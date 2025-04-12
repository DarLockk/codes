import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String body;
  final DateTime timestamp;

  NotificationItem({
    required this.title,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: DateTime.parse(
        map['timestamp'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationItem &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          body == other.body &&
          timestamp == other.timestamp;

  @override
  int get hashCode => title.hashCode ^ body.hashCode ^ timestamp.hashCode;
}

// Fonction pour déterminer l'icône en fonction du titre
IconData getIconForNotification(String title) {
  if (title.toLowerCase().contains("inconnu")) return Icons.warning;
  if (title.toLowerCase().contains("déverrouillée")) return Icons.lock_open;
  return Icons.notifications_active;
}

Future<void> saveNotificationToFirestore(NotificationItem notification) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    print("Utilisateur connecté pour sauvegarde : ${user.uid}");
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print("Mode hors ligne : la notification sera synchronisée plus tard.");
    }
    try {
      DocumentReference ref = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add(notification.toMap());
      print("Notification sauvegardée dans Firestore avec ID : ${ref.id}");
    } catch (e, stackTrace) {
      print("Erreur lors de la sauvegarde dans Firestore : $e");
      print("Stack trace : $stackTrace");
    }
  } else {
    print("Aucun utilisateur connecté, notification non sauvegardée.");
  }
}

void handleForegroundMessage(
  RemoteMessage message,
  FlutterLocalNotificationsPlugin plugin,
) {
  print("Message reçu en avant-plan : ${message.notification?.title}");
  if (message.notification != null) {
    NotificationItem item = NotificationItem(
      title: message.notification!.title!,
      body: message.notification!.body!,
      timestamp: DateTime.now(),
    );
    saveNotificationToFirestore(item);
    plugin.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'channel_id',
          'Channel Name',
          channelDescription: 'Channel Description',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}

Future<void> requestNotificationPermission() async {
  PermissionStatus status = await Permission.notification.request();
  if (status.isGranted) {
    print("Permission de notification accordée");
  } else {
    print("Permission de notification refusée");
  }
}

Future<void> saveFCMTokenToDatabase(String token) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    print("Utilisateur connecté : ${user.uid}");
    DocumentReference ref = FirebaseFirestore.instance
        .collection('fcm_tokens')
        .doc(user.uid);

    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print(
        "Aucune connexion réseau détectée. Le token sera synchronisé plus tard grâce à Firestore offline.",
      );
      await ref.set({
        'token': token,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("Token FCM enregistré localement en mode hors ligne.");
      return;
    } else {
      print("Connexion réseau détectée : $connectivityResult");
    }

    try {
      print("Tentative d'écriture dans Firestore sur le chemin : ${ref.path}");
      await ref
          .set({'token': token, 'timestamp': FieldValue.serverTimestamp()})
          .timeout(
            Duration(seconds: 30),
            onTimeout: () {
              throw Exception("Timeout : impossible d'écrire dans Firestore");
            },
          );
      print("Écriture dans Firestore réussie.");

      print("Début de lecture depuis Firestore sur le chemin : ${ref.path}");
      DocumentSnapshot snapshot = await ref.get().timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception("Timeout : impossible de lire depuis Firestore");
        },
      );
      print("Lecture terminée, valeur : ${snapshot.data()}");
    } catch (error, stackTrace) {
      print("Erreur lors de l'opération sur Firestore : $error");
      print("Stack trace : $stackTrace");
    }
  } else {
    print("Aucun utilisateur connecté.");
  }
}
