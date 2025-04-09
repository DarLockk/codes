import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_wrapper.dart';
import 'landing.dart';
import 'signin.dart';
import 'signup.dart';
import 'home_screen.dart';
import 'settings_page.dart';
import 'notifications.dart';
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key); // Ajout d'un constructeur const

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Videophone',
      theme: AppTheme.theme, // Utilisation de ton thème personnalisé
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'SFPro',
        primaryColor: AppTheme.primaryColor,
        scaffoldBackgroundColor: Colors.grey[900],
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: AppTheme.darLockColor),
          headlineMedium: TextStyle(color: AppTheme.primaryColor),
          bodyMedium: TextStyle(color: Colors.white70),
          bodySmall: TextStyle(color: Colors.white60),
        ),
      ),
      themeMode: ThemeMode.system,
      home: FutureBuilder(
        future: _checkUserAuthStatus(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data == true) {
            return  AuthWrapper();
          } else {
            return const LandingPage();
          }
        },
      ),
      routes: {
        '/landing': (context) => const LandingPage(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) =>  SignUpPage(),
        '/home': (context) =>  HomeScreen(),
        '/settings': (context) => const SettingsPage(),
        '/notifications': (context) =>  NotificationsScreen(),
      },
    );
  }

  Future<bool> _checkUserAuthStatus() async {
    return FirebaseAuth.instance.currentUser != null;
  }
}