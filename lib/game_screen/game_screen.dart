import 'package:flutter/material.dart';
import 'package:flutter_match/game_screen/round_view.dart';
import 'package:flutter_match/scoring_screen/scoring_screen.dart';

import 'game_screen_bloc.dart';

class GameScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  GameScreenBloc _bloc = GameScreenBloc();

  void _onRequestScore(BuildContext context, int player, int expidition) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return ScoringScreen();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lost Cities Scoring Helper"),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) {
          return Divider();
        },
        itemCount: _bloc.rounds.length,
        itemBuilder: (context, index) {
          return RoundView(
            round: _bloc.rounds[index],
            onScoreRequested: (p, e) => _onRequestScore(context, p, e),
          );
        },
      ),
    );
  }
}
