import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  IO.Socket? socket;

  factory SocketService() {
    return _instance;
  }

  SocketService._internal() {
    // Initialisation de la connexion Socket.IO
    socket = IO.io(
      "http://192.168.1.17:3000",
      IO.OptionBuilder().setTransports(['websocket']).build(),
    );

    socket!.onConnect((_) {
      print("✅ Connecté au serveur WebRTC");
    });

    socket!.onDisconnect((_) {
      print("❌ Déconnecté du serveur");
    });
  }

  void connect() {
    if (socket?.connected != true) {
      socket?.connect();
    }
  }

  void disconnect() {
    if (socket?.connected == true) {
      socket?.disconnect();
    }
  }

  void on(String event, Function(dynamic) callback) {
    socket?.on(event, callback);
  }

  void off(String event) {
    socket?.off(event);
  }
}
