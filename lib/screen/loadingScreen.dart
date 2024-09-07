import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 150.0, // Desired width
          height: 150.0, // Desired height
          child: Image.asset('assets/image/icon.jpg'),
        ),
      ),
    );
  }
}
