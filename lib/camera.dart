import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'socket_service.dart';

class LiveCameraScreen extends StatefulWidget {
  @override
  _LiveCameraScreenState createState() => _LiveCameraScreenState();
}

class _LiveCameraScreenState extends State<LiveCameraScreen> {
  Uint8List? imageBytes;
  String connectionStatus = "Non connecté";
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _socketService.connect();
    _socketService.on("video", (data) {
      setState(() {
        imageBytes = Uint8List.fromList(data);
      });
    });

    _socketService.on("connect", (_) {
      setState(() {
        connectionStatus = "Connecté au serveur";
      });
    });

    _socketService.on("disconnect", (_) {
      setState(() {
        connectionStatus = "Déconnecté";
      });
    });
  }

  @override
  void dispose() {
    _socketService.off("video");
    _socketService.off("connect");
    _socketService.off("disconnect");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Live Camera")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Statut : $connectionStatus", style: TextStyle(fontSize: 16)),
          SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 250,
            color: Colors.grey,
            child: Center(
              child:
                  imageBytes != null
                      ? Image.memory(
                        imageBytes!,
                        gaplessPlayback:
                            true, // Optimise l'affichage en évitant de recharger l'image
                        filterQuality:
                            FilterQuality.low, // Réduit la charge de rendu
                      )
                      : CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}
