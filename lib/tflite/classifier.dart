import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class ClassificationRequest {
  final Image? asset;
  final CameraImage? image;
  final SendPort responsePort;

  ClassificationRequest({this.asset, this.image, required this.responsePort});
}

class IsolateStart {
  final SendPort sendPort;
  final int interpeterAddress;
  final String documentsPath;

  IsolateStart(this.sendPort, this.interpeterAddress, this.documentsPath);
}

class ThreadedClassifier {
  static const int _inputSize = 416;

  late Interpreter _interpreter;

  String _documentsPath;

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

  ThreadedClassifier(int interpreterAddress, this._documentsPath) {
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
      image = _convertCameraImage(request.image!);
      if (Platform.isAndroid) {
        image = copyRotate(image!, 90);
      }
    } else if (request.asset != null) {
      image = request.asset;
    }

    if (image == null) {
      return 0;
    }

    // Create TensorImage from image
    // TensorImage inputImage = TensorImage.fromImage(image);
    // // Pre-process TensorImage
    // inputImage = _getProcessedImage(inputImage);

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
      var scoreA = listData[members * i + 4];
      if (scoreA > 80) {
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

  TensorImage _getProcessedImage(TensorImage inputImage) {
    var padSize = min(inputImage.height, inputImage.width);
    var imageProcessor = ImageProcessorBuilder()
        .add(ResizeWithCropOrPadOp(padSize, padSize))
        .add(ResizeOp(_inputSize, _inputSize, ResizeMethod.BILINEAR))
        .build();
    inputImage = imageProcessor.process(inputImage);
    return inputImage;
  }

  static void isolateEntry(IsolateStart isoStart) async {
    print("Starting classification isolate");

    final port = ReceivePort();
    isoStart.sendPort.send(port.sendPort);

    var classifier =
        ThreadedClassifier(isoStart.interpeterAddress, isoStart.documentsPath);

    await for (final ClassificationRequest? request in port) {
      if (request != null) {
        print("Recieved classification request, processing... ");

        var predictStartTime = DateTime.now().microsecondsSinceEpoch;

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

  static Image? _convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return convertBGRA8888ToImage(cameraImage);
    } else {
      return null;
    }
  }

  static Image convertBGRA8888ToImage(CameraImage cameraImage) {
    Image img = Image.fromBytes(cameraImage.planes[0].width!,
        cameraImage.planes[0].height!, cameraImage.planes[0].bytes,
        format: Format.bgra);
    return img;
  }

  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static Image convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int pixelStride = cameraImage.planes[0].bytesPerRow;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = Image(width, height);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * pixelStride + x;

        final yp = cameraImage.planes[0].bytes[index];
        final up = cameraImage.planes[1].bytes[uvIndex];
        final vp = cameraImage.planes[2].bytes[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255).toInt();
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255)
            .toInt();
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255).toInt();

        image.setPixelRgba(x, y, r, g, b);
      }
    }
    return image;
  }

  /// Convert a single YUV pixel to RGB
  static int yuv2rgb(int y, int u, int v) {
    // Convert yuv pixel to rgb
    int r = (y + v * 1436 / 1024 - 179).round();
    int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    int b = (y + u * 1814 / 1024 - 227).round();

    // Clipping RGB values to be inside boundaries [ 0 , 255 ]
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    return 0xff000000 |
        ((b << 16) & 0xff0000) |
        ((g << 8) & 0xff00) |
        (r & 0xff);
  }

  // static void saveImage(Image image, [int i = 0]) async {
  //   List<int> jpeg = JpegEncoder().encodeImage(image);
  //   final appDir = await getTemporaryDirectory();
  //   final appPath = appDir.path;
  //   final fileOnDevice = File('$appPath/out$i.jpg');
  //   await fileOnDevice.writeAsBytes(jpeg, flush: true);
  //   print('Saved $appPath/out$i.jpg');
  // }
}

class Classifier {
  Interpreter? _interpreter;

  static const String _modelFileName = "best-int8.tflite";

  Isolate? _classificationIsolate;
  SendPort? _sendPort;
  ReceivePort _receivePort = ReceivePort();

  bool get ready => _interpreter != null && _classificationIsolate != null;

  Classifier();

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(_modelFileName,
          options: InterpreterOptions()..threads = 4);
    } catch (e) {
      print("Error creating interpreter: $e");
    }
    print("[] Loaded tensorflow model");
  }

  Future<void> start() async {
    await _loadModel();

    if (_classificationIsolate != null) {
      _classificationIsolate!.kill();
      _classificationIsolate = null;
    }

    final path = (await getApplicationDocumentsDirectory()).path;

    _classificationIsolate = await Isolate.spawn<IsolateStart>(
        ThreadedClassifier.isolateEntry,
        IsolateStart(_receivePort.sendPort, _interpreter!.address, path));

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
}
