import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'login_screen.dart';
import 'signin_screen.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'details_screen.dart';
import 'pledge_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
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
        '/details': (context) => const DetailsScreen(
          title: 'NGO Title',
          location: 'Raipur',
          distance: '2 km away',
          tag: 'Medical',
          imageAsset: 'assets/images/ngo1.png',
          about: 'About this NGO',
          urgentText: 'Urgent needs description.',
        ),
        '/pledge': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return PledgeScreen(
            needId: args['needId'],
            category: args['category'],
          );
        },
      },
    );
  }
}
