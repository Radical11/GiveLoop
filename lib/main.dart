import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'providers/needs_provider.dart';
import 'login_screen.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';
import 'providers/donation_streak_provider.dart';
import 'home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => NeedsProvider()),
        ChangeNotifierProvider(create: (_) => DonationStreakProvider()..load()),
      ],
      child: const GiveLoopApp(),
    ),
  );
}

class GiveLoopApp extends StatelessWidget {
  const GiveLoopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GiveLoop',
      theme: ThemeData(useMaterial3: true, fontFamily: 'Inter'),
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
