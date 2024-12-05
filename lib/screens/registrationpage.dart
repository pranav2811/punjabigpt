import 'package:flutter/material.dart';
import 'package:punjabigpt/components/my_button.dart';
import 'package:punjabigpt/components/my_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'model_selection_screen.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isEmailValid(String email) {
    final RegExp emailRegex =
        RegExp(r"^[a-zA-Z0-9]+[a-zA-Z0-9._%+-]*@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  void _scrollToFocusedInput(BuildContext context, FocusNode focusNode) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (focusNode.hasFocus) {
        _scrollController.animateTo(
          focusNode.offset.dy - 100.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF202123),
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
                const Padding(
                  padding: EdgeInsets.only(left: 35),
                  child: Text(
                    "Register",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                const Padding(
                  padding: EdgeInsets.only(left: 35.0),
                  child: Text(
                    'Create an account to continue',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                const SizedBox(height: 30),
                MyButton(
                  buttonText: 'Register',
                  onPressedAsync: () async {
                    if (!_isEmailValid(emailController.text)) {
                      Fluttertoast.showToast(
                        msg: "Please enter a valid email address.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                      return;
                    }

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
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .createUserWithEmailAndPassword(
                        email: emailController.text.trim(),
                        password: passwordController.text,
                      );

                      Fluttertoast.showToast(
                        msg: "Registration Successful!",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ModelSelectionScreen()),
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
