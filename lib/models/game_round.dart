enum ExpiditionColorIndex {
  Yellow,
  Blue,
  White,
  Green,
  Red,
}

class GameRound {
  int get player1Score =>
      player1Scores.reduce((value, element) => value + element);

  int get player2Score =>
      player2Scores.reduce((value, element) => value + element);

  List<int> player1Scores = List.filled(5, 0);
  List<int> player2Scores = List.filled(5, 0);
}
