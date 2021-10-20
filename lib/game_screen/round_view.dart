import 'package:flutter/material.dart';
import 'package:flutter_match/models/game_round.dart';

import 'expanding_section.dart';

typedef ScoreCallback = void Function(
    int player, ExpiditionColorIndex expidition);

class RoundButton extends StatelessWidget {
  final Color color;
  final int score;
  final Function() onPressed;
  final bool enabled;

  RoundButton({
    required this.color,
    required this.score,
    required this.onPressed,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: 80),
      padding: const EdgeInsets.only(left: 4.0, right: 4.0),
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            return this.color;
          }),
        ),
        onPressed: enabled ? onPressed : null,
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

  RoundDetails({Key? key, required this.round, required this.onScoreRequested})
      : super(key: key);

  Widget _expiditionRow(ExpiditionColorIndex expiditionColor) {
    return Row(
      children: [
        Text(expiditionColorNames[expiditionColor.index]),
        Expanded(
          child: Container(),
        ),
        RoundButton(
          color: expiditionColors[expiditionColor.index],
          score: round.player1Scores[expiditionColor.index],
          enabled: !round.isComplete,
          onPressed: () => onScoreRequested(0, expiditionColor),
        ),
        RoundButton(
          color: expiditionColors[expiditionColor.index],
          score: round.player2Scores[expiditionColor.index],
          enabled: !round.isComplete,
          onPressed: () => onScoreRequested(1, expiditionColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 15, right: 5),
      child: Column(
        children:
            ExpiditionColorIndex.values.map((e) => _expiditionRow(e)).toList(),
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

  @override
  void initState() {
    super.initState();

    _expanded = !widget.round.isComplete;
    widget.round.isCompleteStream.listen((isComplete) {
      // This is switching from incomplete to complete,
      // close it up.
      if (isComplete) {
        setState(() {
          _expanded = false;
        });
      }
    });
  }

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
    var theme = Theme.of(context);
    if (widget.round.isComplete) {
      final textTheme = theme.textTheme
          .apply(bodyColor: Colors.grey, displayColor: Colors.grey);
      theme = theme.copyWith(textTheme: textTheme);
    }

    return Theme(
      data: theme,
      child: Container(
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
            )
          ],
        ),
      ),
    );
  }
}
