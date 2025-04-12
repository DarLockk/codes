import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'theme.dart';
import 'face_id_setup_intro.dart';

List<CameraDescription> cameras = [];

class FaceRecognitionScreen extends StatefulWidget {
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  List<File> _images = [];
  File? _galleryImage;
  bool _isFaceDetected = false;
  String _personName = "";
  List<Map<String, dynamic>> _knownFaces = [];

  @override
  void initState() {
    super.initState();
    _initializeCameras(); // Initialisation des caméras
    _fetchKnownFaces();
  }

  Future<void> _initializeCameras() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        print("Erreur : Aucune caméra disponible.");
      } else {
        print("Caméras initialisées : ${cameras.length} caméras détectées.");
      }
    } catch (e) {
      print("Erreur lors de l'initialisation des caméras : $e");
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
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur : $e")));
    }
  }

  void _showKnownFaces() {
    final size = MediaQuery.of(context).size;
    List<Map<String, dynamic>> dialogKnownFaces = List.from(_knownFaces);
    bool isDialogOpen = true;

    void startPolling() {
      Future.doWhile(() async {
        if (!isDialogOpen) return false;
        await Future.delayed(Duration(seconds: 5));
        if (!isDialogOpen) return false;
        try {
          final response = await http.get(
            Uri.parse("http://192.168.1.17:3000/known_faces"),
          );
          if (response.statusCode == 200) {
            final List<dynamic> data = jsonDecode(response.body);
            final newKnownFaces =
                data
                    .map(
                      (face) => {
                        'name': face['name'],
                        'imageUrl': face['imageUrl'],
                      },
                    )
                    .toList();

            if (isDialogOpen) {
              setState(() {
                _knownFaces = newKnownFaces;
                dialogKnownFaces =
                    dialogKnownFaces
                        .where(
                          (face) =>
                              _knownFaces.any((f) => f['name'] == face['name']),
                        )
                        .toList();
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
      builder:
          (context) => StatefulBuilder(
            builder: (context, setDialogState) {
              startPolling();
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                elevation: 8.0,
                backgroundColor: Colors.transparent,
                child: Container(
                  width: size.width * 0.9,
                  constraints: BoxConstraints(maxHeight: size.height * 0.6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, const Color(0xFFE6F0FF)],
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(size.width * 0.04),
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
                                fontSize: size.width * 0.06,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darLockColor,
                                fontFamily: 'SFPro',
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: AppTheme.darLockColor,
                              ),
                              onPressed: () {
                                isDialogOpen = false;
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: size.height * 0.02),
                        Expanded(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: dialogKnownFaces.length,
                            itemBuilder: (context, index) {
                              final face = dialogKnownFaces[index];
                              bool isDeleting = false;
                              return Card(
                                elevation: 4.0,
                                margin: EdgeInsets.symmetric(
                                  vertical: size.height * 0.01,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.all(
                                    size.width * 0.03,
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      face['imageUrl'],
                                      width: size.width * 0.15,
                                      height: size.width * 0.15,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.error,
                                            color: Colors.red,
                                          ),
                                    ),
                                  ),
                                  title: Text(
                                    face['name'],
                                    style: TextStyle(
                                      fontSize: size.width * 0.045,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.darLockColor,
                                      fontFamily: 'SFPro',
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppTheme.primaryColor,
                                        size: size.width * 0.05,
                                      ),
                                      SizedBox(width: size.width * 0.02),
                                      isDeleting
                                          ? CircularProgressIndicator()
                                          : IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () async {
                                              setDialogState(
                                                () => isDeleting = true,
                                              );
                                              final confirm = await showDialog<
                                                bool
                                              >(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: Text(
                                                        "Confirmer la suppression",
                                                      ),
                                                      content: Text(
                                                        "Voulez-vous vraiment supprimer ${face['name']} ?",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                          child: Text(
                                                            "Annuler",
                                                          ),
                                                        ),
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                          child: Text(
                                                            "Supprimer",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );

                                              if (confirm == true) {
                                                try {
                                                  final response = await http
                                                      .delete(
                                                        Uri.parse(
                                                          "http://192.168.1.17:3000/delete?name=${face['name']}",
                                                        ),
                                                      );
                                                  if (response.statusCode ==
                                                      200) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Visage supprimé avec succès !",
                                                        ),
                                                      ),
                                                    );
                                                    setDialogState(() {
                                                      dialogKnownFaces
                                                          .removeWhere(
                                                            (f) =>
                                                                f['name'] ==
                                                                face['name'],
                                                          );
                                                    });
                                                    _fetchKnownFaces();
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "Erreur : $e",
                                                      ),
                                                    ),
                                                  );
                                                } finally {
                                                  setDialogState(
                                                    () => isDeleting = false,
                                                  );
                                                }
                                              } else {
                                                setDialogState(
                                                  () => isDeleting = false,
                                                );
                                              }
                                            },
                                          ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: size.height * 0.02),
                        GestureDetector(
                          onTap: () {
                            isDialogOpen = false;
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(size.width * 0.04),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor,
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: Center(
                              child: Text(
                                "Fermer",
                                style: TextStyle(
                                  fontSize: size.width * 0.045,
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
              );
            },
          ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File galleryFile = File(image.path);
      final inputImage = InputImage.fromFile(galleryFile);
      final List<Face> faces = await FaceDetector(
        options: FaceDetectorOptions(),
      ).processImage(inputImage);
      if (faces.isNotEmpty) {
        setState(() {
          _galleryImage = galleryFile;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Aucun visage détecté dans l'image sélectionnée."),
          ),
        );
      }
    }
  }

  Future<void> _sendImagesToServer() async {
    if (_images.isEmpty || _personName.isEmpty) return;
    if (_images.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Veuillez ajouter au moins 3 images.")),
      );
      return;
    }

    try {
      var url = Uri.parse("http://192.168.1.17:3000/upload");
      var request = http.MultipartRequest('POST', url);

      for (var image in _images) {
        request.files.add(
          await http.MultipartFile.fromPath('file', image.path),
        );
      }
      if (_galleryImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('file', _galleryImage!.path),
        );
        request.fields['displayImage'] = _galleryImage!.path;
      } else {
        request.fields['displayImage'] = _images[0].path;
      }
      request.fields['name'] = _personName;

      var response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Images envoyées avec succès !")),
        );
        setState(() {
          _images.clear();
          _galleryImage = null;
          _personName = "";
        });
        _fetchKnownFaces();
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

  void _openFaceIdSetup() {
    if (cameras.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Aucune caméra disponible. Veuillez vérifier les permissions.",
          ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => FaceIdSetupIntroPage(
              onImagesCaptured: (List<File> capturedImages) {
                setState(() {
                  _images = capturedImages;
                });
              },
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.02),
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
                            fontSize: size.width * 0.06,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darLockColor,
                            fontFamily: 'SFPro',
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.camera_alt,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: _openFaceIdSetup,
                        ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.02),
                    Container(
                      width: size.width * 0.9,
                      height: size.height * 0.3,
                      padding: EdgeInsets.all(size.width * 0.04),
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
                          _images.isEmpty
                              ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: size.width * 0.15,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(height: size.height * 0.01),
                                  Text(
                                    "Aucune image sélectionnée",
                                    style: TextStyle(
                                      fontSize: size.width * 0.045,
                                      color: Colors.grey[600],
                                      fontFamily: 'SFPro',
                                    ),
                                  ),
                                ],
                              )
                              : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: size.width * 0.02,
                                    ),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: Image.file(
                                            _images[index],
                                            width: size.width * 0.35,
                                            height: size.height * 0.25,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: size.width * 0.02,
                                          right: size.width * 0.02,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _images.removeAt(index);
                                              });
                                            },
                                            child: CircleAvatar(
                                              radius: size.width * 0.03,
                                              backgroundColor: Colors.red
                                                  .withOpacity(0.8),
                                              child: Icon(
                                                Icons.close,
                                                size: size.width * 0.04,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ),
                    SizedBox(height: size.height * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickImageFromGallery,
                            child: Container(
                              padding: EdgeInsets.all(size.width * 0.04),
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.photo,
                                    color: AppTheme.primaryColor,
                                  ),
                                  SizedBox(width: size.width * 0.02),
                                  Flexible(
                                    child: Text(
                                      "Ajouter depuis la galerie",
                                      style: TextStyle(
                                        fontSize: size.width * 0.04,
                                        color: AppTheme.darLockColor,
                                        fontFamily: 'SFPro',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_galleryImage != null)
                          SizedBox(width: size.width * 0.02),
                        if (_galleryImage != null)
                          Expanded(
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _galleryImage!,
                                    width: size.width * 0.25,
                                    height: size.width * 0.25,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: size.width * 0.02,
                                  right: size.width * 0.02,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _galleryImage = null;
                                      });
                                    },
                                    child: CircleAvatar(
                                      radius: size.width * 0.03,
                                      backgroundColor: Colors.red.withOpacity(
                                        0.8,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        size: size.width * 0.04,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: size.height * 0.02),
                    Container(
                      width: size.width * 0.9,
                      padding: EdgeInsets.all(size.width * 0.04),
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
                          fontSize: size.width * 0.045,
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.03),
                    GestureDetector(
                      onTap:
                          (_images.isNotEmpty &&
                                  _personName.isNotEmpty &&
                                  _images.length >= 3)
                              ? () => _sendImagesToServer()
                              : null,
                      child: Container(
                        width: size.width * 0.9,
                        padding: EdgeInsets.all(size.width * 0.04),
                        decoration: BoxDecoration(
                          color:
                              (_images.isNotEmpty &&
                                      _personName.isNotEmpty &&
                                      _images.length >= 3)
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
                              fontSize: size.width * 0.045,
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
                        width: size.width * 0.9,
                        padding: EdgeInsets.all(size.width * 0.04),
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
                              fontSize: size.width * 0.045,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'SFPro',
                            ),
                          ),
                        ),
                      ),
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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(home: FaceRecognitionScreen()));
}
