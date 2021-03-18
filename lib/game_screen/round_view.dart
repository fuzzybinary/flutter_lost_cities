import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_match/models/game_round.dart';

class RoundButton extends StatelessWidget {
  final Color color;
  final int score;
  final Function() onPressed;

  void todo() {}

  RoundButton(
      {required this.color, required this.score, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: ElevatedButton(
            style: ElevatedButton.styleFrom(primary: color),
            onPressed: onPressed,
            child: Text(score.toString())),
      ),
    );
  }
}

typedef ScoreCallback = void Function(int player, int expidition);

@immutable
class RoundView extends StatelessWidget {
  final GameRound round;
  final ScoreCallback onScoreRequested;

  RoundView({Key? key, required this.round, required this.onScoreRequested})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Color> expiditionColors = [
      Colors.yellow.shade600,
      Colors.blueAccent,
      Colors.grey,
      Colors.green,
      Colors.redAccent
    ];

    return Container(
      child: Column(
        children: [
          Container(
              padding: EdgeInsets.fromLTRB(8, 0, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Player 1 - Total Score: ${round.player1Score}"),
                  Row(
                    children: [
                      for (int i = 0; i < 5; ++i)
                        RoundButton(
                          color: expiditionColors[i],
                          score: round.player1Scores[i],
                          onPressed: () => onScoreRequested(0, i),
                        )
                    ],
                  ),
                ],
              )),
          Container(
              padding: EdgeInsets.fromLTRB(30, 0, 8, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Player 2 - Total Score: ${round.player2Score}"),
                  Row(
                    children: [
                      for (int i = 0; i < 5; ++i)
                        RoundButton(
                          color: expiditionColors[i],
                          score: round.player2Scores[i],
                          onPressed: () => onScoreRequested(1, i),
                        )
                    ],
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
