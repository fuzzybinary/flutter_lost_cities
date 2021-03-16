import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'camera_utils.dart';

class ClassificationRequest {
  final Image? asset;
  final CameraImage? image;
  final SendPort responsePort;

  ClassificationRequest({this.asset, this.image, required this.responsePort});
}

class ClassificationResult {
  final Rect rect;
  final int score;
  final int bestClassIndex;

  ClassificationResult(this.rect, this.score, this.bestClassIndex);

  @override
  String toString() {
    return "{$bestClassIndex: $score%}";
  }
}

class IsolateStart {
  final SendPort sendPort;
  final int interpeterAddress;

  IsolateStart(this.sendPort, this.interpeterAddress);
}

class ThreadedClassifier {
  static const int _inputSize = 416;

  late Interpreter _interpreter;

  final List<String> _classes = [
    "num_10",
    "num_2",
    "num_3",
    "num_4",
    "num_5",
    "num_6",
    "num_7",
    "num_8",
    "num_9",
    "num_hand",
  ];

  /// Shapes of output tensors
  List<List<int>> _outputShapes = [];

  /// Types of output tensors
  List<TfLiteType> _outputTypes = [];

  ThreadedClassifier(int interpreterAddress) {
    _interpreter = Interpreter.fromAddress(interpreterAddress);

    var outputTensors = _interpreter.getOutputTensors();
    if (outputTensors != null) {
      outputTensors.forEach((tensor) {
        _outputShapes.add(tensor.shape);
        _outputTypes.add(tensor.type);
      });
    }
  }

  Future<List<ClassificationResult>> _classify(
      ClassificationRequest request) async {
    Image? image;
    if (request.image != null) {
      image = CameraUtils.convertCameraImage(request.image!);
      if (Platform.isAndroid) {
        image = copyRotate(image!, 90);
      }
    } else if (request.asset != null) {
      image = request.asset;
    }

    if (image == null) {
      return [];
    }

    List<ClassificationResult> foundObjects = [];

    image = copyResizeCropSquare(image, _inputSize);
    var tensorImage = _createTensorImage(image);

    var output = TensorBufferUint8(_outputShapes[0]);
    var outputs = {0: output.buffer};

    _interpreter.runForMultipleInputs([tensorImage.buffer], outputs);

    var items = output.getShape()![1];
    var members = output.getShape()![2];
    var listData = output.getIntList();
    for (int i = 0; i < items; ++i) {
      var baseIndex = members * i;
      var score = listData[baseIndex + 4];
      if (score > 60) {
        var rect = Rect.fromCenter(
          center: Offset(listData[baseIndex].toDouble(),
              listData[baseIndex + 1].toDouble()),
          width: listData[baseIndex + 2].toDouble(),
          height: listData[baseIndex + 3].toDouble(),
        );

        var classes =
            List.generate(10, (index) => listData[baseIndex + 5 + index]);
        var bestClass = _findBestIndex(classes);

        var foundObject = ClassificationResult(rect, score, bestClass);
        _addIfBetter(foundObjects, foundObject);
      }
    }

    return foundObjects;
  }

  int _findBestIndex(List<int> classScores) {
    var maxIndex = 0, maxValue = 0;
    for (int i = 0; i < classScores.length; ++i) {
      if (classScores[i] > maxValue) {
        maxValue = classScores[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  void _addIfBetter(
      List<ClassificationResult> objects, ClassificationResult newObject) {
    bool shouldAdd = true;
    for (int i = 0; i < objects.length; ++i) {
      var oldObject = objects[i];
      if (oldObject.rect.overlaps(newObject.rect)) {
        shouldAdd = false;
        if (newObject.score > oldObject.score) {
          // Remove the lower scoring object
          objects.removeAt(i);
          objects.add(newObject);
        }
        break;
      }
    }

    if (shouldAdd) {
      objects.add(newObject);
    }
  }

  static void isolateEntry(IsolateStart isoStart) async {
    print("Starting classification isolate");

    final port = ReceivePort();
    isoStart.sendPort.send(port.sendPort);

    var classifier = ThreadedClassifier(isoStart.interpeterAddress);

    await for (final ClassificationRequest? request in port) {
      if (request != null) {
        print("Recieved classification request, processing... ");

        try {
          var results = await classifier._classify(request);

          request.responsePort.send(results);
        } catch (e) {
          print("Failure running classifier $e");
          request.responsePort.send(0);
        }
      }
    }
  }

  static TensorBufferUint8 _createTensorImage(Image image) {
    var tensorBuffer = TensorBufferUint8([1, image.width, image.height, 3]);
    var imageData = image.data;
    for (int i = 0; i < imageData.length; ++i) {
      var pixelValue = imageData[i];
      var writeIndex = i * 3;
      tensorBuffer.byteData.setUint8(writeIndex, pixelValue & 0xff);
      tensorBuffer.byteData.setUint8(writeIndex + 1, (pixelValue >> 8) & 0xff);
      tensorBuffer.byteData.setUint8(writeIndex + 2, (pixelValue >> 16) & 0xff);
    }

    return tensorBuffer;
  }
}

class Classifier {
  Interpreter? _interpreter;

  static const String _modelFileName = "best-int8.tflite";

  Isolate? _classificationIsolate;
  SendPort? _sendPort;
  ReceivePort _receivePort = ReceivePort();

  bool get ready => _interpreter != null && _classificationIsolate != null;

  Future<void> start() async {
    await _loadModel();

    if (_classificationIsolate != null) {
      _classificationIsolate!.kill();
      _classificationIsolate = null;
    }

    _classificationIsolate = await Isolate.spawn<IsolateStart>(
        ThreadedClassifier.isolateEntry,
        IsolateStart(_receivePort.sendPort, _interpreter!.address));

    // After the isolate spawns it will send us back the port we should send information on
    _sendPort = await _receivePort.first;
  }

  void stop() async {
    _classificationIsolate?.kill();
    _classificationIsolate = null;
  }

  Future<List<ClassificationResult>> classify(CameraImage image) async {
    var responsePort = ReceivePort();
    var message = ClassificationRequest(
        image: image, responsePort: responsePort.sendPort);
    _sendPort?.send(message);

    return await responsePort.first;
  }

  Future<List<ClassificationResult>> classifyAsset(String asset) async {
    var raw = await rootBundle.load('assets/$asset');
    var imageAsset = decodeImage(raw.buffer.asUint8List());

    var responsePort = ReceivePort();
    var message = ClassificationRequest(
        asset: imageAsset, responsePort: responsePort.sendPort);
    _sendPort?.send(message);

    return await responsePort.first;
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelFileName,
          options: InterpreterOptions()..threads = 4);
    } catch (e) {
      print("Error creating interpreter: $e");
    }
    print("[] Loaded tensorflow model");
  }
}
