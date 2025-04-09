import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF007AFF);
  static const Color secondaryColor = Color(0xFF4A6CF7);
  static const Color darLockColor = Color(0xFF004AAD);

  static final ThemeData theme = ThemeData(
    fontFamily: 'SFPro',
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darLockColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: Colors.black87,
      ),
      bodySmall: TextStyle(
        fontSize: 10,
        color: Colors.black54,
      ),
    ),
  );

  static BoxDecoration gradientBackground(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFE6F0FF)],
      ),
      // Ajoute les cercles décoratifs
    ).copyWith(
      // Ajoute ici les cercles si tu veux les réutiliser partout
      // Sinon, fais une méthode séparée pour ça
    );
  }

  static BoxShadow subtleShadow() {
    return BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 4),
    );
  }
}