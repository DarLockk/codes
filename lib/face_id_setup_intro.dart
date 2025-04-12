import 'dart:io';
import 'package:flutter/material.dart';
import 'face_id_setup_scan.dart';

class FaceIdSetupIntroPage extends StatelessWidget {
  final Function(List<File>) onImagesCaptured;

  const FaceIdSetupIntroPage({required this.onImagesCaptured});

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
            Icon(Icons.face, size: size.width * 0.2, color: Colors.white),
            SizedBox(height: size.height * 0.03),
            Text(
              "Comment configurer Face ID",
              style: TextStyle(
                fontSize: size.width * 0.06,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: size.height * 0.02),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
              child: Text(
                "Commencez par placer votre visage dans le cadre. Puis faites un cercle avec la tête de façon à capturer tous les angles de votre visage.",
                style: TextStyle(
                  fontSize: size.width * 0.045,
                  color: Colors.white70,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Spacer(),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => FaceIdSetupScanPage(
                          onImagesCaptured: onImagesCaptured,
                        ),
                  ),
                );
              },
              child: Container(
                width: size.width * 0.9,
                padding: EdgeInsets.all(size.width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "Démarrer",
                    style: TextStyle(
                      fontSize: size.width * 0.045,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: size.height * 0.03),
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
