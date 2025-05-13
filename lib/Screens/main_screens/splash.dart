import 'package:flutter/material.dart';
import 'package:diuleaderboard/Screens/auth/login.dart';
import 'package:diuleaderboard/Screens/updates/update_screens.dart';
import 'package:diuleaderboard/main.dart';
import 'package:diuleaderboard/services/update_service.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diuleaderboard/Screens/nav/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    NotificationService().initialize();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward();
    
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkVersionAndLogin();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVersionAndLogin() async {
    if (!mounted) return;

    final updateService = UpdateService();
    final updateStatus = await updateService.checkUpdate();

    if (!mounted) return;

    if (updateStatus['isUnderMaintenance']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MaintenancePage()),
      );
      return;
    }

    if (updateStatus['needsUpdate']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UpdatePromptPage(
            onUpdate: () {
              // Add your store URL launch logic here
            },
          ),
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Theme.of(context).scaffoldBackgroundColor, // Background color
        child: Center(
          child: Lottie.asset(
            'assets/splash_animation.json', // Place your Lottie JSON file here
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.8,
            controller: _controller,
            fit: BoxFit.contain,
            animate: true,
          ),
        ),
      ),
    );
  }
}