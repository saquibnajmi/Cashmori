import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

// App entry point. This boots the Flutter app and starts from the splash screen,
// which then loads the database and opens the main hub.
void main() {
  runApp(const CashmoriApp());
}

// Root widget that configures the app theme and the initial screen shown to the user.
class CashmoriApp extends StatelessWidget {
  const CashmoriApp({super.key});

  /// Builds the root Material app and sets the app-wide theme and initial screen.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashmori',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),
    );
  }
}
