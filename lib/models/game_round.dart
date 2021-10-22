import 'dart:async';

import 'package:flutter/material.dart';

enum ExpiditionColorIndex {
  Yellow,
  Blue,
  White,
  Green,
  Red,
}

final List<String> expiditionColorNames = [
  "Yellow",
  "Blue",
  "White",
  "Green",
  "Red"
];

final List<Color> expiditionColors = [
  Colors.yellow.shade600,
  Colors.blueAccent,
  Colors.grey,
  Colors.green,
  Colors.redAccent
];

class GameRound {
  int get player1Score =>
      player1Scores.reduce((value, element) => value + element);

  int get player2Score =>
      player2Scores.reduce((value, element) => value + element);

  List<int> player1Scores = List.filled(5, 0);
  List<int> player2Scores = List.filled(5, 0);

  bool _isComplete = false;
  bool get isComplete => _isComplete;
  set isComplete(bool value) {
    _isComplete = value;
    _isCompleteController.sink.add(value);
  }

  StreamController<bool> _isCompleteController = StreamController<bool>();
  Stream<bool> get isCompleteStream => _isCompleteController.stream;
}
