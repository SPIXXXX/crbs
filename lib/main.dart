import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const CRBSApp());
}

class CRBSApp extends StatelessWidget{
  const CRBSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRBS App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A1628),
         // Light gray background color.
      ),  
      home: const LoginPage(), // Set the initial screen to the login page.
    );
  }
}