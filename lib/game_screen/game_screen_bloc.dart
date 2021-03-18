import 'package:flutter_match/models/game_round.dart';

class GameScreenBloc {
  List<GameRound> rounds = [];

  GameScreenBloc() {
    // Fake Game
    rounds = [
      GameRound()
        ..player1Scores = [0, 10, 2, 13, 1]
        ..player2Scores = [10, 10, 0, 0, 20],
      GameRound()
        ..player1Scores = [0, 10, 2, 13, 1]
        ..player2Scores = [10, 10, 0, 0, 20],
      GameRound()
        ..player1Scores = [0, 10, 2, 13, 1]
        ..player2Scores = [10, 10, 0, 0, 20],
      GameRound()
        ..player1Scores = [0, 10, 2, 13, 1]
        ..player2Scores = [10, 10, 0, 0, 20],
      GameRound()
        ..player1Scores = [0, 10, 2, 13, 1]
        ..player2Scores = [10, 10, 0, 0, 20],
    ];
  }

  void addRound() {
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
