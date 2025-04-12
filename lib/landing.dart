import 'package:flutter/material.dart';
import 'main.dart'; // Importer pour accéder à AuthChecker
import 'package:firebase_auth/firebase_auth.dart'; // Pour vérifier l'état de connexion

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isLoggedIn = false; // État pour suivre si l'utilisateur est connecté

  @override
  void initState() {
    super.initState();

    // Vérifier l'état de connexion au démarrage
    _checkLoginStatus();
  }

  void _checkLoginStatus() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isLoggedIn = true;
      });
      // Si connecté, redirection automatique après 3 secondes
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          AuthChecker.checkAndRedirect(context);
        }
      });
    } else {
      setState(() {
        _isLoggedIn = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF007AFF); // Bleu iOS
    final secondaryColor = const Color(0xFF4A6CF7); // Bleu violet subtil
    final darLockColor = const Color(0xFF004AAD); // Bleu foncé pour DarLock
    final size = MediaQuery.of(context).size;

    // Fond avec dégradé et cercles décoratifs
    final background = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFE6F0FF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.6,
              height: size.height * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            child: Container(
              width: size.width * 0.5,
              height: size.height * 0.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondaryColor.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          background,
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Section de bienvenue avec logo et nom DarLock
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/logo_doorbel.png',
                            height: 50,
                            fit: BoxFit.contain,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bienvenue chez",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontFamily: 'SFPro',
                                  ),
                                ),
                                Text(
                                  "DarLock !",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: darLockColor,
                                    fontFamily: 'SFPro',
                                  ),
                                ),
                                Text(
                                  "Votre porte, sécurisée et connectée.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black.withOpacity(0.6),
                                    fontFamily: 'SFPro',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Section texte principal avec DarLock
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "DarLock",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darLockColor,
                            fontFamily: 'SFPro',
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "Connectivité et Comfort",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'SFPro',
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Ouvrez et surveillez votre porte, où que vous soyez.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.8),
                            fontFamily: 'SFPro',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 28),
                        // Cartes de fonctionnalités
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            _buildFeatureCard(
                              icon: Icons.face,
                              title: "Face ID",
                              subtitle: "Déverrouillage sécurisé",
                              color: primaryColor,
                            ),
                            _buildFeatureCard(
                              icon: Icons.lock_open,
                              title: "Ouverture à distance",
                              subtitle: "Contrôle à distance",
                              color: secondaryColor,
                            ),
                            _buildFeatureCard(
                              icon: Icons.camera,
                              title: "Caméra en direct",
                              subtitle: "Voir en temps réel",
                              color: primaryColor,
                            ),
                            _buildFeatureCard(
                              icon: Icons.notifications,
                              title: "Alertes",
                              subtitle: "Notifications instantanées",
                              color: secondaryColor,
                            ),
                          ],
                        ),
                        const SizedBox(height: 55),
                        // Condition : nouveau bouton circulaire ou indicateur visuel
                        if (!_isLoggedIn)
                          GestureDetector(
                            onTap: () {
                              AuthChecker.checkAndRedirect(context);
                            },
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [darLockColor, primaryColor],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: darLockColor.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLoadingDot(darLockColor),
                                  const SizedBox(width: 8),
                                  _buildLoadingDot(darLockColor),
                                  const SizedBox(width: 8),
                                  _buildLoadingDot(darLockColor),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Chargement...",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: darLockColor,
                                  fontFamily: 'SFPro',
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour un point clignotant
  Widget _buildLoadingDot(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.8),
      ),
      onEnd: () {
        setState(() {}); // Relance l'animation en boucle
      },
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return SizedBox(
      width: 120,
      height: 100,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'SFPro',
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.black.withOpacity(0.6),
                fontFamily: 'SFPro',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
