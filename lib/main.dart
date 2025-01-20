import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Screens/splash.dart';
import 'package:flutter_first/Screens/main_navigation.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DIU Buddy',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        // ... existing theme configuration ...
      ),
      home: SplashScreen(),
    );
  }
}