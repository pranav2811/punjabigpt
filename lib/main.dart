import 'package:flutter/material.dart';
import 'package:punjabigpt/screens/loginpage.dart';


void main() {
  runApp(ChatGPTCloneApp());
}

class ChatGPTCloneApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGPT Clone',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blueGrey[900],
        scaffoldBackgroundColor: Colors.black,
        hintColor: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.grey[900],
        ),
      ),
      home: LoginPage(),
    );
  }
}