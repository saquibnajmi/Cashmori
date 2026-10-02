import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import 'home_hub_screen.dart';

// Initial screen shown on app launch while the database is loaded and the user is redirected to the hub.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Opens the database and then routes to the home hub once initialization completes.
  Future<void> _initialize() async {
    await DatabaseHelper.instance.database;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeHubScreen()),
    );
  }

  /// Shows the app splash image while the app initializes and loads its database.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FractionallySizedBox(
          widthFactor: 0.75,
          child: Image.asset(
            'assets/icon/cashmori_logo_transparent.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
