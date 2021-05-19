import 'package:flutter_match/models/game_round.dart';

class GameScreenBloc {
  List<GameRound> rounds = [];

  int get player1Score {
    return rounds.fold(
        0, (previousValue, element) => previousValue + element.player1Score);
  }

  int get player2Score {
    return rounds.fold(
        0, (previousValue, element) => previousValue + element.player2Score);
  }

  GameScreenBloc() {
    rounds = [
      GameRound()..isComplete = false,
    ];
  }

  void addRound() {
    rounds.last.isComplete = true;
    rounds.add(GameRound());
  }

  void setExpiditionScore(int player, ExpiditionColorIndex color, int score) {
    if (player == 0) {
      rounds.last.player1Scores[color.index] = score;
    } else if (player == 1) {
      rounds.last.player2Scores[color.index] = score;
    }
  }
}
