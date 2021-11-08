import 'dart:async';

import 'package:flutter_match/network/network_service.dart';

enum CurrentGameState {
  initialization,
  searching,
  connected,
}

typedef GameListChangedCallback = void Function(List<SearchResult> games);

class NetworkGameBloc {
  final NetworkService _networkService;

  var _gameName = '';
  String get gameName => _gameName;

  var _currentGameState = CurrentGameState.initialization;
  CurrentGameState get currentGameState => _currentGameState;

  var _gameList = <SearchResult>[];
  List<SearchResult> get gameList => _gameList;

  StreamSubscription? _searchSubscription;

  set gameName(String name) {
    // Don't allow semi-colons in game names. It will mess up handshake parsing.
    _gameName = name.replaceAll(';', '');
  }

  NetworkGameBloc(this._networkService) {
    _gameName = _networkService.gameName ?? '';
  }

  void beginSearch(GameListChangedCallback onGameListChanged) {
    _currentGameState = CurrentGameState.searching;
    _searchSubscription =
        _networkService.startSearch(gameName).listen((gameList) {
      _gameList = gameList;
      onGameListChanged(gameList);
    }, onError: (error) {});
  }

  void cancelSearch() {
    _searchSubscription?.cancel();
    _searchSubscription = null;

    _currentGameState = CurrentGameState.initialization;
  }

  void dispose() {
    _searchSubscription?.cancel();
  }
}
