import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'notification_utils.dart';
import 'socket_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'signin.dart';
import 'signup.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter(); // Initialisation de Hive
  await Hive.openBox('notifications'); // Boîte pour le cache
  await requestNotificationPermission();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Firebase initialisé avec succès");

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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

  print("Début du chargement des notifications persistantes...");
  await loadNotificationsFromFirestore();
  print("Chargement des notifications terminé.");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarLock',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'SFPro'),
      home: AuthWrapper(),
      routes: {
        '/signin': (context) => SignInPage(),
        '/signup': (context) => SignUpPage(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool rememberMe = prefs.getBool('rememberMe') ?? false;
    setState(() {
      _rememberMe = rememberMe;
    });

    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      if (_rememberMe) {
        // Si "Se souvenir de moi" est coché, garder l'utilisateur connecté
        setState(() {
          _isLoggedIn = true;
          _isLoading = false;
        });
      } else {
        // Si "Se souvenir de moi" n'est pas coché, déconnecter l'utilisateur
        await FirebaseAuth.instance.signOut();
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLoggedIn ? HomeScreen() : SignInPage();
  }
}
