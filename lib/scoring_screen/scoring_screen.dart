import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_match/scoring_screen/scoring_bloc.dart';
import 'package:flutter_match/tflite/classifier.dart';

import '../camera_view.dart';
import '../classification_box.dart';

class ScoringScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ScoringState();
}

class _ScoringState extends State<ScoringScreen> {
  ScoringBloc _bloc = ScoringBloc();

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

      if (mounted) {
        setState(() {
          _bloc.setClassifications(classifications);
        });
      }
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

  void todo() {}

  Widget _scoringButton(String score, bool isOn) {
    return ElevatedButton(
      onPressed: todo,
      child: Text(score),
      style: ElevatedButton.styleFrom(
          primary: Colors.blueAccent.withOpacity(isOn ? 1.0 : 0.4)),
    );
  }

  Widget _cameraViewStack(BuildContext context) {
    final boxes = _classifications?.map((c) {
          return ClassificationBox(
            location: c.rect,
            classification: c,
          );
        }).toList() ??
        [];

    return CameraView(
      onCameraData: _onCameraData,
      child: Stack(children: [
        ...boxes,
        Container(
          alignment: Alignment.topRight,
          child: Column(children: [
            for (var i = 0; i < _bloc.enabledCards.length; ++i)
              _scoringButton(
                  i < 3 ? "H" : (i - 1).toString(), _bloc.enabledCards[i])
          ]),
        )
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(children: [
          Text("Current Score: ${_bloc.currentScore}"),
          _cameraViewStack(context)
        ]),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.camera),
      //   onPressed: _onCameraButtonPressed,
      // ),
    );
  }
}
