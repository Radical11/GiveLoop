import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(const GiveLoopApp());
}

class GiveLoopApp extends StatelessWidget {
  const GiveLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GiveLoop',
      theme: ThemeData(useMaterial3: true),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
