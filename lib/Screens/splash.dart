import 'package:flutter/material.dart';
import 'package:flutter_first/Screens/home.dart';
import 'package:flutter_first/Screens/login.dart';
import 'package:flutter_first/Screens/update_screens.dart';
import 'package:flutter_first/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3), // Match this with your GIF duration
    )..forward();
    _checkVersionAndLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkVersionAndLogin() async {
    await Future.delayed(Duration(seconds: 3));

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
        MaterialPageRoute(builder: (context) => HomePage()),
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Image.asset(
              'assets/splash.gif',
              fit: BoxFit.fill,
              width: double.infinity,
              height: double.infinity,
              gaplessPlayback: true,
              repeat: ImageRepeat.noRepeat,
            );
          },
        ),
      ),
    );
  }
}