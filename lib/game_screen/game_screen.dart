import 'package:flutter/material.dart';
import 'package:flutter_match/game_screen/game_sceen_app_bar.dart';
import 'package:flutter_match/game_screen/round_view.dart';
import 'package:flutter_match/models/game_round.dart';
import 'package:flutter_match/network/network_service.dart';
import 'package:flutter_match/scoring_screen/scoring_screen.dart';
import 'package:flutter_match/tflite/classifier.dart';

import 'game_screen_bloc.dart';
import '../network/network_game_dialog.dart';

class GameScreen extends StatefulWidget {
  final Classifier classifier;
  final NetworkService networkService;

  const GameScreen(
    this.classifier,
    this.networkService, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  static const _newGameAction = 'new_game';
  static const _networkGameAction = 'network_game';

  final GameScreenBloc _bloc = GameScreenBloc();

  void _onPopupMenuItemSelected(String value) {
    switch (value) {
      case _newGameAction:
        //print("new game");
        break;
      case _networkGameAction:
        showDialog(
          context: context,
          builder: (context) => NetworkGameDialog(
            networkService: widget.networkService,
          ),
        );
        break;
    }
  }

  void _onRequestScore(
      BuildContext context, int player, ExpiditionColorIndex expidition) async {
    await Navigator.push<ScoringResult>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return ScoringScreen(
            classifier: widget.classifier,
            initialExpidition: expidition,
            round: _bloc.rounds.last,
          );
        },
      ),
    );
    // Reset round scores when we return
    setState(() {});
  }

  void _addRound(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Finish this round and start a new round?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
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
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            delegate: GameScreenAppBar(
                expandedHeight: 200,
                player1Score: _bloc.player1Score,
                player2Score: _bloc.player2Score,
                onPopupSelected: _onPopupMenuItemSelected,
                popupItems: [
                  const PopupMenuItem(
                    value: _newGameAction,
                    child: Text('New Game'),
                  ),
                  const PopupMenuItem(
                    value: _networkGameAction,
                    child: Text('Join Network Game'),
                  )
                ]),
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
                      const Divider(
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
