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

typedef void ScoringResultCallback(
    ExpiditionColorIndex expiditionIndex, int score);

class ScoringScreen extends StatefulWidget {
  final Classifier classifier;
  final GameRound round;
  final ExpiditionColorIndex initialExpidition;

  ScoringScreen(
      {required this.classifier,
      required this.initialExpidition,
      required this.round});

  @override
  State<StatefulWidget> createState() => _ScoringState(classifier, round);
}

class _ScoringState extends State<ScoringScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller = AnimationController(
      duration: const Duration(milliseconds: 200), vsync: this);
  late ThemeData _currentTheme;
  Animation<ThemeData>? _themeAnimation;

  late ScoringBloc _bloc;
  late Future _cameraDelayFuture;

  Key _cameraKey = UniqueKey();
  bool _streamingCamera = true;

  _ScoringState(Classifier classifier, GameRound round)
      : _bloc = ScoringBloc(classifier, round);

  @override
  void initState() {
    super.initState();

    _bloc.currentExpidition = widget.initialExpidition;
    // Allow the screen to animate in before attempting to initialize the camera
    // This is a bit of a hack to avoid some visual jank
    _cameraDelayFuture = Future.delayed(Duration(milliseconds: 500));
  }

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
    await _bloc.onCameraData(cameraImage);

    if (mounted) {
      setState(() {});
    }
  }

  void setExpidition(ExpiditionColorIndex expiditionIndex) {
    setState(() {
      _bloc.currentExpidition = expiditionIndex;
      _animateThemeChange();
    });
  }

  void _onCameraPause() {
    setState(() {
      _streamingCamera = !_streamingCamera;
    });
  }

  Widget _bottomBar(ThemeData theme) {
    return Row(
      children: ExpiditionColorIndex.values.map((element) {
        bool isCurrent = element == _bloc.currentExpidition;
        return Expanded(
          child: Container(
            decoration:
                isCurrent ? BoxDecoration(color: Colors.amberAccent) : null,
            padding: isCurrent ? EdgeInsets.only(left: 2, right: 2) : null,
            child: OutlinedButton(
              child: Text(isCurrent
                  ? '${_bloc.currentScore}'
                  : '${_bloc.round.player1Scores[element.index]}'),
              onPressed: () => setExpidition(element),
              style: OutlinedButton.styleFrom(
                primary: Colors.white,
                backgroundColor: expiditionColors[element.index],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _scoringButton(ThemeData theme, String score, int cardIndex) {
    final isOn = _bloc.enabledCards[cardIndex];
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _bloc.toggleCard(cardIndex);
        });
      },
      child: Text(score),
      style: ElevatedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        primary: theme.primaryColor.withOpacity(isOn ? 1.0 : 0.4),
      ),
    );
  }

  Widget _cameraViewStack(
      Key cameraKey, BuildContext context, ThemeData themeData) {
    final buttonStyle = ElevatedButton.styleFrom(
      shape: CircleBorder(),
      padding: EdgeInsets.all(15),
    );

    final cardButtons = Container(
      alignment: Alignment.topRight,
      child: SingleChildScrollView(
        child: Column(
          children: [
            for (var i = 0; i < _bloc.enabledCards.length; ++i)
              _scoringButton(
                themeData,
                i < 3 ? "H" : (i - 1).toString(),
                i,
              ),
          ],
        ),
      ),
    );
    final actionButtons = Container(
      alignment: Alignment.bottomCenter,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: _onBack,
              style: buttonStyle,
              child: Icon(Icons.fast_rewind),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: _onCameraPause,
              style: buttonStyle,
              child:
                  _streamingCamera ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: _onNext,
              style: buttonStyle,
              child: Icon(Icons.fast_forward),
            ),
          ),
        ],
      ),
    );
    return CameraView(
      key: cameraKey,
      onCameraData: _onCameraData,
      isStreaming: _streamingCamera,
      child: Stack(
        children: [
          cardButtons,
          actionButtons,
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
      _bloc.nextExpidition(true);
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
        appBar: AppBar(title: Text("Score: ${_bloc.currentScore}")),
        body: Center(
          child: Column(children: [
            Expanded(
              child: FutureBuilder(
                future: _cameraDelayFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return _cameraViewStack(_cameraKey, context, themeData);
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
            _bottomBar(themeData),
          ]),
        ),
      ),
    );
  }
}
