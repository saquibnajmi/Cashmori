import 'package:flutter/material.dart';
import 'screens/home_hub_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const CashmoriApp());
}

class CashmoriApp extends StatelessWidget {
  const CashmoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashmori',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeHubScreen(),
    );
  }
}
