import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true; // État pour afficher/masquer le mot de passe

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Expression régulière simple pour vérifier si la saisie est un email
  bool _isEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
  }

  // Sauvegarder l'état de "Se souvenir de moi" et l'identifiant
  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rememberMe', _rememberMe);
    if (_rememberMe) {
      await prefs.setString('identifier', _identifierController.text.trim());
    } else {
      await prefs.remove('identifier');
    }
  }

  // Charger les préférences au démarrage
  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _rememberMe = prefs.getBool('rememberMe') ?? false;
      if (_rememberMe) {
        String? identifier = prefs.getString('identifier');
        if (identifier != null) {
          _identifierController.text = identifier;
        }
      }
    });
  }

  void _signIn() async {
    String identifier = _identifierController.text.trim();
    String password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showSnackBar(
        "Veuillez entrer votre email ou nom d'utilisateur et votre mot de passe.",
        Colors.red,
      );
      return;
    }

    try {
      String email;

      // Vérifier si l'identifiant est un email ou un nom d'utilisateur
      if (_isEmail(identifier)) {
        email = identifier;
      } else {
        QuerySnapshot query =
            await _firestore
                .collection('users')
                .where('username', isEqualTo: identifier)
                .get();

        if (query.docs.isEmpty) {
          _showSnackBar("Nom d'utilisateur incorrect.", Colors.red);
          return;
        }

        email = query.docs.first['email'];
      }

      // Se connecter avec l'email et le mot de passe
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Vérifier si l'email est vérifié
        if (!user.emailVerified) {
          await _auth.signOut();
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Email non vérifié'),
                  content: const Text(
                    'Veuillez vérifier votre email avant de vous connecter. Vérifiez votre boîte de réception ou vos spams.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await user.sendEmailVerification();
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Email envoyé'),
                                content: const Text(
                                  'Un nouvel email de vérification a été envoyé.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text('Renvoyer l\'email'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
          return;
        }

        // Sauvegarder les préférences après une connexion réussie
        await _savePreferences();
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Aucun utilisateur trouvé avec cet email.';
          break;
        case 'wrong-password':
          errorMessage = 'Mot de passe incorrect.';
          break;
        case 'invalid-email':
          errorMessage = 'L\'adresse email est invalide.';
          break;
        default:
          errorMessage =
              'Une erreur s\'est produite lors de la connexion : ${e.message}';
      }
      _showSnackBar(errorMessage, Colors.red);
    } catch (e) {
      _showSnackBar("Une erreur inattendue s'est produite : $e", Colors.red);
    }
  }

  // Fonction pour gérer la réinitialisation du mot de passe
  void _resetPassword() async {
    String identifier = _identifierController.text.trim();

    if (identifier.isEmpty) {
      _showSnackBar(
        "Veuillez entrer votre email ou nom d'utilisateur pour réinitialiser le mot de passe.",
        Colors.red,
      );
      return;
    }

    try {
      String email;

      // Vérifier si l'identifiant est un email ou un nom d'utilisateur
      if (_isEmail(identifier)) {
        email = identifier;
      } else {
        QuerySnapshot query =
            await _firestore
                .collection('users')
                .where('username', isEqualTo: identifier)
                .get();

        if (query.docs.isEmpty) {
          _showSnackBar("Nom d'utilisateur incorrect.", Colors.red);
          return;
        }

        email = query.docs.first['email'];
      }

      await _auth.sendPasswordResetEmail(email: email);
      _showSnackBar(
        "Un email de réinitialisation a été envoyé à $email. Vérifiez votre boîte de réception ou vos spams.",
        Colors.green,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = "L'adresse email est invalide.";
          break;
        case 'user-not-found':
          errorMessage = "Aucun utilisateur trouvé avec cet email.";
          break;
        default:
          errorMessage = "Une erreur s'est produite : ${e.message}";
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
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF007AFF);
    final secondaryColor = const Color(0xFF4A6CF7);

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double padding = constraints.maxWidth > 600 ? 48.0 : 24.0;
          final double buttonWidth =
              constraints.maxWidth > 600
                  ? constraints.maxWidth * 0.4
                  : constraints.maxWidth * 0.9;
          final double fontSizeTitle = constraints.maxWidth > 600 ? 48 : 36;
          final double fontSizeSubtitle = constraints.maxWidth > 600 ? 24 : 18;
          final double fontSizeSmall = constraints.maxWidth > 600 ? 16 : 14;

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
                  top: -constraints.maxHeight * 0.1,
                  left: -constraints.maxWidth * 0.2,
                  child: Container(
                    width: constraints.maxWidth * 0.6,
                    height: constraints.maxHeight * 0.3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -constraints.maxHeight * 0.1,
                  right: -constraints.maxWidth * 0.1,
                  child: Container(
                    width: constraints.maxWidth * 0.5,
                    height: constraints.maxHeight * 0.2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secondaryColor.withOpacity(0.05),
                    ),
                  ),
                ),
              ],
            ),
          );

          return Stack(
            children: [
              background,
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: padding),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DarLock',
                          style: TextStyle(
                            fontSize: fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontFamily: 'SFPro',
                            shadows: [
                              Shadow(
                                color: primaryColor.withOpacity(0.5),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Connexion sécurisée',
                          style: TextStyle(
                            fontSize: fontSizeSubtitle,
                            color: Colors.black.withOpacity(0.6),
                            fontFamily: 'SFPro',
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildTextField(
                          _identifierController,
                          'Email ou Nom d\'utilisateur',
                          Icons.account_circle,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _passwordController,
                          'Mot de passe',
                          Icons.lock,
                          obscure: _obscurePassword,
                          toggleObscure: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                                  activeColor: primaryColor,
                                ),
                                Flexible(
                                  child: Text(
                                    'Se souvenir de moi',
                                    style: TextStyle(
                                      fontFamily: 'SFPro',
                                      fontSize: fontSizeSmall,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed:
                                  _resetPassword, // Appel de la fonction de réinitialisation
                              child: Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                  fontSize: fontSizeSmall,
                                  color: primaryColor,
                                  fontFamily: 'SFPro',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: _signIn,
                          child: Container(
                            width: buttonWidth,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [primaryColor, secondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontFamily: 'SFPro',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Pas de compte ? ',
                              style: TextStyle(
                                fontFamily: 'SFPro',
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SignUpPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Inscrivez-vous',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: primaryColor,
                                  fontFamily: 'SFPro',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    Function()? toggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontFamily: 'SFPro'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: const Color(0xFF007AFF)),
          suffixIcon:
              toggleObscure != null
                  ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF007AFF).withOpacity(0.7),
                    ),
                    onPressed: toggleObscure,
                  )
                  : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
