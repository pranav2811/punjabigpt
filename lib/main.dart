import 'package:flutter/material.dart';
import 'package:punjabigpt/screens/loginpage.dart';
import 'screens/chat_screen.dart';

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
        textTheme: TextTheme(
          bodyText1: TextStyle(color: Colors.white),
          bodyText2: TextStyle(color: Colors.white),
        ),
        drawerTheme: DrawerThemeData(
          backgroundColor: Colors.grey[900],
        ),
      ),
      home: LoginPage(),
    );
  }
}
