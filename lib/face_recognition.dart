import 'dart:io';
import 'dart:convert'; // Ajout de l'import pour jsonDecode
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'theme.dart';

class FaceRecognitionScreen extends StatefulWidget {
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  File? _image;
  bool _isFaceDetected = false;
  final ImagePicker _picker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(),
  );
  String _personName = "";
  List<Map<String, dynamic>> _knownFaces = [];

  @override
  void initState() {
    super.initState();
    _fetchKnownFaces();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
      _detectFace(_image!);
    }
  }

  Future<void> _detectFace(File image) async {
    final inputImage = InputImage.fromFile(image);
    final List<Face> faces = await _faceDetector.processImage(inputImage);
    setState(() => _isFaceDetected = faces.isNotEmpty);
    if (_isFaceDetected) {
      print("✅ ${faces.length} visage(s) détecté(s)");
    } else {
      print("❌ Aucun visage détecté");
    }
  }

  Future<void> _sendImageToServer(File image) async {
    try {
      var url = Uri.parse("http://192.168.1.17:3000/upload");
      var request =
          http.MultipartRequest('POST', url)
            ..files.add(await http.MultipartFile.fromPath('file', image.path))
            ..fields['name'] = _personName;

      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Image envoyée avec succès !")));
        _fetchKnownFaces(); // Mettre à jour la liste après envoi
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Échec de l'envoi")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  Future<void> _fetchKnownFaces() async {
    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.17:3000/known_faces"),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _knownFaces =
              data
                  .map(
                    (face) => {
                      'name': face['name'],
                      'imageUrl': face['imageUrl'],
                    },
                  )
                  .toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la récupération des visages connus"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

void _showKnownFaces() {
  final size = MediaQuery.of(context).size;
  List<Map<String, dynamic>> dialogKnownFaces = List.from(_knownFaces); // Copie initiale de la liste
  bool isDialogOpen = true;

  // Polling pour actualiser la liste toutes les 5 secondes
  void startPolling() {
    Future.doWhile(() async {
      if (!isDialogOpen) return false; // Arrêter si la boîte de dialogue est fermée
      await Future.delayed(Duration(seconds: 5));
      if (!isDialogOpen) return false;
      try {
        final response = await http.get(Uri.parse("http://192.168.1.17:3000/known_faces"));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          final newKnownFaces = data.map((face) => {
            'name': face['name'],
            'imageUrl': face['imageUrl'],
          }).toList();

          if (isDialogOpen) {
            setState(() {
              _knownFaces = newKnownFaces;
              // Mettre à jour dialogKnownFaces en synchronisant avec _knownFaces
              // On garde les éléments de dialogKnownFaces qui existent encore dans _knownFaces
              dialogKnownFaces = dialogKnownFaces
                  .where((face) => _knownFaces.any((f) => f['name'] == face['name']))
                  .toList();
              // Ajouter les nouveaux éléments de _knownFaces qui ne sont pas dans dialogKnownFaces
              for (var face in _knownFaces) {
                if (!dialogKnownFaces.any((f) => f['name'] == face['name'])) {
                  dialogKnownFaces.add(face);
                }
              }
            });
          }
        }
      } catch (e) {
        print("Erreur lors du polling : $e");
      }
      return isDialogOpen;
    });
  }

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        startPolling(); // Lancer le polling
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: size.height * 0.6,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, const Color(0xFFE6F0FF)],
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -size.height * 0.05,
                        left: -size.width * 0.1,
                        child: Container(
                          width: size.width * 0.3,
                          height: size.height * 0.15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor.withOpacity(0.1),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -size.height * 0.05,
                        right: -size.width * 0.05,
                        child: Container(
                          width: size.width * 0.25,
                          height: size.height * 0.1,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.secondaryColor.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Visages Connus",
                            style: TextStyle(
                              fontSize: (size.width * 0.06).clamp(18.0, 24.0),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darLockColor,
                              fontFamily: 'SFPro',
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              isDialogOpen = false; // Arrêter le polling
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.close,
                                color: AppTheme.darLockColor,
                                size: (size.width * 0.06).clamp(18.0, 24.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: dialogKnownFaces.length,
                          itemBuilder: (context, index) {
                            final face = dialogKnownFaces[index];
                            bool isDeleting = false; // État pour l'indicateur de chargement
                            return StatefulBuilder(
                              builder: (context, setItemState) {
                                return Card(
                                  elevation: 4.0,
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  color: Colors.white,
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(12.0),
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.network(
                                        face['imageUrl'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          Icons.error,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      face['name'],
                                      style: TextStyle(
                                        fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.darLockColor,
                                        fontFamily: 'SFPro',
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: (size.width * 0.04).clamp(12.0, 16.0),
                                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: AppTheme.primaryColor,
                                            size: (size.width * 0.04).clamp(12.0, 16.0),
                                          ),
                                        ),
                                        SizedBox(width: 8.0),
                                        isDeleting
                                            ? CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                                strokeWidth: 2.0,
                                              )
                                            : GestureDetector(
                                                onTap: () async {
                                                  setItemState(() {
                                                    isDeleting = true;
                                                  });
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      title: Text("Confirmer la suppression"),
                                                      content: Text("Voulez-vous vraiment supprimer ${face['name']} ?"),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: Text("Annuler"),
                                                        ),
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, true),
                                                          child: Text("Supprimer"),
                                                        ),
                                                      ],
                                                    ),
                                                  );

                                                  if (confirm == true) {
                                                    try {
                                                      final response = await http.delete(
                                                        Uri.parse("http://192.168.1.17:3000/delete?name=${face['name']}"),
                                                      );
                                                      if (response.statusCode == 200) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text("Visage supprimé avec succès !")),
                                                        );
                                                        setDialogState(() {
                                                          dialogKnownFaces.removeWhere((f) => f['name'] == face['name']);
                                                        });
                                                        _fetchKnownFaces();
                                                      } else {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          SnackBar(content: Text("Échec de la suppression")),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text("Erreur : $e")),
                                                      );
                                                    } finally {
                                                      setItemState(() {
                                                        isDeleting = false;
                                                      });
                                                    }
                                                  } else {
                                                    setItemState(() {
                                                      isDeleting = false;
                                                    });
                                                  }
                                                },
                                                child: CircleAvatar(
                                                  radius: (size.width * 0.04).clamp(12.0, 16.0),
                                                  backgroundColor: Colors.red.withOpacity(0.1),
                                                  child: Icon(
                                                    Icons.delete,
                                                    color: Colors.red,
                                                    size: (size.width * 0.04).clamp(12.0, 16.0),
                                                  ),
                                                ),
                                              ),
                                      ],
                                    ),
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Visage sélectionné : ${face['name']}")),
                                      );
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Align(
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () {
                            isDialogOpen = false; // Arrêter le polling
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                "Fermer",
                                style: TextStyle(
                                  fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'SFPro',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  ).whenComplete(() {
    isDialogOpen = false; // S'assurer que le polling s'arrête
  });
}

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = (size.width * 0.05).clamp(16.0, 24.0);

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: padding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: AppTheme.darLockColor,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          "Ajouter un Visage",
                          style: TextStyle(
                            fontSize: (size.width * 0.06).clamp(18.0, 24.0),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darLockColor,
                            fontFamily: 'SFPro',
                          ),
                        ),
                        SizedBox(width: 48),
                      ],
                    ),
                    SizedBox(height: size.height * 0.03),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(padding),
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
                      child:
                          _image != null
                              ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _image!,
                                  height: 250,
                                  fit: BoxFit.cover,
                                ),
                              )
                              : Column(
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 60,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    "Aucune image sélectionnée",
                                    style: TextStyle(
                                      fontSize: (size.width * 0.04).clamp(
                                        14.0,
                                        16.0,
                                      ),
                                      color: Colors.grey[600],
                                      fontFamily: 'SFPro',
                                    ),
                                  ),
                                ],
                              ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    if (_image != null)
                      Container(
                        padding: EdgeInsets.all(padding),
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
                              backgroundColor: (_isFaceDetected
                                      ? Colors.green
                                      : Colors.red)
                                  .withOpacity(0.1),
                              child: Icon(
                                _isFaceDetected
                                    ? Icons.check_circle
                                    : Icons.error,
                                color:
                                    _isFaceDetected ? Colors.green : Colors.red,
                                size: (size.width * 0.05).clamp(16.0, 20.0),
                              ),
                            ),
                            SizedBox(
                              width: (size.width * 0.03).clamp(8.0, 12.0),
                            ),
                            Expanded(
                              child: Text(
                                _isFaceDetected
                                    ? "Visage détecté"
                                    : "Aucun visage détecté",
                                style: TextStyle(
                                  fontSize: (size.width * 0.04).clamp(
                                    14.0,
                                    16.0,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darLockColor,
                                  fontFamily: 'SFPro',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: size.height * 0.02),
                    Container(
                      padding: EdgeInsets.all(padding),
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
                      child: TextField(
                        onChanged:
                            (value) => setState(() => _personName = value),
                        decoration: InputDecoration(
                          labelText: "Nom de la personne",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        style: TextStyle(
                          fontFamily: 'SFPro',
                          color: AppTheme.darLockColor,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          icon: Icons.camera_alt,
                          title: "Caméra",
                          color: Colors.green,
                          onTap: () => _pickImage(ImageSource.camera),
                          size: size,
                        ),
                        _buildActionButton(
                          icon: Icons.photo_library,
                          title: "Galerie",
                          color: Colors.orange,
                          onTap: () => _pickImage(ImageSource.gallery),
                          size: size,
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.03),
                    GestureDetector(
                      onTap:
                          _isFaceDetected && _personName.isNotEmpty
                              ? () => _sendImageToServer(_image!)
                              : null,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(padding),
                        decoration: BoxDecoration(
                          color:
                              _isFaceDetected && _personName.isNotEmpty
                                  ? AppTheme.primaryColor
                                  : Colors.grey[400],
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Enregistrer",
                            style: TextStyle(
                              fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'SFPro',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    GestureDetector(
                      onTap: _showKnownFaces,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(padding),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "Voir Visages Connus",
                            style: TextStyle(
                              fontSize: (size.width * 0.04).clamp(14.0, 16.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'SFPro',
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
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
          maxWidth: (size.width * 0.35).clamp(120.0, 140.0),
          minWidth: (size.width * 0.30).clamp(100.0, 120.0),
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
            ),
          ],
        ),
      ),
    );
  }
}
