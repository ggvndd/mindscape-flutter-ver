import 'package:flutter/material.dart';
import '../../presentation/screens/onboarding/welcome_screen.dart';
import '../../presentation/screens/main/home_screen.dart';

/// App routing configuration
class AppRouter {
  static const String welcomeRoute = '/welcome';
  static const String homeRoute = '/home';
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcomeRoute:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}