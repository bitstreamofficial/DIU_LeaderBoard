import 'package:flutter/material.dart';
import 'package:flutter_first/Screens/academic_performance.dart';
import 'package:flutter_first/Screens/ai_recommendations.dart';
import 'package:flutter_first/unnecessary/cgpa_view.dart';
import 'package:flutter_first/Screens/home.dart';
import 'package:flutter_first/Screens/profile.dart';
import 'package:flutter_first/unnecessary/results_view.dart';
import 'package:flutter_first/Screens/settings_view.dart';
import '../models/student_model.dart';
import '../services/auth_service.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final _auth = AuthService();
  int _selectedIndex = 2;
  
  // Temporary mock student info - replace with actual data later
  final studentInfo = StudentInfo(
    studentId: '201-15-3000',
    studentName: 'John Doe',
    programName: 'BSc in CSE',
    departmentName: 'CSE',
    batchNo: '201',
    shift: 'Day',
  );
  
  late List<Widget> _screens;  // Remove final and initialize in initState

  @override
  void initState() {
    super.initState();
    _screens = [
      AIRecommendationsPage(userId: _auth.getCurrentUserId() ?? ''),
      const AcademicPerformancePage(),
      const HomePage(), // Leaderboard
      const SettingsView(),
      const ProfilePage(),
      
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: const Color(0xFF1A1A1A), // Dark background
        indicatorColor: const Color(0xFF2E4F3A), // Dark green indicator
        surfaceTintColor: Colors.transparent,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics, color: Colors.white70),
            selectedIcon: Icon(Icons.analytics, color: Colors.white),
            label: 'Analyze',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment, color: Colors.white70),
            selectedIcon: Icon(Icons.assignment, color: Colors.white),
            label: 'Results',
          ),
          
          NavigationDestination(
            icon: Icon(Icons.leaderboard, color: Colors.white70),
            selectedIcon: Icon(Icons.leaderboard, color: Colors.white),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings, color: Colors.white70),
            selectedIcon: Icon(Icons.settings, color: Colors.white),
            label: 'Settings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person, color: Colors.white70),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
          // NavigationDestination(
          //   icon: Icon(Icons.person, color: Colors.white70),
          //   selectedIcon: Icon(Icons.roundabout_left, color: Colors.white),
          //   label: 'AI',
          // ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
} 