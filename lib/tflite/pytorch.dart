import 'dart:typed_data';

import 'package:flutter/services.dart';

class OutputTensor {
  final Int64List shape;
  final Float32List data;

  OutputTensor(this.shape, this.data);
}

class PyTorchModule {
  final int nativeId;

  PyTorchModule._(this.nativeId);

  Future<OutputTensor?> execute(Int32List image, int width, int height) async {
    final args = {
      'nativeId': nativeId,
      'image': image,
      'width': width,
      'height': height,
    };
    final mapResult =
        await _PyTorchPlugin.channel.invokeMethod('execute', args) as Map?;
    OutputTensor? output;
    if (mapResult != null) {
      output = OutputTensor(
        mapResult['shape'],
        mapResult['data'],
      );
    }

    return output;
  }

  static Future<PyTorchModule?> fromAsset(String asset) async {
    PyTorchModule? module;
    var nativeId = await _PyTorchPlugin.loadModel(asset);
    if (nativeId != null) {
      module = PyTorchModule._(nativeId);
    }

    return module;
  }
}

class _PyTorchPlugin {
  static const channel = MethodChannel('fuzzybinary.com/pytorch');

  static Future<int?> loadModel(String model) async {
    try {
      final args = {'model': model};
      var result = (await channel.invokeMethod('loadModel', args)) as int;
      return result;
    } catch (err) {
      print('Error creating pytorch model: $err');
    }
  }
}
