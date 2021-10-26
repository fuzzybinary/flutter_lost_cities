import 'package:flutter_match/network/network_service.dart';

enum CurrentGameState {
  initialization,
  searching,
  connected,
}

class NetworkGameBloc {
  final NetworkService _networkService;

  CurrentGameState get currentGameState {
    return CurrentGameState.initialization;
  }

  NetworkGameBloc(this._networkService);
}
