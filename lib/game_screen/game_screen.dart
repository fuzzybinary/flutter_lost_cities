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

  void _onRequestScore(BuildContext context, int player, int expidition) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ScoringScreen(widget.classifier);
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              delegate: GameScreenAppBar(expandedHeight: 200),
              pinned: true,
            ),
            // Create a SliverList.
            SliverList(
              // Use a delegate to build items as they're scrolled on screen.
              delegate: SliverChildBuilderDelegate(
                // The builder function returns a ListTile with a title that
                // displays the index of the current item.
                (context, index) {
                  return RoundView(
                    roundNumber: index,
                    round: _bloc.rounds[index],
                    onScoreRequested: (p, e) => _onRequestScore(context, p, e),
                  );
                },
                // Builds 1000 ListTiles
                childCount: _bloc.rounds.length,
              ),
            )
          ],
        ),
      ),
    );
  }
}
