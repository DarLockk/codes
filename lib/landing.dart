import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
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
          colors: [
            Colors.white,
            const Color(0xFFE6F0FF),
          ],
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
                    child: FadeTransition(
                      opacity: _fadeAnimation,
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
                                      fontFamily: 'SFPro', // Police iOS
                                    ),
                                  ),
                                  Text(
                                    "DarLock !",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: darLockColor, // Couleur différente
                                      fontFamily: 'SFPro', // Police iOS
                                    ),
                                  ),
                                  Text(
                                    "Votre porte, sécurisée et connectée.",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black.withOpacity(0.6),
                                      fontFamily: 'SFPro', // Police iOS
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Section texte principal avec DarLock
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "DarLock",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: darLockColor, // Couleur différente
                                fontFamily: 'SFPro', // Police iOS
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Connectivité et Comfort",
                              style: TextStyle(
                                fontSize: 20, // Légèrement plus petit pour équilibrer
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                                fontFamily: 'SFPro', // Police iOS
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
                                fontFamily: 'SFPro', // Police iOS
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 28),
                            // Cartes de fonctionnalités (SFPro conservé)
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
                            // Nouveau bouton avec outline et animation
                            GestureDetector(
                              onTapDown: (_) {
                                _controller.reverse(); // Animation scale au tap
                              },
                              onTapUp: (_) {
                                _controller.forward();
                                Navigator.pushReplacementNamed(context, '/signin');
                              },
                              onTapCancel: () {
                                _controller.forward();
                              },
                              child: MouseRegion(
                                onEnter: (_) => setState(() {}),
                                onExit: (_) => setState(() {}),
                                child: ScaleTransition(
                                  scale: Tween<double>(begin: 1.0, end: 0.95).animate(
                                    CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: darLockColor, width: 2),
                                      borderRadius: BorderRadius.circular(20),
                                      color: _controller.isAnimating
                                          ? darLockColor.withOpacity(0.1)
                                          : Colors.transparent, // Effet au survol/tap
                                    ),
                                    child: Text(
                                      "Commencer",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: darLockColor,
                                        fontFamily: 'SFPro',
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return SizedBox(
      width: 120, // Taille fixe plus petite
      height: 100, // Hauteur fixe plus petite
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8), // Padding réduit
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Coins moins arrondis
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8, // Ombre plus subtile
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color), // Icône plus petite
            const SizedBox(height: 4), // Espacement réduit
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14, // Texte plus petit
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'SFPro', // Police conservée
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10, // Sous-titre plus petit
                color: Colors.black.withOpacity(0.6),
                fontFamily: 'SFPro', // Police conservée
              ),
            ),
          ],
        ),
      ),
    );
  }
}