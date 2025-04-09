import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';
import 'camera.dart';
import 'notifications.dart';
import 'settings_page.dart';
import 'notification_utils.dart';
import 'theme.dart';
import 'unlock_door.dart';
import 'face_recognition.dart' as face; // Ajout du préfixe

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveTokenOnStart();
      _fetchUsernameAndPromptIfMissing();
    });
  }

  Future<bool> _isUsernameUnique(String username) async {
    QuerySnapshot query =
        await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: username)
            .get();
    return query.docs.isEmpty;
  }

  Future<void> _fetchUsernameAndPromptIfMissing() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists && doc['username'] != null) {
        setState(() {
          _username = doc['username'];
        });
      } else {
        TextEditingController usernameController = TextEditingController();
        String? newUsername;
        bool isUnique = false;

        while (!isUnique) {
          newUsername = await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  title: const Text("Choisissez un nom d'utilisateur"),
                  content: TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      hintText: "Entrez un nom d'utilisateur",
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(usernameController.text.trim());
                      },
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
          );

          if (newUsername == null || newUsername.isEmpty) {
            continue;
          }

          await FirebaseFirestore.instance.runTransaction((transaction) async {
            QuerySnapshot query =
                await FirebaseFirestore.instance
                    .collection('users')
                    .where('username', isEqualTo: newUsername)
                    .get();
            if (query.docs.isEmpty) {
              isUnique = true;
              DocumentReference userDocRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid);
              transaction.set(userDocRef, {
                'username': newUsername,
                'email': user.email,
                'createdAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }
          });

          if (!isUnique) {
            await showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Erreur'),
                    content: const Text(
                      'Ce nom d\'utilisateur est déjà pris. Veuillez en choisir un autre.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
            );
          }
        }

        setState(() {
          _username = newUsername;
        });
      }
    }
  }

  Future<void> _saveTokenOnStart() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        print("FCM Token initial : $token");
        await saveFCMTokenToDatabase(token);
        await FirebaseMessaging.instance.deleteToken();
        String? newToken = await FirebaseMessaging.instance.getToken();
        if (newToken != null) {
          print("Nouveau FCM Token après régénération : $newToken");
          await saveFCMTokenToDatabase(newToken);
        } else {
          print(
            "Erreur : Impossible de récupérer le nouveau token après régénération",
          );
        }
      } else {
        print(
          "Erreur : Impossible de récupérer le token initial dans HomeScreen",
        );
      }
    } catch (e) {
      print("Erreur lors de la gestion du token FCM : $e");
    }
  }

  Future<void> _signOut() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('rememberMe', false);
      await prefs.remove('identifier');
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      print("Erreur lors de la déconnexion : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la déconnexion : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double padding = (size.width * 0.05).clamp(16.0, 24.0);
    final double iconSize = (size.width * 0.08).clamp(24.0, 32.0);

    final background = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
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
                color: AppTheme.primaryColor.withOpacity(0.1),
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
                color: AppTheme.secondaryColor.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(size),
      body: Stack(
        children: [
          background,
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(padding),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.menu,
                              color: AppTheme.darLockColor,
                              size: iconSize,
                            ),
                            onPressed: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                          Expanded(
                            child: Text(
                              "Bonjour, ${_username ?? 'Utilisateur'}",
                              style: TextStyle(
                                fontSize: (size.width * 0.06).clamp(18.0, 24.0),
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darLockColor,
                                fontFamily: 'SFPro',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.logout,
                              color: AppTheme.darLockColor,
                              size: iconSize,
                            ),
                            onPressed: _signOut,
                          ),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: size.width * 0.02,
                      runSpacing: size.height * 0.02,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildActionCard(
                          context: context,
                          icon: Icons.lock_open,
                          title: "Déverrouiller",
                          color: AppTheme.primaryColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UnlockDoorScreen(),
                              ),
                            );
                          },
                          size: size,
                        ),
                        _buildActionCard(
                          context: context,
                          icon: Icons.videocam,
                          title: "Caméra",
                          color: Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LiveCameraScreen(),
                              ),
                            );
                          },
                          size: size,
                        ),
                        _buildActionCard(
                          context: context,
                          icon: Icons.face,
                          title: "Visages",
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => face.FaceRecognitionScreen(),
                              ),
                            );
                          },
                          size: size,
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.03),
                    Text(
                      "Statut",
                      style: TextStyle(
                        fontSize: (size.width * 0.05).clamp(16.0, 20.0),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darLockColor,
                        fontFamily: 'SFPro',
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    _buildStatusCard(
                      icon: Icons.lock,
                      title: "Porte",
                      subtitle: "Verrouillée",
                      color: AppTheme.primaryColor,
                      size: size,
                    ),
                    SizedBox(height: size.height * 0.01),
                    _buildStatusCard(
                      icon: Icons.videocam,
                      title: "Caméra",
                      subtitle: "Active",
                      color: Colors.green,
                      size: size,
                    ),
                    SizedBox(height: size.height * 0.03),
                    Text(
                      "Activité récente",
                      style: TextStyle(
                        fontSize: (size.width * 0.05).clamp(16.0, 20.0),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darLockColor,
                        fontFamily: 'SFPro',
                      ),
                    ),
                    SizedBox(height: size.height * 0.01),
                    _buildActivityItem(
                      icon: Icons.lock_open,
                      title: "Porte déverrouillée",
                      subtitle: "Aujourd'hui, 14:30",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardScreen(),
                          ),
                        );
                      },
                      size: size,
                    ),
                    _buildActivityItem(
                      icon: Icons.face,
                      title: "Visage détecté",
                      subtitle: "Aujourd'hui, 14:15",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => face.FaceRecognitionScreen(),
                          ),
                        );
                      },
                      size: size,
                    ),
                    _buildActivityItem(
                      icon: Icons.videocam,
                      title: "Caméra activée",
                      subtitle: "Aujourd'hui, 14:00",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LiveCameraScreen(),
                          ),
                        );
                      },
                      size: size,
                    ),
                    _buildActivityItem(
                      icon: Icons.notifications,
                      title: "Voir les notifications",
                      subtitle: "Consultez vos alertes",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationsScreen(),
                          ),
                        );
                      },
                      size: size,
                    ),
                    _buildActivityItem(
                      icon: Icons.settings,
                      title: "Paramètres",
                      subtitle: "Personnalisez vos préférences",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsPage(),
                          ),
                        );
                      },
                      size: size,
                    ),
                    SizedBox(height: size.height * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Drawer avec espacement réduit et icônes plus grandes
  Widget _buildDrawer(Size size) {
    final double minCollapsedWidth = (size.width * 0.15).clamp(80.0, 100.0);
    final double maxCollapsedWidth = (size.width * 0.25).clamp(100.0, 140.0);
    final double minExpandedWidth = (size.width * 0.55).clamp(240.0, 350.0);
    final double maxExpandedWidth = (size.width * 0.75).clamp(300.0, 450.0);

    final bool useCompactMode = size.width >= 360;
    final double drawerWidth =
        useCompactMode && !_isDrawerExpanded
            ? (size.width * 0.2).clamp(minCollapsedWidth, maxCollapsedWidth)
            : (size.width * 0.6).clamp(minExpandedWidth, maxExpandedWidth);

    return Drawer(
      width: drawerWidth,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, const Color(0xFFE6F0FF)],
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // En-tête du Drawer
            Container(
              height: (size.height * 0.15).clamp(100.0, 140.0),
              margin: EdgeInsets.all((size.width * 0.01).clamp(4.0, 8.0)),
              padding: EdgeInsets.all((size.width * 0.01).clamp(4.0, 8.0)),
              child: SafeArea(
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (drawerWidth * 0.3).clamp(
                          48.0,
                          64.0,
                        ), // Ajusté pour icônes plus grandes
                      ),
                      child: CircleAvatar(
                        radius: (size.width * 0.07).clamp(
                          24.0,
                          32.0,
                        ), // Augmenté
                        backgroundColor: Colors.transparent,
                        child: Icon(
                          Icons.person,
                          color: AppTheme.primaryColor,
                          size: (size.width * 0.07).clamp(
                            24.0,
                            32.0,
                          ), // Augmenté
                        ),
                      ),
                    ),
                    if (!useCompactMode || _isDrawerExpanded) ...[
                      SizedBox(width: (size.width * 0.01).clamp(4.0, 8.0)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _username ?? 'Utilisateur',
                              style: TextStyle(
                                fontSize: (size.width * 0.045).clamp(
                                  16.0,
                                  20.0,
                                ), // Ajusté
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darLockColor,
                                fontFamily: 'SFPro',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? '',
                              style: TextStyle(
                                fontSize: (size.width * 0.04).clamp(
                                  14.0,
                                  18.0,
                                ), // Ajusté
                                color: Colors.grey[600],
                                fontFamily: 'SFPro',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Éléments de navigation
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Section 1 : Navigation
                  if (!useCompactMode || _isDrawerExpanded)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (size.width * 0.01).clamp(4.0, 8.0),
                        vertical: (size.height * 0.005).clamp(
                          4.0,
                          6.0,
                        ), // Réduit
                      ),
                      child: Text(
                        "Navigation",
                        style: TextStyle(
                          fontSize: (size.width * 0.045).clamp(
                            16.0,
                            20.0,
                          ), // Ajusté
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darLockColor,
                          fontFamily: 'SFPro',
                        ),
                      ),
                    ),
                  _buildDrawerItem(
                    icon: Icons.dashboard,
                    title: "Tableau de bord",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DashboardScreen(),
                        ),
                      );
                    },
                    size: size,
                    iconColor: AppTheme.primaryColor,
                    drawerWidth: drawerWidth,
                  ),
                  _buildDrawerItem(
                    icon: Icons.videocam,
                    title: "Caméra en direct",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveCameraScreen(),
                        ),
                      );
                    },
                    size: size,
                    iconColor: Colors.green,
                    drawerWidth: drawerWidth,
                  ),
                  _buildDrawerItem(
                    icon: Icons.face,
                    title: "Reconnaissance faciale",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => face.FaceRecognitionScreen(),
                        ),
                      );
                    },
                    size: size,
                    iconColor: Colors.orange,
                    drawerWidth: drawerWidth,
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications,
                    title: "Notifications",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationsScreen(),
                        ),
                      );
                    },
                    size: size,
                    iconColor: AppTheme.primaryColor,
                    drawerWidth: drawerWidth,
                  ),
                  // Séparateur après la première section
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: (size.width * 0.01).clamp(4.0, 8.0),
                    ),
                    child: Divider(color: Colors.grey[300], thickness: 1),
                  ),
                  // Section 2 : Paramètres et Déconnexion
                  if (!useCompactMode || _isDrawerExpanded)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (size.width * 0.01).clamp(4.0, 8.0),
                        vertical: (size.height * 0.005).clamp(
                          4.0,
                          6.0,
                        ), // Réduit
                      ),
                      child: Text(
                        "Paramètres",
                        style: TextStyle(
                          fontSize: (size.width * 0.045).clamp(
                            16.0,
                            20.0,
                          ), // Ajusté
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darLockColor,
                          fontFamily: 'SFPro',
                        ),
                      ),
                    ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: "Paramètres",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsPage()),
                      );
                    },
                    size: size,
                    iconColor: AppTheme.primaryColor,
                    drawerWidth: drawerWidth,
                  ),
                ],
              ),
            ),
            // Bouton pour élargir/réduire le Drawer
            if (useCompactMode)
              Padding(
                padding: EdgeInsets.symmetric(
                  vertical: (size.height * 0.005).clamp(4.0, 6.0),
                ), // Réduit
                child: IconButton(
                  icon: Icon(
                    _isDrawerExpanded
                        ? Icons.arrow_back_ios
                        : Icons.arrow_forward_ios,
                    color: AppTheme.primaryColor,
                    size: (size.width * 0.06).clamp(20.0, 28.0), // Augmenté
                  ),
                  onPressed: () {
                    setState(() {
                      _isDrawerExpanded = !_isDrawerExpanded;
                    });
                  },
                ),
              ),
            // Élément "Déconnexion"
            _buildDrawerItem(
              icon: Icons.logout,
              title: "Déconnexion",
              onTap: _signOut,
              size: size,
              iconColor: Colors.red[400],
              textColor: Colors.red[400],
              drawerWidth: drawerWidth,
            ),
            SizedBox(height: (size.height * 0.01).clamp(6.0, 10.0)),
          ],
        ),
      ),
    );
  }

  // Widget pour les éléments du Drawer (avec espacement réduit et icônes plus grandes)
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Size size,
    required double drawerWidth,
    Color? iconColor,
    Color? textColor,
  }) {
    final bool useCompactMode = size.width >= 360;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: (size.width * 0.01).clamp(4.0, 8.0),
        vertical: (size.height * 0.002).clamp(2.0, 4.0), // Réduit
      ),
      child: InkWell(
        onTap: onTap,
        hoverColor: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: (size.height * 0.005).clamp(4.0, 6.0), // Réduit
            horizontal: (size.width * 0.01).clamp(4.0, 8.0),
          ),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: (drawerWidth * 0.3).clamp(
                    40.0,
                    56.0,
                  ), // Ajusté pour icônes plus grandes
                ),
                child: CircleAvatar(
                  radius: (size.width * 0.06).clamp(20.0, 28.0), // Augmenté
                  backgroundColor: Colors.transparent,
                  child: Icon(
                    icon,
                    color: iconColor ?? AppTheme.primaryColor,
                    size: (size.width * 0.06).clamp(20.0, 28.0), // Augmenté
                  ),
                ),
              ),
              if (!useCompactMode || _isDrawerExpanded) ...[
                SizedBox(width: (size.width * 0.01).clamp(4.0, 8.0)),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: (size.width * 0.04).clamp(16.0, 20.0), // Ajusté
                      fontWeight: FontWeight.bold,
                      color: textColor ?? AppTheme.darLockColor,
                      fontFamily: 'SFPro',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Widget pour les cartes d'action rapide
  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required Size size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: (size.width * 0.28).clamp(100.0, 120.0),
          minWidth: (size.width * 0.25).clamp(90.0, 110.0),
        ),
        padding: EdgeInsets.all((size.width * 0.04).clamp(12.0, 16.0)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: (size.width * 0.06).clamp(20.0, 24.0),
              backgroundColor: color.withOpacity(0.1),
              child: Icon(
                icon,
                color: color,
                size: (size.width * 0.06).clamp(20.0, 24.0),
              ),
            ),
            SizedBox(height: (size.height * 0.01).clamp(4.0, 8.0)),
            Text(
              title,
              style: TextStyle(
                fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                fontWeight: FontWeight.bold,
                color: AppTheme.darLockColor,
                fontFamily: 'SFPro',
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour les cartes de statut
  Widget _buildStatusCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Size size,
  }) {
    return Container(
      padding: EdgeInsets.all((size.width * 0.04).clamp(12.0, 16.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: (size.width * 0.05).clamp(16.0, 20.0),
            backgroundColor: color.withOpacity(0.1),
            child: Icon(
              icon,
              color: color,
              size: (size.width * 0.05).clamp(16.0, 20.0),
            ),
          ),
          SizedBox(width: (size.width * 0.03).clamp(8.0, 12.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darLockColor,
                    fontFamily: 'SFPro',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: (size.width * 0.035).clamp(12.0, 14.0),
                    color: Colors.grey[600],
                    fontFamily: 'SFPro',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour les éléments d'activité récente
  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Size size,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: (size.height * 0.01).clamp(4.0, 8.0)),
        padding: EdgeInsets.all((size.width * 0.04).clamp(12.0, 16.0)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: (size.width * 0.05).clamp(16.0, 20.0),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: (size.width * 0.05).clamp(16.0, 20.0),
              ),
            ),
            SizedBox(width: (size.width * 0.03).clamp(8.0, 12.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darLockColor,
                      fontFamily: 'SFPro',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: (size.width * 0.035).clamp(12.0, 14.0),
                      color: Colors.grey[600],
                      fontFamily: 'SFPro',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: (size.width * 0.04).clamp(12.0, 16.0),
            ),
          ],
        ),
      ),
    );
  }
}