import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'face_recognition.dart';

class FaceIdSetupScanPage extends StatefulWidget {
  final Function(List<File>) onImagesCaptured;

  const FaceIdSetupScanPage({required this.onImagesCaptured});

  @override
  _FaceIdSetupScanPageState createState() => _FaceIdSetupScanPageState();
}

class _FaceIdSetupScanPageState extends State<FaceIdSetupScanPage>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(),
  );
  List<File> _capturedImages = [];
  int _currentStep = 0;
  double _progress = 0.0;
  late AnimationController _animationController;
  bool _isFaceDetected = false;
  bool _isCameraInitialized = false;
  String? _errorMessage;

  final List<String> _instructions = [
    "Bougez lentement la tête pour compléter le cercle.",
    "Tournez la tête à gauche.",
    "Tournez la tête à droite.",
    "Regardez vers le haut.",
    "Regardez vers le bas.",
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    )..addListener(() {
      setState(() {
        _progress = _animationController.value;
      });
    });
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage =
              "Aucune caméra disponible. Veuillez vérifier les permissions.";
        });
        print("Erreur : Aucune caméra disponible.");
        return;
      }

      CameraDescription? frontCamera;
      for (var camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          frontCamera = camera;
          break;
        }
      }

      if (frontCamera == null) {
        setState(() {
          _errorMessage = "Aucune caméra frontale disponible.";
        });
        print("Erreur : Aucune caméra frontale disponible.");
        return;
      }

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
      print("Caméra initialisée avec succès.");
      _startFaceDetection();
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur lors de l'initialisation de la caméra : $e";
      });
      print("Erreur lors de l'initialisation de la caméra : $e");
    }
  }

  Future<void> _startFaceDetection() async {
    if (!_isCameraInitialized || _cameraController == null) {
      print("Caméra non initialisée, impossible de démarrer la détection.");
      return;
    }

    _animationController.reset();
    _animationController.forward();

    while (_currentStep < _instructions.length) {
      try {
        final XFile image = await _cameraController!.takePicture();
        File imageFile = File(image.path);
        final inputImage = InputImage.fromFile(imageFile);
        final List<Face> faces = await _faceDetector.processImage(inputImage);

        setState(() {
          _isFaceDetected = faces.isNotEmpty;
        });

        if (_isFaceDetected) {
          print("Visage détecté à l'étape $_currentStep.");
          _capturedImages.add(imageFile);
          setState(() {
            _currentStep++;
            _progress = 0.0;
          });
          _animationController.reset();
          if (_currentStep < _instructions.length) {
            _animationController.forward();
          }
        } else {
          print("Aucun visage détecté à l'étape $_currentStep.");
        }

        await Future.delayed(Duration(milliseconds: 500));
      } catch (e) {
        print("Erreur lors de la détection de visage : $e");
      }
    }

    print("Détection terminée. ${_capturedImages.length} images capturées.");
    widget.onImagesCaptured(_capturedImages);
    Navigator.pop(context);
    Navigator.pop(context); // Revenir à la page principale
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Spacer(),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    fontSize: size.width * 0.045,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else if (!_isCameraInitialized)
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            else
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                      child: CameraPreview(_cameraController!),
                    ),
                  ),
                  CustomPaint(
                    painter: CircleProgressPainter(progress: _progress),
                    child: Container(
                      width: size.width * 0.8,
                      height: size.width * 0.8,
                    ),
                  ),
                ],
              ),
            SizedBox(height: size.height * 0.03),
            Text(
              _currentStep < _instructions.length
                  ? _instructions[_currentStep]
                  : "Terminé !",
              style: TextStyle(
                fontSize: size.width * 0.05,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Annuler",
                style: TextStyle(
                  fontSize: size.width * 0.045,
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: size.height * 0.03),
          ],
        ),
      ),
    );
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;

  CircleProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 10.0;

    // Dessiner le cercle de fond (gris)
    final backgroundPaint =
        Paint()
          ..color = Colors.grey.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, backgroundPaint);

    // Dessiner les segments du cercle
    const segmentCount = 50;
    const segmentAngle = 2 * 3.14159 / segmentCount;
    final segmentPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final segmentsToDraw = (segmentCount * progress).toInt();
    for (int i = 0; i < segmentCount; i++) {
      final startAngle = i * segmentAngle - 3.14159 / 2;
      final sweepAngle = segmentAngle * 0.8;
      if (i < segmentsToDraw) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
          segmentPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
