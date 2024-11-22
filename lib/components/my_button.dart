import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String buttonText;
  final Future<void> Function() onPressedAsync;

  const MyButton({
    super.key,
    required this.buttonText,
    required this.onPressedAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          onPressedAsync();
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
              horizontal: 50, vertical: 10), // Adjust padding if needed
          backgroundColor: const Color(
              0xFF00A67E), // Green background color to match the theme
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // Rounded corners
          ),
        ),
        child: Text(
          buttonText,
          style: const TextStyle(
            color: Colors.white, // White text color
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
