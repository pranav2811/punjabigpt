import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;
  final IconData prefixIconData;
  final Color prefixIconColor;
  final double textFieldHeight;
  final double textFieldWidth;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.prefixIconData,
    required this.prefixIconColor,
    required this.textFieldHeight,
    required this.textFieldWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 35.0),
      child: SizedBox(
        height: textFieldHeight,
        width: textFieldWidth,
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: Colors.white), // Text color inside the field
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF444654)), // Border color for enabled state
              borderRadius: BorderRadius.circular(10.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF00A67E), // Green border color when focused
              ),
            ),
            fillColor: Color(0xFF343541), // Dark fill color for the text field
            filled: true,
            prefixIcon: Icon(
              prefixIconData,
              color: prefixIconColor,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white70, // Slightly faded white for the hint text
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
