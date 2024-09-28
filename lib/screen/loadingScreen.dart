import 'package:flutter/material.dart';
import '../setting/color.dart' as GlobalColor;

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a Container to apply the gradient background
      body: Container(
        width: double.infinity, // Occupy the full width
        height: double.infinity, // Occupy the full height
        decoration: BoxDecoration(
          // Implement a vertical linear gradient: white -> orange -> white
          gradient: LinearGradient(
            begin: Alignment.topCenter, // Start from the top
            end: Alignment.bottomCenter, // End at the bottom
            colors: [
              GlobalColor.backGroundCol, // Top color
              GlobalColor.loadingCol, // Middle color (Orange)
              GlobalColor.loadingCol, // Middle color (Orange)
              GlobalColor.backGroundCol, // Bottom color
            ],
            stops: [0.0, 0.3 , 0.7, 1.0], // Position of each color
          ),
        ),
        child: Center(
          // Center the Column both vertically and horizontally
          child: Column(
            mainAxisSize: MainAxisSize.min, // Minimize vertical space usage
            children: [
              // Display the centered icon
              Container(
                width: 300.0, // Desired width
                height: 300.0, // Desired height
                child: Image.asset(
                  'assets/image/icon_transparent.jpg',
                  fit: BoxFit.cover, // Ensure the image covers the container
                  errorBuilder: (BuildContext context, Object exception,
                      StackTrace? stackTrace) {
                    return Icon(
                      Icons.error,
                      color: Colors.red,
                      size: 100.0, // Adjust size as needed
                    );
                  },
                ),
              ),

              SizedBox(height: 20.0), // Space between the icon and the loader

              // Loading Indicator
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(GlobalColor.MainCol),
                strokeWidth: 4.0, // Thickness of the circle
              ),
            ],
          ),
        ),
      ),
    );
  }
}
