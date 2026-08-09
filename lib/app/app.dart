import 'package:flutter/material.dart';
import 'routes.dart';
import 'theme/app_theme.dart';

/// Root widget — MaterialApp configuration.
class ChemiCalcApp extends StatelessWidget {
  const ChemiCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChemiCalc',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
