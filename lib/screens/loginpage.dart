import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:punjabigpt/components/my_button.dart';
import 'package:punjabigpt/components/my_textfield.dart';
import 'chat_screen.dart'; // Assuming you have a ChatScreen widget

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFF202123), // Dark background color
      body: SingleChildScrollView(
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
              padding: const EdgeInsets.symmetric(horizontal: 37),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 35),
                    child: const Text(
                      "Login",
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
                      'Login to continue using the app',
                      style: TextStyle(
                        color: Colors.white70, // Slightly faded white
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(
                      height: 20), // Space between text and text fields
                  MyTextField(
                    controller: emailController,
                    hintText: "Email",
                    obscureText: false,
                    prefixIconData: Icons.email,
                    prefixIconColor: Colors.white70,
                    textFieldHeight: 55.0,
                    textFieldWidth: double.infinity,
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
                  ),
                  const SizedBox(
                      height: 30), // Increased space after text fields
                  MyButton(
                    buttonText: 'Login',
                    onPressedAsync: () async {
                      // No authentication, simply navigate to the ChatScreen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => ChatScreen()),
                      );
                    },
                  ),
                  const SizedBox(
                      height: 20), // Adjusted spacing after the button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
