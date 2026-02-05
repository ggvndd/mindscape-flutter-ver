import 'package:flutter/material.dart';
import '../../presentation/screens/onboarding/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/onboarding/welcome_screen.dart';
import '../../presentation/screens/auth/sign_up_screen.dart';
import '../../presentation/screens/auth/rush_hour_screen.dart';
import '../../presentation/screens/auth/sign_up_success_screen.dart';
import '../../presentation/screens/auth/sign_in_screen.dart';
import '../../presentation/screens/home/home_screen.dart';

/// App routing configuration
class AppRouter {
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String welcomeRoute = '/welcome';
  static const String signUpRoute = '/sign-up';
  static const String rushHourRoute = '/rush-hour';
  static const String signUpSuccessRoute = '/sign-up-success';
  static const String signInRoute = '/sign-in';
  static const String homeRoute = '/home';
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboardingRoute:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case welcomeRoute:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case signUpRoute:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case rushHourRoute:
        return MaterialPageRoute(builder: (_) => const RushHourScreen());
      case signUpSuccessRoute:
        return MaterialPageRoute(builder: (_) => const SignUpSuccessScreen());
      case signInRoute:
        return MaterialPageRoute(builder: (_) => const SignInScreen());
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