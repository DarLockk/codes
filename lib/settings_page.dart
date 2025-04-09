import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _obscureNewPassword = true; // Pour afficher/masquer le nouveau mot de passe dans la boîte de dialogue

  // Contrôleurs pour la boîte de dialogue de changement de mot de passe
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // Fonction pour changer le mot de passe
  Future<void> _changePassword() async {
    String currentPassword = _currentPasswordController.text.trim();
    String newPassword = _newPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.red);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar("Le nouveau mot de passe doit contenir au moins 6 caractères", Colors.red);
      return;
    }

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar("Utilisateur non connecté", Colors.red);
        return;
      }

      // Re-authentification de l'utilisateur avec son mot de passe actuel
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Mise à jour du mot de passe
      await user.updatePassword(newPassword);
      _showSnackBar("Mot de passe changé avec succès", Colors.green);

      // Réinitialiser les champs après succès
      _currentPasswordController.clear();
      _newPasswordController.clear();
      Navigator.of(context).pop(); // Fermer la boîte de dialogue
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'L\'ancien mot de passe est incorrect.';
          break;
        case 'weak-password':
          errorMessage = 'Le nouveau mot de passe est trop faible. Il doit contenir au moins 6 caractères.';
          break;
        default:
          errorMessage = 'Erreur : ${e.message}';
      }
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      _showSnackBar("Une erreur inattendue s'est produite : $e", Colors.red);
    }
  }

  // Fonction pour afficher une SnackBar
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Boîte de dialogue pour changer le mot de passe
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Changer le mot de passe"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Ancien mot de passe",
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: "Nouveau mot de passe",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                      color: Colors.blue.withOpacity(0.7),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _currentPasswordController.clear();
              _newPasswordController.clear();
              Navigator.of(context).pop();
            },
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: _changePassword,
            child: const Text("Changer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.blue;
    final size = MediaQuery.of(context).size;

    // Fond en dégradé et effet de vague, identique aux autres pages
    final background = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.8),
            primaryColor.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipPath(
        clipper: WaveClipper(),
        child: Container(color: Colors.white.withOpacity(0.1)),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres")),
      body: Stack(
        children: [
          background,
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Section pour le mot de passe
                ListTile(
                  leading: const Icon(Icons.lock, color: Colors.blue),
                  title: const Text("Mot de passe"),
                  subtitle: const Text("********"), // Indication que le mot de passe est défini (non récupérable)
                  trailing: TextButton(
                    onPressed: _showChangePasswordDialog,
                    child: const Text(
                      "Changer",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                const Divider(color: Colors.white70),
                // Option Notifications
                ListTile(
                  leading: const Icon(Icons.notifications, color: Colors.blue),
                  title: const Text("Activer les notifications"),
                  trailing: Switch(
                    value: _notificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                ),
                const Divider(color: Colors.white70),
                // Option Mode sombre
                ListTile(
                  leading: const Icon(Icons.brightness_6, color: Colors.blue),
                  title: const Text("Mode sombre"),
                  trailing: Switch(
                    value: _darkModeEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _darkModeEnabled = value;
                        // Vous pouvez ici implémenter le changement de thème global si nécessaire.
                      });
                    },
                  ),
                ),
                const Divider(color: Colors.white70),
                // Option À propos
                ListTile(
                  leading: const Icon(Icons.info, color: Colors.blue),
                  title: const Text("À propos"),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: "Smart Videophone",
                      applicationVersion: "1.0.0",
                      applicationIcon: const Icon(
                        Icons.videocam,
                        size: 50,
                        color: Colors.blue,
                      ),
                      children: const [
                        Text("Application de vidéophonie intelligente."),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// CustomClipper pour créer un effet de vague en bas de l'écran
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.8);

    final firstControlPoint = Offset(size.width * 0.25, size.height);
    final firstEndPoint = Offset(size.width * 0.5, size.height * 0.8);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    final secondControlPoint = Offset(size.width * 0.75, size.height * 0.6);
    final secondEndPoint = Offset(size.width, size.height * 0.8);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}