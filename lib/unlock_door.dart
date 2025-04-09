import 'package:flutter/material.dart';

class UnlockDoorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Unlock Door")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text("Door Unlocked!")));
          },
          child: Text("Unlock Now"),
        ),
      ),
    );
  }
}