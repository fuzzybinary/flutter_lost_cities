import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_match/scoring_screen/scoring_bloc.dart';
import 'package:flutter_match/tflite/classifier.dart';

import '../camera_view.dart';
import '../classification_box.dart';

class ScoringScreen extends StatefulWidget {
  final Classifier classifier;

  ScoringScreen(this.classifier);

  @override
  State<StatefulWidget> createState() => _ScoringState();
}

class _ScoringState extends State<ScoringScreen> {
  ScoringBloc _bloc = ScoringBloc();

  bool _classifying = false;

  List<ClassificationResult>? _classifications;

  void _onCameraData(CameraImage cameraImage) async {
    if (widget.classifier.ready) {
      if (_classifying) {
        return;
      }

      _classifying = true;

      var classifications = await widget.classifier.classify(cameraImage);
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
    if (widget.classifier.ready) {
      if (_classifying) {
        return;
      }

      _classifying = true;

      var classifications =
          await widget.classifier.classifyAsset('test_image.jpg');
      print(classifications);

      _classifying = false;
    }
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
