import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_match/models/game_round.dart';

import 'expanding_section.dart';

typedef ScoreCallback = void Function(int player, int expidition);

class RoundButton extends StatelessWidget {
  final Color color;
  final int score;
  final Function() onPressed;

  void todo() {}

  RoundButton(
      {required this.color, required this.score, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.only(left: 4.0, right: 4.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(primary: color),
        onPressed: onPressed,
        child: Text(
          score.toString(),
        ),
      ),
    );
  }
}

class RoundDetails extends StatelessWidget {
  final GameRound round;
  final ScoreCallback onScoreRequested;

  final List<String> colors = ["Yellow", "Blue", "White", "Green", "Red"];

  final List<Color> expiditionColors = [
    Colors.yellow.shade600,
    Colors.blueAccent,
    Colors.grey,
    Colors.green,
    Colors.redAccent
  ];

  RoundDetails({Key? key, required this.round, required this.onScoreRequested})
      : super(key: key);

  Widget _expiditionRow(int expiditionIndex) {
    return Row(
      children: [
        Text(colors[expiditionIndex]),
        Expanded(
          child: Container(),
        ),
        RoundButton(
          color: expiditionColors[expiditionIndex],
          score: round.player1Scores[expiditionIndex],
          onPressed: () => onScoreRequested(0, expiditionIndex),
        ),
        RoundButton(
          color: expiditionColors[expiditionIndex],
          score: round.player2Scores[expiditionIndex],
          onPressed: () => onScoreRequested(1, expiditionIndex),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(left: 15, right: 5),
      child: Column(
        children: [for (int i = 0; i < 5; ++i) _expiditionRow(i)],
      ),
    );
  }
}

@immutable
class RoundView extends StatefulWidget {
  final int roundNumber;
  final GameRound round;
  final ScoreCallback onScoreRequested;

  RoundView(
      {Key? key,
      required this.roundNumber,
      required this.round,
      required this.onScoreRequested})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _RoundViewState();
}

class _RoundViewState extends State<RoundView> {
  bool _expanded = false;

  void _onExpand() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  Widget _scoreWidget(ThemeData theme, String text) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Text(
        text,
        style: theme.textTheme.headline5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(left: 6, right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: _onExpand,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Text(
                  "Round ${widget.roundNumber}",
                  style: theme.textTheme.headline5,
                ),
                Expanded(child: Container()),
                _scoreWidget(theme, widget.round.player1Score.toString()),
                _scoreWidget(theme, "-"),
                _scoreWidget(theme, widget.round.player2Score.toString())
              ],
            ),
          ),
          ExpandingSection(
            expand: _expanded,
            child: RoundDetails(
              round: widget.round,
              onScoreRequested: widget.onScoreRequested,
            ),
          ),
        ],
      ),
    );
  }
}
