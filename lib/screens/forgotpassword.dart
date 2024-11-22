import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:punjabigpt/components/my_textfield.dart';
import 'package:punjabigpt/components/my_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();

  void _sendPasswordResetEmail() async {
    if (emailController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter your email",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text,
      );
      Fluttertoast.showToast(
        msg: "Password reset link sent! Check your email.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      Navigator.pop(
          context); // Go back to the previous screen after sending the email
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else {
        errorMessage = 'Failed to send password reset link. Please try again.';
      }

      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF202123), // Dark background color
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: const Color(0xFF343541),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 37),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Center the content vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center the content horizontally
              children: [
                const Padding(
                  padding:
                      EdgeInsets.only(bottom: 20), // Space between elements
                  child: Text(
                    "Forgot Password",
                    style: TextStyle(
                      color: Colors.white, // White text color
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
                const Padding(
                  padding:
                      EdgeInsets.only(bottom: 20), // Space between elements
                  child: Text(
                    'Enter your email to receive a password reset link',
                    style: TextStyle(
                      color: Colors.white70, // Slightly faded white
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center, // Center the text
                  ),
                ),
                MyTextField(
                  controller: emailController,
                  hintText: "Email",
                  obscureText: false,
                  prefixIconData: Icons.email,
                  prefixIconColor: Colors.white70,
                  textFieldHeight: 55.0,
                  textFieldWidth: double.infinity,
                  onFocusChange: null,
                ),
                const SizedBox(height: 30), // Space after the text field
                MyButton(
                  buttonText: 'Send Reset Link',
                  onPressedAsync: () async {
                    _sendPasswordResetEmail();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
