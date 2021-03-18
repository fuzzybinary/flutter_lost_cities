import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_match/tflite/classifier.dart';

import '../camera_view.dart';
import '../classification_box.dart';

class ScoringScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ScoringState();
}

class _ScoringState extends State<ScoringScreen> {
  bool _classifying = false;
  Classifier? _classifier;

  List<ClassificationResult>? _classifications;

  void _loadClassifier() async {
    _classifier = Classifier();
    await _classifier?.start();
  }

  void _onCameraData(CameraImage cameraImage) async {
    if (_classifier != null && _classifier!.ready) {
      if (_classifying) {
        return;
      }

      _classifying = true;

      var classifications = await _classifier!.classify(cameraImage);
      print(classifications);
      _classifying = false;

      setState(() {
        _classifications = classifications;
      });
    }
  }

  void _classifySample() async {
    if (_classifier != null && _classifier!.ready) {
      if (_classifying) {
        return;
      }

      _classifying = true;

      var classifications = await _classifier!.classifyAsset('test_image.jpg');
      print(classifications);

      _classifying = false;
    }
  }

  @override
  void initState() {
    super.initState();

    _loadClassifier();
  }

  Widget _cameraViewStack(BuildContext context) {
    final boxes = _classifications?.map((c) {
      return ClassificationBox(
        location: c.rect,
        classification: c,
      );
    }).toList();

    return CameraView(
      onCameraData: _onCameraData,
      child: Stack(
        children: boxes ?? [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: _cameraViewStack(context)),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.camera),
      //   onPressed: _onCameraButtonPressed,
      // ),
    );
  }
}
