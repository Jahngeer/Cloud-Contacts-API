import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'package:cloud_contacts/screens/user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_contacts/database_helper/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Sqflite.setDebugModeOn(true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Cloud Contacts API",
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startAppWorkflow();
  }

  void _startAppWorkflow() {
    OfflineSyncManager.instance.uploadPendingChangesToCloud().catchError((e) {
      print("⚠️ Background Splash Sync Error: $e");
    });

    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const UserListScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.asset(
            'assets/images/splashicon.png',
            width: MediaQuery.of(context).size.width * 0.98,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
