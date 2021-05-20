import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_match/models/game_round.dart';
import 'package:flutter_match/scoring_screen/scoring_bloc.dart';
import 'package:flutter_match/tflite/classifier.dart';

import '../camera_view.dart';

class ScoringResult {
  List<int?> classifiedScores =
      List.filled(ExpiditionColorIndex.values.length, null);
}

class ScoringScreen extends StatefulWidget {
  final Classifier classifier;

  ScoringScreen(this.classifier);

  @override
  State<StatefulWidget> createState() => _ScoringState();
}

class _ScoringState extends State<ScoringScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller = AnimationController(
      duration: const Duration(milliseconds: 200), vsync: this);
  late ThemeData _currentTheme;
  Animation<ThemeData>? _themeAnimation;

  ScoringBloc _bloc = ScoringBloc();

  // TODO: This is set to true for now to essentially disable the classifier
  // while I work on the UI
  bool _classifying = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _currentTheme = _getThemeFor(_bloc.currentExpidition);
  }

  ThemeData _getThemeFor(ExpiditionColorIndex expidition) {
    final parentTheme = Theme.of(context);
    return parentTheme.copyWith(
      primaryColor: expiditionColors[_bloc.currentExpidition.index],
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          primary: expiditionColors[_bloc.currentExpidition.index],
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: expiditionColors[_bloc.currentExpidition.index],
      ),
    );
  }

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

  // Unused for now until I need to test the classifier again
  // ignore: unused_element
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

  Widget _scoringButton(ThemeData theme, String score, bool isOn) {
    return ElevatedButton(
      onPressed: todo,
      child: Text(score),
      style: ElevatedButton.styleFrom(
        primary: theme.primaryColor.withOpacity(isOn ? 1.0 : 0.4),
      ),
    );
  }

  Widget _cameraViewStack(BuildContext context, ThemeData themeData) {
    return CameraView(
      onCameraData: _onCameraData,
      child: Stack(
        children: [
          Container(
            alignment: Alignment.topRight,
            child: Column(children: [
              for (var i = 0; i < _bloc.enabledCards.length; ++i)
                _scoringButton(
                  themeData,
                  i < 3 ? "H" : (i - 1).toString(),
                  _bloc.enabledCards[i],
                )
            ]),
          ),
        ],
      ),
    );
  }

  void _animateThemeChange() {
    final endTheme = _getThemeFor(_bloc.currentExpidition);
    _themeAnimation =
        ThemeDataTween(begin: _currentTheme, end: endTheme).animate(_controller)
          ..addListener(() {
            setState(() {});
          });
    _controller.reset();
    _controller.forward();
    _currentTheme = endTheme;
  }

  void _onBack() {
    setState(() {
      _bloc.prevExpidition();
      _animateThemeChange();
    });
  }

  void _onNext() {
    setState(() {
      _bloc.nextExpidition(false);
      _animateThemeChange();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var themeData = _themeAnimation?.value ?? _currentTheme;
    return Theme(
      data: themeData,
      child: Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(children: [
            Text("Current Score: ${_bloc.currentScore}"),
            _cameraViewStack(context, themeData),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _onBack,
                  child: Icon(Icons.arrow_back),
                ),
                ElevatedButton(
                  onPressed: todo,
                  child: Icon(Icons.pause),
                ),
                ElevatedButton(
                  onPressed: _onNext,
                  child: Icon(Icons.arrow_forward),
                )
              ],
            )
          ]),
        ),
      ),
    );
  }
}
