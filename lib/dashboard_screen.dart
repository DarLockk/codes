import 'package:flutter/material.dart';
import 'feature_card.dart';
import 'camera.dart';
import 'notifications.dart';
import 'face_recognition.dart';
import 'unlock_door.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  FeatureCard(
                    icon: Icons.videocam,
                    title: "Live Camera",
                    screen: LiveCameraScreen(),
                  ),
                  FeatureCard(
                    icon: Icons.notifications,
                    title: "Notifications",
                    screen: NotificationsScreen(),
                  ),
                  FeatureCard(
                    icon: Icons.face,
                    title: "Face Recognition",
                    screen: FaceRecognitionScreen(),
                  ),
                  FeatureCard(
                    icon: Icons.lock_open,
                    title: "Unlock Door",
                    screen: UnlockDoorScreen(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}