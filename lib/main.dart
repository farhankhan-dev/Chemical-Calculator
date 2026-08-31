// App entry point — sets up MaterialApp, theme, routes
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'app/app.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    MobileAds.instance.initialize();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Security: In production, show a clean error screen instead of
    // the red debug error screen that exposes internal code paths.
    if (!kDebugMode) {
      ErrorWidget.builder = (FlutterErrorDetails details) {
        return const Material(
          child: Center(
            child: Text(
              'Something went wrong.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        );
      };
    }

    runApp(const ChemiCalcApp());
  }, (error, stackTrace) {
    // Security: In debug mode, print errors for development.
    // In production, errors are silently caught to prevent info leakage.
    if (kDebugMode) {
      debugPrint('Unhandled error: $error');
      debugPrint('$stackTrace');
    }
  });
}
