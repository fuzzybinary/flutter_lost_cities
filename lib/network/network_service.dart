import 'dart:async';
import 'dart:io';

class ConnectionRequest {
  final String name;
  final InternetAddress address;
  final int port;

  ConnectionRequest(this.name, this.address, this.port);
}

class NetworkService {
  static const _handshakeOpening = '//LC:HELPER';
  static const _searchPort = 10054;
  static final _searchAddress = InternetAddress('239.11.10.2');

  RawDatagramSocket? _searchSocket;
  StreamSubscription? _searchSubscription;
  Timer? _broadcastTimer;

  final StreamController<ConnectionRequest> _connectionStreamController =
      StreamController();
  Stream<ConnectionRequest> get onConnectionRequest =>
      _connectionStreamController.stream.asBroadcastStream();

  Future<void> startSearch(String withName) async {
    _searchSocket =
        await RawDatagramSocket.bind(InternetAddress.anyIPv4, _searchPort);

    _searchSocket!.joinMulticast(_searchAddress);
    _searchSubscription = _searchSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        var datagram = _searchSocket?.receive();
        if (datagram != null) {
          _onSearchResponse(datagram);
        }
      }
    });

    _broadcastTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_searchSocket != null) {
        var handshake =
            '$_handshakeOpening;${_searchSocket!.address.toString()};$_searchPort;$withName';

        _searchSocket!.send(handshake.codeUnits, _searchAddress, _searchPort);
      }
    });
  }

  void cancelSearch() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;

    _searchSubscription?.cancel();
    _searchSubscription = null;

    _searchSocket?.close();
    _searchSocket = null;
  }

  void _onSearchResponse(Datagram datagram) {
    var broadcastInfo = String.fromCharCodes(datagram.data);
    if (broadcastInfo.startsWith('//LC:HELPER')) {
      var parsedOkay = false;
      var params = broadcastInfo.split(';');
      if (params.length != 4) {
        try {
          var addressString = params[1];
          var portString = params[2];
          var name = params[3];

          var address = InternetAddress(addressString);
          var port = int.parse(portString);
          _connectionStreamController.sink.add(ConnectionRequest(
            name,
            address,
            port,
          ));
        } catch (e) {
          print('Exception parsing broadcast: ${e.toString()}');
        }
      }

      if (!parsedOkay) {
        print("Failed to parse broadcast. Datagram was: '$broadcastInfo'");
      }
    }
  }
}
