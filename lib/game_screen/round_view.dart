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
  final int roundNumber;
  final GameRound round;
  final ScoreCallback onScoreRequested;

  RoundView(
      {Key? key,
      required this.roundNumber,
      required this.round,
      required this.onScoreRequested})
      : super(key: key);

  Widget _buildPlayerScore(
      {required ThemeData theme,
      required int playerNumber,
      required int score}) {
    return Container(
      padding: EdgeInsets.all(5),
      child: Column(
        children: [
          Text("Player $playerNumber"),
          Text(
            score.toString(),
            style: theme.textTheme.headline3,
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Color> expiditionColors = [
      Colors.yellow.shade600,
      Colors.blueAccent,
      Colors.grey,
      Colors.green,
      Colors.redAccent
    ];

    final theme = Theme.of(context);

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Round $roundNumber", style: theme.textTheme.headline4),
          Container(
              padding: EdgeInsets.fromLTRB(8, 0, 30, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildPlayerScore(
                        theme: theme,
                        playerNumber: 1,
                        score: round.player1Score,
                      ),
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
                  Row(
                    children: [
                      for (int i = 0; i < 5; ++i)
                        RoundButton(
                          color: expiditionColors[i],
                          score: round.player2Scores[i],
                          onPressed: () => onScoreRequested(1, i),
                        ),
                      _buildPlayerScore(
                        theme: theme,
                        playerNumber: 2,
                        score: round.player2Score,
                      ),
                    ],
                  ),
                ],
              )),
        ],
      ),
    );
  }
}
