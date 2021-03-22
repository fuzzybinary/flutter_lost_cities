import 'dart:typed_data';

import 'package:flutter/services.dart';

class _TFLitePlugin {
  static const platform = MethodChannel('fuzzybinary.com/tflite');

  static Future<int?> createInterpreter(
      String model, TFLiteInterpreterOptions? options) async {
    try {
      var args = {"model": "assets/$model", "options": options?.toNativeMap()};
      var result = await platform.invokeMethod('createInterpreter', args);
      return ((result as Map)['nativeId'] as int);
    } catch (err) {
      print("Error creating interpretor: $err");
    }
    return null;
  }
}

// In the acutal native code, none of these options are optional. Here,
// we use "null" to mean use the defualt, whatever that is
class TFLiteInterpreterOptions {
  bool? allowBufferHandleOutput;
  bool? isCancellable;
  int? numThreads;
  bool? useNNAPIOnAnrdoid;
  bool? useXNNPACK;

  Map<String, Object?> toNativeMap() {
    return {
      'allowBufferHandleOutput': allowBufferHandleOutput,
      'isCancellable': isCancellable,
      'numThreads': numThreads,
      'useNNAPI': useNNAPIOnAnrdoid,
      'useXNNPACK': useXNNPACK
    };
  }
}

class TFLiteInterpreter {
  bool _destroyed = false;
  int _nativeId;

  int get nativeId => _nativeId;

  TFLiteInterpreter._(this._nativeId);

  TFLiteInterpreter.fromId(this._nativeId);

  void destroy() {
    if (!_destroyed) {
      _destroyed = true;
      _TFLitePlugin.platform.invokeMethod('destroyInterpreter');
    }
  }

  Future<void> run(Uint8List input, Uint8List output) async {
    final args = {"nativeId": _nativeId, "input": input, "output": output};
    await _TFLitePlugin.platform.invokeMethod('run', args);
  }

  Future<List<TFLiteTensor>?> getOutputTensors() async {
    var args = {'nativeId': _nativeId};
    var result =
        await _TFLitePlugin.platform.invokeMethod('getOutputTensors', args);

    var tensors = result['tensors'] as List<Map<String, Object>>;

    return tensors.map((e) => TFLiteTensor.fromMap(e)).toList();
  }

  static Future<TFLiteInterpreter?> fromAsset(String model,
      {TFLiteInterpreterOptions? options}) async {
    var nativeId = await _TFLitePlugin.createInterpreter(model, options);
    if (nativeId != null) {
      return TFLiteInterpreter._(nativeId);
    }
    return null;
  }
}

enum TFLiteDataType {
  unknown,
  bool,
  float32,
  int32,
  int64,
  int8,
  string,
  uint8
}

TFLiteDataType _dataTypeFromString(String string) {
  final lowerString = string.toLowerCase();
  return TFLiteDataType.values.firstWhere((e) => e.toString() == lowerString,
      orElse: () => TFLiteDataType.unknown);
}

class TFLiteTensor {
  TFLiteDataType dataType;
  final int numBytes;
  final List<int> shape;

  TFLiteTensor({
    required this.dataType,
    required this.numBytes,
    required this.shape,
  });

  factory TFLiteTensor.fromMap(Map map) {
    final dataType = _dataTypeFromString(map['dataType'] as String);
    final shape = (map['shape'] as Uint32List).toList();

    final result = TFLiteTensor(
      dataType: dataType,
      numBytes: map['numBytes'] as int,
      shape: shape,
    );
    return result;
  }
}
