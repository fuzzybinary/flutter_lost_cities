import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter_match/tflite/pytorch.dart';
import 'package:image/image.dart';

import 'camera_utils.dart';

class ImageProcessRequest {
  CameraImage image;
  SendPort port;

  ImageProcessRequest(this.image, this.port);
}

class ImageProcessResponse {
  Int32List imageData;

  ImageProcessResponse(this.imageData);
}

class ClassificationResult {
  Rect rect;
  final double score;
  final int bestClassIndex;

  ClassificationResult(this.rect, this.score, this.bestClassIndex);

  @override
  String toString() {
    return "{$bestClassIndex: $score%}";
  }
}

class Classifier {
  static const int _inputSize = 416;
  PyTorchModule? _pyTorchModule;

  Isolate? _isolate;
  late SendPort _processingPort;

  static const double _quantization = 0.0109202368185;
  static const double _outputToImageLoc = _inputSize * _quantization;

  // ignore: unused_field
  //String _documentsPath;

  Classifier();

  void start() async {
    ReceivePort responsePort = ReceivePort();
    _isolate =
        await Isolate.spawn<SendPort>(processingThread, responsePort.sendPort);

    _processingPort = await responsePort.first;

    _pyTorchModule = await PyTorchModule.fromAsset("assets/lostcities.ptl");
  }

  static void processingThread(SendPort responsePort) async {
    ReceivePort listenPort = ReceivePort();
    responsePort.send(listenPort.sendPort);

    await for (final ImageProcessRequest? request in listenPort) {
      if (request != null) {
        var image = CameraUtils.convertCameraImage(request.image);
        if (Platform.isAndroid) {
          image = copyRotate(image!, 90);
        }
        // } else if (request.asset != null) {
        //   originalImage = request.asset;
        // }

        image = copyResizeCropSquare(image!, _inputSize);
        //var tensorImage = _createTensorImage(image!);
        var tensorImage = _createARGBImage(image);
        request.port.send(ImageProcessResponse(tensorImage));
      }
    }
  }

  static Int32List _createARGBImage(Image image) {
    var buffer = Int32List(image.width * image.height);
    var imageData = image.data;
    for (int i = 0; i < imageData.length; ++i) {
      var pixelValue = imageData[i];
      var argbValue = pixelValue & 0xff00ff00; // alpha and green
      argbValue = argbValue | ((pixelValue & 0xff) << 16); // red
      argbValue = argbValue | ((pixelValue & 0xff0000) >> 16); // blue
      buffer[i] = argbValue;
    }

    return buffer;
  }

  Future<Int32List> _createTensorFromImage(CameraImage cameraImage) async {
    var responsePort = ReceivePort();
    var message = ImageProcessRequest(cameraImage, responsePort.sendPort);
    _processingPort.send(message);

    ImageProcessResponse response = await responsePort.first;
    return response.imageData;
  }

  Future<List<ClassificationResult>> classify(CameraImage? cameraImage) async {
    if (_pyTorchModule == null) {
      return [];
    }

    final stopwatch = Stopwatch();
    stopwatch.start();

    List<ClassificationResult> foundObjects = [];
    if (cameraImage == null) {
      return [];
    }

    var tensorImage = await _createTensorFromImage(cameraImage);

    // print(
    //     "Prep time: ${(stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2)}");
    stopwatch.reset();

    var output =
        await _pyTorchModule?.execute(tensorImage, _inputSize, _inputSize);

    // print(
    //     "Classification Time: ${(stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2)}");
    stopwatch.reset();

    if (output != null) {
      int items = output.shape[1];
      int members = output.shape[2];
      for (int i = 0; i < items; ++i) {
        var baseIndex = members * i;
        var score = output.data[baseIndex + 4];
        if (score > 0.8) {
          // TODO: Double check this logic for assembling the rectangles,
          // It was pulled from old TensorFlow work and may not be correct.
          var rect = Rect.fromCenter(
            center: Offset(
              output.data[baseIndex] * _outputToImageLoc,
              output.data[baseIndex + 1] * _outputToImageLoc,
            ),
            width: output.data[baseIndex + 2] * _outputToImageLoc,
            height: output.data[baseIndex + 3] * _outputToImageLoc,
          );

          var classes =
              List.generate(10, (index) => output.data[baseIndex + 5 + index]);
          var bestClass = _findBestIndex(classes);

          var foundObject = ClassificationResult(rect, score, bestClass);
          _addIfBetter(foundObjects, foundObject);
        }
      }
    }

    // print(
    //     "Postprocessing Time: ${(stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2)}");
    stopwatch.reset();

    return foundObjects;
  }

  int _findBestIndex(List<double> classScores) {
    var maxIndex = 0;
    var maxValue = 0.0;
    for (int i = 0; i < classScores.length; ++i) {
      if (classScores[i] > maxValue) {
        maxValue = classScores[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  bool _addIfBetter(
      List<ClassificationResult> objects, ClassificationResult newObject) {
    for (int i = 0; i < objects.length; ++i) {
      var oldObject = objects[i];
      if (oldObject.rect.overlaps(newObject.rect)) {
        if (newObject.score > oldObject.score) {
          // Remove the lower scoring object
          objects.removeAt(i);
          objects.add(newObject);
          // Did add
          return true;
        }
        return false;
      }
    }

    objects.add(newObject);

    return true;
  }

  Rect _uncropRect(Rect inputRect, Image originalImage, int inputImageSize) {
    var scale = 1.0;
    var offset = Offset.zero;
    if (originalImage.width < originalImage.height) {
      scale = originalImage.width / inputImageSize;
      var offsetY = (originalImage.height / scale - inputImageSize) * 0.5;
      offset = Offset(0, offsetY);
    } else {
      scale = originalImage.height / inputImageSize;
      var offsetX = (originalImage.width / scale - inputImageSize) * 0.5;
      offset = Offset(offsetX, 0);
    }

    var uncropped = Rect.fromLTRB(
      (inputRect.left + offset.dx) * scale,
      (inputRect.top + offset.dy) * scale,
      (inputRect.right + offset.dx) * scale,
      (inputRect.bottom + offset.dy) * scale,
    );
    // Not sure this is necessary since the camera preview should also rotate
    // the view of the camera.
    // if (Platform.isAndroid) {
    //   // Unrotate - this is a simplification of multiplication by a 2D rotation matrix
    //   // with the result [ x cos θ - y sin θ, x sin θ + y cos θ ]
    //   uncropped = Rect.fromLTRB(
    //       uncropped.top,
    //       originalImage.width - uncropped.left,
    //       uncropped.bottom,
    //       originalImage.width - uncropped.right);
    // }

    return uncropped;
  }
}
