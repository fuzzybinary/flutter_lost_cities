import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_match/network/network_service.dart';

import 'network_game_bloc.dart';

class NetworkGameDialog extends StatefulWidget {
  final NetworkService networkService;

  const NetworkGameDialog({
    Key? key,
    required this.networkService,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NetworkGameState();
}

class _NetworkGameState extends State<NetworkGameDialog> {
  late final NetworkGameBloc _bloc;

  @override
  void initState() {
    super.initState();

    _bloc = NetworkGameBloc(widget.networkService);
  }

  @override
  void dispose() {
    _bloc.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Networked Game'),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: _buildInnerWidget(),
        ),
      ],
    );
  }

  Widget _buildInnerWidget() {
    switch (_bloc.currentGameState) {
      case CurrentGameState.searching:
        return _buildSearchingWidget();

      case CurrentGameState.connected:
        return _buildConnectedWidget();

      case CurrentGameState.initialization:
      default:
        return _buildNameInnerWidget();
    }
  }

  Widget _buildSearchingWidget() {
    return Column(
      children: [
        for (var game in _bloc.gameList)
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: Text(game.name)),
                ElevatedButton(
                  child: const Text('Join'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0),
              child: ElevatedButton(
                child: const Text('Cancel'),
                onPressed: () {
                  setState(() {
                    _bloc.cancelSearch();
                  });
                },
              ),
            ),
            const CircularProgressIndicator(),
          ],
        )
      ],
    );
  }

  Widget _buildConnectedWidget() {
    return Container();
  }

  Widget _buildNameInnerWidget() {
    return Column(children: [
      TextFormField(
        initialValue: _bloc.gameName,
        onChanged: (v) => setState(() {
          _bloc.gameName = v;
        }),
        inputFormatters: [
          FilteringTextInputFormatter.deny(';'),
        ],
        decoration: const InputDecoration(
          labelText: 'Name:',
          border: OutlineInputBorder(),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            child: const Text('Search'),
            onPressed: _bloc.gameName.isEmpty ? null : _beginSearch,
          ),
        ],
      ),
    ]);
  }

  void _beginSearch() {
    setState(() {
      _bloc.beginSearch(_onGameListChanged);
    });
  }

  void _onGameListChanged(List<SearchResult> games) {
    setState(() {});
  }
}
