import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_first/Screens/login.dart';
import 'package:flutter_first/Screens/privacy_policy.dart';
import 'package:flutter_first/Screens/support_contact_page.dart';
import 'package:flutter_first/Screens/terms_conditions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/theme_service.dart';

// Team Member Model stays the same
class TeamMember {
  final String name;
  final String role;
  final String imageUrl;
  final String description;
  final String githubUrl;
  final String linkedinUrl;

  TeamMember({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.description,
    required this.githubUrl,
    required this.linkedinUrl,
  });
}

class TeamBottomSheet extends StatefulWidget {
  TeamBottomSheet({Key? key}) : super(key: key);

  @override
  State<TeamBottomSheet> createState() => _TeamBottomSheetState();
}

class _TeamBottomSheetState extends State<TeamBottomSheet> {
  final List<TeamMember> teamMembers = [
    
    TeamMember(
      name: 'Syed Sabbir Ahmed',
      role: 'Flutter Developer',
      imageUrl: 'lib\\assets\\Images\\rafi.jpg',
      description:
          'Passionate about creating beautiful and functional Flutter applications.',
      githubUrl: 'https://github.com/rafi6037',
      linkedinUrl: 'https://linkedin.com/in/member2',
    ),
    TeamMember(
      name: 'Shakib Howlader',
      role: 'Flutter Developer',
      imageUrl: 'lib\\assets\\Images\\shakib_dev.jpg',
      description:
          'Passionate about creating beautiful and functional Flutter applications.',
      githubUrl: 'https://github.com/mr-shakib',
      linkedinUrl: 'https://www.linkedin.com/in/shakib-howlader',
    ),
    TeamMember(
      name: 'Sabbir Ahamed',
      role: 'Flutter Developer',
      imageUrl: '',
      description:
          'Passionate about creating beautiful and functional Flutter applications.',
      githubUrl: 'https://github.com/member2',
      linkedinUrl: 'https://linkedin.com/in/member2',
    ),
    TeamMember(
      name: 'Sakib Mahmudd Rahat',
      role: 'UI/UX Designer',
      imageUrl: 'assets/images/member2.jpg',
      description:
          'Creative designer with a focus on user-centered design principles.',
      githubUrl: 'https://github.com/member2',
      linkedinUrl: 'https://linkedin.com/in/member2',
    ),
  ];

  Future<void> _launchUrl(String url, BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch URL')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching URL: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Meet Our Team',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: teamMembers.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final member = teamMembers[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: const Color(0xFF2A2A2A),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: AssetImage(member.imageUrl),
                                  backgroundColor: Colors.grey[800],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        member.role,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              member.description,
                              style: TextStyle(
                                color: Colors.grey[300],
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.code),
                                  color: Colors.white,
                                  onPressed: () =>
                                      _launchUrl(member.githubUrl, context),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.people),
                                  color: Colors.white,
                                  onPressed: () =>
                                      _launchUrl(member.linkedinUrl, context),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Settings View
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool isDarkMode = false;
  bool isNotificationsEnabled = true;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _handleAccountDeletion(BuildContext context) async {
    final bool? confirmDeletion = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              const Text('Delete Account', style: TextStyle(color: Colors.red)),
          content: Text(
            'Are you absolutely sure you want to delete your account? '
            'This action cannot be undone and will permanently remove all your data.',
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.onPrimary,
        );
      },
    );

    if (confirmDeletion == true) {
      try {
        // Get current user ID
        String? userId = _authService.getCurrentUserId();

        if (userId != null) {
          // Delete user data from Firestore
          await _firestore.collection('users').doc(userId).delete();

          // Delete Firebase Authentication account
          await _authService.deleteUser();

          // Clear SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deleted successfully'),
                backgroundColor: Colors.red,
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _handleLogout(BuildContext context) async {
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

    if (confirmLogout == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged out successfully')),
        );

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
    final themeService = Provider.of<ThemeService>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppBarTheme.of(context).backgroundColor,
        title: Text('Settings',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.dark_mode,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Dark Mode',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            trailing: Switch(
              value: themeService.isDarkMode,
              onChanged: (value) {
                themeService.toggleTheme();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        value ? 'Dark mode enabled' : 'Light mode enabled'),
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.notifications,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Notifications',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            trailing: Switch(
              value: isNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  isNotificationsEnabled = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(value
                        ? 'Notifications enabled'
                        : 'Notifications disabled'),
                  ),
                );
              },
            ),
          ),
          ListTile(
            leading: Icon(Icons.language,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Language',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
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
          ListTile(
            leading: Icon(Icons.info,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('About Devs',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => TeamBottomSheet(),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Privacy Policy',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.description,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Terms & Conditions',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsConditionsPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.chat,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Support Chat',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  final userId = _authService.getCurrentUserId();
                  if (userId != null) {
                    return SupportContactPage(userId: userId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User ID is null')),
                    );
                    return Container();
                  }
                }),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Logout',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            trailing: Icon(Icons.arrow_forward_ios,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () => _handleLogout(context),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text('Delete Account',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            subtitle: Text(
                'Permanently remove your account and all associated data',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            trailing: Icon(Icons.warning,
                color: Theme.of(context).colorScheme.onSurface),
            onTap: () => _handleAccountDeletion(context),
          ),
        ],
      ),
    );
  }
}
