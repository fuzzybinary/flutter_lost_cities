import 'dart:io';
import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import 'camera_utils.dart';

class ClassificationRequest {
  final Image? asset;
  final CameraImage? image;
  final SendPort responsePort;

  ClassificationRequest({this.asset, this.image, required this.responsePort});
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

  Future<int> _classify(ClassificationRequest request) async {
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
      return 0;
    }

    image = copyResizeCropSquare(image, _inputSize);
    var tensorImage = _createTensorImage(image);

    var output = TensorBufferUint8(_outputShapes[0]);
    var outputs = {0: output.buffer};

    _interpreter.runForMultipleInputs([tensorImage.buffer], outputs);

    final seenItems = Set<int>();
    var items = output.getShape()![1];
    var members = output.getShape()![2];
    var listData = output.getIntList();
    for (int i = 0; i < items; ++i) {
      var score = listData[members * i + 4];
      if (score > 80) {
        var splat = List.generate(
            members, (memberIndex) => listData[members * i + memberIndex]);
        var maxArg = 0, maxValue = 0;
        for (int c = 5; c < 15; ++c) {
          if (splat[c] > maxValue) {
            maxValue = splat[c];
            maxArg = c - 5;
          }
        }
        seenItems.add(maxArg);
      }
    }

    for (var seen in seenItems) {
      print("I see ${_classes[seen]}");
    }

    return seenItems.length;
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
          var resultCount = await classifier._classify(request);

          request.responsePort.send(resultCount);
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

    final path = (await getApplicationDocumentsDirectory()).path;

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

  Future<void> classify(CameraImage image) async {
    var responsePort = ReceivePort();
    var message = ClassificationRequest(
        image: image, responsePort: responsePort.sendPort);
    _sendPort?.send(message);

    var _ = await responsePort.first;
  }

  Future<void> classifyAsset(String asset) async {
    var raw = await rootBundle.load('assets/$asset');
    var imageAsset = decodeImage(raw.buffer.asUint8List());

    var responsePort = ReceivePort();
    var message = ClassificationRequest(
        asset: imageAsset, responsePort: responsePort.sendPort);
    _sendPort?.send(message);

    var _ = await responsePort.first;
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
