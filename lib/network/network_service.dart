import 'dart:async';
import 'dart:io';

import 'package:network_info_plus/network_info_plus.dart';

typedef OnGameListChanged = void Function(List<SearchResult> games);

class SearchResult {
  final String name;
  final InternetAddress address;
  final int port;
  DateTime lastSeen;

  SearchResult(this.name, this.address, this.port, this.lastSeen);
}

class ConnectionRequest {
  final String name;
  final InternetAddress address;
  final int port;

  const ConnectionRequest(this.name, this.address, this.port);
}

class NetworkService {
  static const _handshakeOpening = '//LC:HELPER';
  static const _searchPort = 10054;
  static final _searchAddress = InternetAddress('239.11.10.2');
  static const _gameTtl = Duration(seconds: 30);

  String? _gameName;
  String? get gameName => _gameName;

  Stream<List<SearchResult>> startSearch(String withName) {
    _gameName = withName;

    Timer? broadcastTimer;
    RawDatagramSocket? searchSocket;
    StreamSubscription? searchSubscription;

    late StreamController<List<SearchResult>> controller;

    controller = StreamController<List<SearchResult>>(
      onListen: () async {
        final networkInfo = NetworkInfo();
        final ipAddress = await networkInfo.getWifiIP();

        if (ipAddress == null) {
          controller.addError('Failed to get wifi address for search');
          return;
        }

        searchSocket =
            await RawDatagramSocket.bind(InternetAddress.anyIPv4, _searchPort);

        final foundGames = <SearchResult>[];

        searchSocket!.joinMulticast(_searchAddress);
        searchSubscription = searchSocket!.listen((event) {
          if (event == RawSocketEvent.read) {
            var datagram = searchSocket?.receive();
            if (datagram != null) {
              //if (datagram.address.address != ipAddress) {
              var result = _parseSearchResult(datagram);
              if (result != null && _updateGameList(foundGames, result)) {
                controller.add(foundGames);
              }
              //}
            }
          }
        });

        broadcastTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
          if (searchSocket != null) {
            var handshake =
                '$_handshakeOpening;$ipAddress;$_searchPort;$withName';

            searchSocket!
                .send(handshake.codeUnits, _searchAddress, _searchPort);
          }

          final expirationTime = DateTime.now().subtract(_gameTtl);
          if (_removeOldGames(foundGames, expirationTime)) {
            controller.add(foundGames);
          }
        });
      },
      onCancel: () {
        broadcastTimer?.cancel();

        searchSubscription?.cancel();

        searchSocket?.close();
        controller.close();
      },
    );

    return controller.stream;
  }

  SearchResult? _parseSearchResult(Datagram datagram) {
    SearchResult? result;
    var broadcastInfo = String.fromCharCodes(datagram.data);
    if (broadcastInfo.startsWith('//LC:HELPER')) {
      var params = broadcastInfo.split(';');
      if (params.length == 4) {
        try {
          var addressString = params[1];
          var portString = params[2];
          var name = params[3];

          var address = InternetAddress(addressString);
          var port = int.parse(portString);
          result = SearchResult(name, address, port, DateTime.now());
          // ignore: empty_catches
        } catch (e) {}
      }
    }

    return result;
  }

  /// Update the list of available games, or change the last seen time if the game
  /// already existed. Returns true if the list was modified
  static bool _updateGameList(
      List<SearchResult> gameList, SearchResult newResult) {
    for (var game in gameList) {
      if (game.address == newResult.address) {
        if (game.name == newResult.name) {
          game.lastSeen = newResult.lastSeen;
          return false;
        } else {
          gameList.remove(game);
          gameList.add(newResult);
          return true;
        }
      }
    }
    gameList.add(newResult);
    return true;
  }

  // Scan through this list of games and remove any that we haven't seen since [expirationTime]
  static bool _removeOldGames(
      List<SearchResult> gameList, DateTime experationTime) {
    final length = gameList.length;
    gameList.removeWhere((e) => e.lastSeen.isBefore(experationTime));
    return gameList.length < length;
  }
}
