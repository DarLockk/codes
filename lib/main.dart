import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'notification_utils.dart';
import 'socket_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'signin.dart';
import 'signup.dart';
import 'home_screen.dart';
import 'landing.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('notifications');
  await requestNotificationPermission();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Firebase initialisé avec succès");

  // Configuration du canal de notification
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'channel_id',
    'Channel Name',
    description: 'Channel Description',
    importance: Importance.max,
  );
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Initialisation avec gestion des actions
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Gestion des actions cliquées
      if (response.payload != null) {
        print("Action cliquée : ${response.payload}");
        if (response.payload == 'open_door') {
          print("Action : Ouvrir la porte");
          // TODO : Ajoutez ici la logique pour ouvrir la porte (par exemple, via WebRTC ou une API)
        } else if (response.payload == 'ignore') {
          print("Action : Ignorer");
          // Optionnel : Marquer comme ignorée dans Firestore si nécessaire
        }
      }
    },
  );

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    handleForegroundMessage(message, flutterLocalNotificationsPlugin);
  });

  final SocketService socketService = SocketService();
  socketService.connect();

  String? token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    print("FCM Token récupéré au démarrage : $token");
    await saveFCMTokenToDatabase(token);
  } else {
    print("Erreur : Token FCM non récupéré");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarLock',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'SFPro'),
      home: LandingPage(),
      routes: {
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("=== Début du traitement en arrière-plan ===");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Firebase réinitialisé pour le background handler.");

  if (message.notification != null) {
    print("Message reçu en arrière-plan : ${message.messageId}");
    print("Titre : ${message.notification!.title}");
    print("Corps : ${message.notification!.body}");

    NotificationItem item = NotificationItem(
      title: message.notification!.title!,
      body: message.notification!.body!,
      timestamp: DateTime.now(),
    );

    String? notificationId;
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print("Utilisateur connecté : ${user.uid}");
        DocumentReference ref = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .add(item.toMap());
        notificationId = ref.id;
        print(
          "Notification sauvegardée dans Firestore avec ID : $notificationId",
        );
      } else {
        print(
          "Erreur : Aucun utilisateur connecté dans le background handler.",
        );
      }
    } catch (e) {
      print("Erreur lors de la sauvegarde dans Firestore : $e");
    }

    // Ajout des actions à la notification
    await flutterLocalNotificationsPlugin.show(
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
          actions: [
            AndroidNotificationAction('open_door', 'Ouvrir la porte'),
            AndroidNotificationAction('ignore', 'Ignorer'),
          ],
        ),
      ),
      payload: notificationId, // Passer l'ID Firestore pour référence future
    );
    print("Notification locale affichée avec actions.");
  }
  print("=== Fin du traitement en arrière-plan ===");
}

// Classe utilitaire pour vérifier l'état d'authentification
class AuthChecker {
  static Future<void> checkAndRedirect(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('rememberMe') ?? false;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null && rememberMe) {
      Navigator.pushReplacementNamed(context, '/home');
    } else if (user != null && !rememberMe) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/signin');
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }
}
