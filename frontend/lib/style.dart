import 'package:flutter/material.dart';

Widget showLoadingAction() {
  return Positioned.fill(
    child: InkWell(
      onTap: () {}, // Prevent interaction while loading
      child: Container(
        color: Colors.black.withAlpha(200), // Darker overlay
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.deepPurple,
              strokeWidth: 10,
              backgroundColor: Colors.black87, // Darker background for the loading circle
            ),
            SizedBox(height: 20), // Spacing between loader and text
            Text(
              'Processing . . .',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white, // Text color for better visibility
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
