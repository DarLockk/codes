import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _isUsernameUnique(String username) async {
    QuerySnapshot query =
        await _firestore
            .collection('users')
            .where('username', isEqualTo: username)
            .get();
    return query.docs.isEmpty;
  }

  Future<void> _signUpWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier que le nom d'utilisateur et le mot de passe sont saisis
      String username = _usernameController.text.trim();
      String password = _passwordController.text.trim();

      if (username.isEmpty || password.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Erreur'),
                content: const Text(
                  'Veuillez entrer un nom d\'utilisateur et un mot de passe.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }

      if (password.length < 6) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Erreur'),
                content: const Text(
                  'Le mot de passe doit contenir au moins 6 caractères.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }

      GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Vérifier si l'email est déjà utilisé
      List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(
        googleUser.email,
      );
      if (signInMethods.isNotEmpty) {
        await _googleSignIn.signOut();
        await _auth.signOut();
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Compte existant'),
                content: const Text(
                  'Cet email est déjà associé à un compte. Veuillez vous connecter depuis la page de connexion.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
        return;
      }

      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      AuthCredential googleCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(
        googleCredential,
      );
      User? user = userCredential.user;

      if (user != null) {
        if (userCredential.additionalUserInfo?.isNewUser == false) {
          await _googleSignIn.signOut();
          await _auth.signOut();
          setState(() {
            _isLoading = false;
          });
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Compte existant'),
                  content: const Text(
                    'Cet email est déjà associé à un compte. Veuillez vous connecter depuis la page de connexion.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pop(context);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
          return;
        }

        // Lier les identifiants email/mot de passe au compte Google
        AuthCredential emailCredential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.linkWithCredential(emailCredential);

        // Utiliser une transaction pour garantir l'unicité du nom d'utilisateur
        bool isUnique = false;
        await _firestore.runTransaction((transaction) async {
          QuerySnapshot query =
              await _firestore
                  .collection('users')
                  .where('username', isEqualTo: username)
                  .get();
          if (query.docs.isEmpty) {
            isUnique = true;
            DocumentReference userDocRef = _firestore
                .collection('users')
                .doc(user.uid);
            transaction.set(userDocRef, {
              'username': username,
              'email': user.email,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        });

        if (!isUnique) {
          await _googleSignIn.signOut();
          await _auth.signOut();
          setState(() {
            _isLoading = false;
          });
          showDialog(
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
          return;
        }

        // Envoyer un email de vérification
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          await _googleSignIn.signOut();
          await _auth.signOut();
          setState(() {
            _isLoading = false;
          });
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Vérification requise'),
                  content: const Text(
                    'Un email de vérification a été envoyé à votre adresse. Veuillez vérifier votre email avant de vous connecter.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pop(
                          context,
                        ); // Rediriger vers la page de connexion
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
          return;
        }

        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'Cet email est déjà associé à un autre type de compte. Veuillez vous connecter depuis la page de connexion.';
          break;
        case 'email-already-in-use':
          errorMessage =
              'Cet email est déjà utilisé. Veuillez vous connecter depuis la page de connexion.';
          break;
        case 'credential-already-in-use':
          errorMessage =
              'Ces identifiants sont déjà associés à un autre compte.';
          break;
        default:
          errorMessage =
              'Erreur lors de l\'inscription avec Google : ${e.message}';
      }
      await _googleSignIn.signOut();
      await _auth.signOut();
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      await _googleSignIn.signOut();
      await _auth.signOut();
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: Text('Une erreur inattendue s\'est produite : $e'),
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

  void _signUp() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text;
    String username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: const Text('Veuillez remplir tous les champs.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    if (password.length < 6) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: const Text(
                'Le mot de passe doit contenir au moins 6 caractères.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    List<String> signInMethods = await _auth.fetchSignInMethodsForEmail(email);
    if (signInMethods.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: const Text(
                'Cet email est déjà utilisé. Veuillez vous connecter ou utiliser un autre email.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;
      if (user != null) {
        bool isUnique = false;
        await _firestore.runTransaction((transaction) async {
          QuerySnapshot query =
              await _firestore
                  .collection('users')
                  .where('username', isEqualTo: username)
                  .get();
          if (query.docs.isEmpty) {
            isUnique = true;
            DocumentReference userDocRef = _firestore
                .collection('users')
                .doc(user.uid);
            transaction.set(userDocRef, {
              'username': username,
              'email': user.email,
              'createdAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        });

        if (!isUnique) {
          await user.delete();
          setState(() {
            _isLoading = false;
          });
          showDialog(
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
          return;
        }

        // Envoyer un email de vérification
        if (!user.emailVerified) {
          await user.sendEmailVerification();
          await _auth.signOut();
          setState(() {
            _isLoading = false;
          });
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Vérification requise'),
                  content: const Text(
                    'Un email de vérification a été envoyé à votre adresse. Veuillez vérifier votre email avant de vous connecter.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.pop(
                          context,
                        ); // Rediriger vers la page de connexion
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
          return;
        }

        setState(() {
          _isLoading = false;
        });
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'Cet email est déjà utilisé par un autre compte.';
          break;
        case 'invalid-email':
          errorMessage = 'L\'adresse email n\'est pas valide.';
          break;
        case 'weak-password':
          errorMessage =
              'Le mot de passe est trop faible. Il doit contenir au moins 6 caractères.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'L\'inscription par email/mot de passe est désactivée. Contactez l\'administrateur.';
          break;
        default:
          errorMessage =
              'Une erreur s\'est produite lors de l\'inscription : ${e.message}';
      }
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: Text(errorMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Erreur'),
              content: Text('Une erreur inattendue s\'est produite : $e'),
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
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: primaryColor,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Expanded(
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
                                'Créez votre compte',
                                style: TextStyle(
                                  fontSize: fontSizeSubtitle,
                                  color: Colors.black.withOpacity(0.6),
                                  fontFamily: 'SFPro',
                                ),
                              ),
                              const SizedBox(height: 40),
                              _buildTextField(
                                _usernameController,
                                'Nom d\'utilisateur',
                                Icons.person,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                _emailController,
                                'Email',
                                Icons.email,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                _passwordController,
                                'Mot de passe',
                                Icons.lock,
                                obscure: true,
                              ),
                              const SizedBox(height: 32),
                              GestureDetector(
                                onTap: _isLoading ? null : _signUp,
                                child: Container(
                                  width: buttonWidth,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
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
                                  child: Center(
                                    child:
                                        _isLoading
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : const Text(
                                              'S\'inscrire',
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
                              Text(
                                '- OU -',
                                style: TextStyle(
                                  fontSize: fontSizeSmall,
                                  color: Colors.black.withOpacity(0.6),
                                  fontFamily: 'SFPro',
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _isLoading ? null : _signUpWithGoogle,
                                child: Container(
                                  width: buttonWidth,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child:
                                        _isLoading
                                            ? const CircularProgressIndicator()
                                            : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.network(
                                                  'https://www.google.com/images/branding/googlelogo/2x/googlelogo_color_92x30dp.png',
                                                  height: 24,
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'S\'inscrire avec Google',
                                                  style: TextStyle(
                                                    fontSize: fontSizeSmall,
                                                    color: Colors.black
                                                        .withOpacity(0.8),
                                                    fontFamily: 'SFPro',
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
