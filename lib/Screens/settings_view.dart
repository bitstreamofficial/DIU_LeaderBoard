import 'package:flutter/material.dart';
import 'package:flutter_first/Screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;

  void _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    // If user confirmed logout
    if (confirmLogout == true) {
      //logout logic here
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();


      if (mounted) {
        // Show logout message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );

        // Navigate to login page and clear navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false, 
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: ListView(
        children: [
          // Dark Mode Toggle
          ListTile(
            leading: const Icon(Icons.dark_mode, color: Colors.white),
            title:
                const Text('Dark Mode', style: TextStyle(color: Colors.white)),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) {
                setState(() {
                  isDarkMode = value;
                });
                if (isDarkMode) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dark mode enabled')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Light mode enabled')),
                  );
                }
              },
            ),
          ),

          // Notifications Toggle
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.white),
            title: const Text('Notifications',
                style: TextStyle(color: Colors.white)),
            trailing: Switch(
              value: isNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  isNotificationsEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isNotificationsEnabled
                        ? 'Notifications enabled'
                        : 'Notifications disabled'),
                  ),
                );
              },
            ),
          ),

          // Language Selection
          ListTile(
            leading: const Icon(Icons.language, color: Colors.white),
            title:
                const Text('Language', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Select Language'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: const Text('English'),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Language set to English')),
                            );
                          },
                        ),
                        ListTile(
                          title: const Text('Bangla'),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Language set to Bangla')),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          // About Dialog
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title: const Text('About', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'DIU Leaderboard',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2025 BitStream',
                children: [
                  const Text('Wait till you meet the team!'),
                ],
              );
            },
          ),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.red),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }
}
