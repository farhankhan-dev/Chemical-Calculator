import 'package:flutter/material.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/splash/presentation/screens/security_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../app/main_screen.dart';

/// Named route definitions and route generator.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String security = '/security';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const MainScreen(),
        );
      case security:
        return MaterialPageRoute(
          builder: (_) => const SecurityScreen(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
