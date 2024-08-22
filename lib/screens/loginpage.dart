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
            Image.asset(
              'assets/images/landing.jpeg',
              height: 350,
              width: 350,
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.only(left: 37),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.white, // White text color
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                  Text(
                    'Login to continue using the app',
                    style: TextStyle(
                      color: Colors.white70, // Slightly faded white
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 37),
              child: Column(
                children: [
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
                  const SizedBox(height: 20),
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
                  const SizedBox(height: 20), // Adjusted spacing after the button
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
