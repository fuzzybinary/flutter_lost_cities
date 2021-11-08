import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter_match/models/game_round.dart';
import 'package:flutter_match/tflite/classifier.dart';

class ScoringBloc {
  final Classifier classifier;
  final GameRound round;

  bool _classifying = false;

  ExpiditionColorIndex currentExpidition = ExpiditionColorIndex.yellow;

  // This is 3 hands + 9 number cards
  List<bool> _enabledCards = List.filled(12, false);
  List<bool> get enabledCards => _enabledCards;

  int _currentScore = 0;
  int get currentScore => _currentScore;

  bool _hasTwentyPointBonus = false;
  bool get hasTwentyPointBonus => _hasTwentyPointBonus;

  ScoringBloc(this.classifier, this.round);

  Future<void> onCameraData(CameraImage cameraImage) async {
    if (_classifying) {
      return;
    }

    _classifying = true;

    final classifications = await classifier.classify(cameraImage);
    _updateClassifications(classifications);
    _classifying = false;
  }

  void toggleCard(int cardIndex) {
    _enabledCards[cardIndex] = !_enabledCards[cardIndex];
    _updateScoring();
  }

  void toggleClassifier() {}

  void prevExpidition() {
    var expiditionIndex = currentExpidition.index - 1;
    if (expiditionIndex < 0) {
      expiditionIndex = ExpiditionColorIndex.values.length - 1;
    }
    currentExpidition = ExpiditionColorIndex.values[expiditionIndex];
  }

  void nextExpidition(bool didConfirmScore) {
    if (didConfirmScore) {
      round.player1Scores[currentExpidition.index] = _currentScore;
    }
    var expiditionIndex = currentExpidition.index + 1;
    if (expiditionIndex >= ExpiditionColorIndex.values.length) {
      expiditionIndex = 0;
    }
    _enabledCards.fillRange(0, 12, false);
    _updateScoring();

    currentExpidition = ExpiditionColorIndex.values[expiditionIndex];
  }

  void _updateClassifications(List<ClassificationResult> classifications) {
    _enabledCards = List.filled(12, false);

    int numHands = 0;
    for (var c in classifications) {
      var cardValue = 0;
      if (c.bestClassIndex == 0) {
        cardValue = 10;
      } else if (c.bestClassIndex == 9) {
        numHands++;
      } else {
        cardValue = c.bestClassIndex + 1;
      }

      if (cardValue > 0) {
        // The first 3 indexes are hands, then 2-10
        var cardIndex = (cardValue - 2) + 3;
        if (!_enabledCards[cardIndex]) {
          _enabledCards[cardIndex] = true;
        }
      }
    }

    numHands = min((numHands / 2.0).ceil(), 3);
    for (int i = 0; i < numHands; ++i) {
      _enabledCards[i] = true;
    }
    _updateScoring();
  }

  void _updateScoring() {
    int numCards = 0;
    var numHands = 0;
    int baseScore = 0;

    for (int i = 0; i < _enabledCards.length; ++i) {
      if (_enabledCards[i]) {
        numCards++;
        var cardValue = 0;
        if (i > 2) {
          cardValue = i - 1; // Values 2-10 past the first 3 cards
        } else {
          numHands++;
        }

        baseScore += cardValue;
      }
    }

    if (numCards > 0) {
      _currentScore = (baseScore - 20) * (numHands + 1);
      _hasTwentyPointBonus = numCards >= 8;
      if (hasTwentyPointBonus) {
        _currentScore += 20;
      }
    } else {
      _currentScore = 0;
    }
  }
}
