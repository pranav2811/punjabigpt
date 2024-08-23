import 'package:flutter/material.dart';
import 'package:punjabigpt/components/my_button.dart';
import 'package:punjabigpt/components/my_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'chat_screen.dart'; // Assuming you have a ChatScreen widget

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToFocusedInput(BuildContext context, FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.hasFocus) {
        _scrollController.animateTo(
          focusNode.offset.dy - 100.0, // Adjust the offset as needed
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFF202123), // Dark background color
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 37),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 350,
                      width: 350,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.only(left: 35),
                  child: const Text(
                    "Register",
                    style: TextStyle(
                      color: Colors.white, // White text color
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 5), // Slight space between texts
                Padding(
                  padding: const EdgeInsets.only(left: 35.0),
                  child: const Text(
                    'Create an account to continue',
                    style: TextStyle(
                      color: Colors.white70, // Slightly faded white
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(
                    height: 20), // Space between text and text fields
                MyTextField(
                  controller: nameController,
                  hintText: "Name",
                  obscureText: false,
                  prefixIconData: Icons.person,
                  prefixIconColor: Colors.white70,
                  textFieldHeight: 55.0,
                  textFieldWidth: double.infinity,
                  onFocusChange: (focusNode) =>
                      _scrollToFocusedInput(context, focusNode),
                ),
                const SizedBox(height: 20),
                MyTextField(
                  controller: emailController,
                  hintText: "Email",
                  obscureText: false,
                  prefixIconData: Icons.email,
                  prefixIconColor: Colors.white70,
                  textFieldHeight: 55.0,
                  textFieldWidth: double.infinity,
                  onFocusChange: (focusNode) =>
                      _scrollToFocusedInput(context, focusNode),
                ),
                const SizedBox(height: 20),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                  prefixIconData: Icons.lock,
                  prefixIconColor: Colors.white70,
                  textFieldHeight: 55.0,
                  textFieldWidth: double.infinity,
                  onFocusChange: (focusNode) =>
                      _scrollToFocusedInput(context, focusNode),
                ),
                const SizedBox(height: 20),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                  prefixIconData: Icons.lock_outline,
                  prefixIconColor: Colors.white70,
                  textFieldHeight: 55.0,
                  textFieldWidth: double.infinity,
                  onFocusChange: (focusNode) =>
                      _scrollToFocusedInput(context, focusNode),
                ),
                const SizedBox(height: 30), // Increased space after text fields
                MyButton(
                  buttonText: 'Register',
                  onPressedAsync: () async {
                    // Validate password and confirm password
                    if (passwordController.text !=
                        confirmPasswordController.text) {
                      Fluttertoast.showToast(
                        msg: "Passwords do not match!",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                      return;
                    }

                    try {
                      // Register the user with Firebase Auth
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .createUserWithEmailAndPassword(
                        email: emailController.text,
                        password: passwordController.text,
                      );

                      Fluttertoast.showToast(
                        msg: "Registration Successful!",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );

                      // Navigate to the ChatScreen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen()),
                      );
                    } on FirebaseAuthException catch (e) {
                      String errorMessage;
                      if (e.code == 'weak-password') {
                        errorMessage = 'The password provided is too weak.';
                      } else if (e.code == 'email-already-in-use') {
                        errorMessage =
                            'The account already exists for that email.';
                      } else if (e.code == 'invalid-email') {
                        errorMessage = 'The email address is not valid.';
                      } else {
                        errorMessage = 'Registration failed. Please try again.';
                      }

                      Fluttertoast.showToast(
                        msg: errorMessage,
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    } catch (e) {
                      Fluttertoast.showToast(
                        msg: "An unexpected error occurred. Please try again.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                    }
                  },
                ),
                const SizedBox(height: 20), // Adjusted spacing after the button
              ],
            ),
          ),
        ),
      ),
    );
  }
}
