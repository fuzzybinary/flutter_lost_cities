import 'dart:math';

import 'package:flutter_match/tflite/classifier.dart';

class ScoringBloc {
  // This is 3 hands + 9 number cards
  List<bool> _enabledCards = List.filled(12, false);
  List<bool> get enabledCards => _enabledCards;

  int _currentScore = 0;
  int get currentScore => _currentScore;

  int totalCards = 0;
  bool get hasTwentyPointBonus => totalCards >= 8;

  void setClassifications(List<ClassificationResult> classifications) {
    _enabledCards = List.filled(12, false);

    int baseScore = 0;
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
          baseScore += cardValue;
        }
      }
    }

    numHands = min((numHands / 2.0).ceil(), 3);
    for (int i = 0; i < numHands; ++i) {
      _enabledCards[i] = true;
    }

    totalCards = _enabledCards.where((e) => e).length;
    if (baseScore > 0) {
      _currentScore = (baseScore - 20) * numHands;
      if (hasTwentyPointBonus) {
        _currentScore += 20;
      }
    } else {
      _currentScore = 0;
    }
  }
}
