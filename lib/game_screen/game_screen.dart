import 'package:flutter/material.dart';
import 'package:flutter_match/game_screen/game_sceen_app_bar.dart';
import 'package:flutter_match/game_screen/round_view.dart';
import 'package:flutter_match/scoring_screen/scoring_screen.dart';
import 'package:flutter_match/tflite/classifier.dart';

import 'game_screen_bloc.dart';

class GameScreen extends StatefulWidget {
  final Classifier classifier;

  GameScreen(this.classifier);

  @override
  State<StatefulWidget> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameScreenBloc _bloc = GameScreenBloc();

  void _onRequestScore(BuildContext context, int player, int expidition) async {
    var scoringResult = await Navigator.push<ScoringResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return ScoringScreen(widget.classifier);
        },
      ),
    );
    if (scoringResult != null) {
      // TODO:
    }
  }

  void _addRound(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Finish this round and start a new round?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("No"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Yes"),
            ),
          ],
        );
      },
    );
    if (result == true) {
      setState(() {
        _bloc.addRound();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addRound(context),
        child: Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: GameScreenAppBar(
              expandedHeight: 200,
              player1Score: _bloc.player1Score,
              player2Score: _bloc.player2Score,
            ),
            pinned: true,
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Column(
                  children: [
                    RoundView(
                      roundNumber: index,
                      round: _bloc.rounds[index],
                      onScoreRequested: (p, e) =>
                          _onRequestScore(context, p, e),
                    ),
                    if (index != _bloc.rounds.length - 1)
                      Divider(
                        color: Colors.black54,
                        thickness: 1,
                      ),
                  ],
                );
              },
              childCount: _bloc.rounds.length,
            ),
          )
        ],
      ),
    );
  }
}
