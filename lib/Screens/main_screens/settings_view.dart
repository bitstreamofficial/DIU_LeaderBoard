import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:diuleaderboard/Screens/auth/login.dart';
import 'package:diuleaderboard/Screens/settings/privacy_policy.dart';
import 'package:diuleaderboard/Screens/settings/support_contact_page.dart';
import 'package:diuleaderboard/Screens/settings/terms_conditions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/theme_service.dart';

// Team Member Model stays the same
class TeamMember {
  final String name;
  final String role;
  final String imageUrl;
  final String description;
  final String portfolio;
  final String githubUrl;
  final String linkedinUrl;

  TeamMember({
    required this.name,
    required this.role,
    required this.imageUrl,
    required this.description,
    required this.portfolio,
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
      role: 'UI/UX Engineer',
      imageUrl: 'lib\\assets\\Images\\rafi.jpg',
      description:
          'Dedicated UI/UX engineer focused on crafting seamless user experiences and intuitive interfaces using Flutter. Combines design principles with technical skills to deliver polished mobile apps.',
      portfolio: '',
      githubUrl: 'https://github.com/rafi6037',
      linkedinUrl: 'https://www.linkedin.com/in/syed-sabbir-ahmed',
    ),
    TeamMember(
      name: 'Shakib Howlader',
      role: 'Mobile App Architect',
      imageUrl: 'lib\\assets\\Images\\shakib_dev.jpg',
      description:
          'Experienced in designing scalable Flutter architectures and managing full app lifecycles. Adept at implementing clean code practices and optimizing performance for robust mobile applications.',
      portfolio: 'https://shakibhowlader.vercel.app/',
      githubUrl: 'https://github.com/mr-shakib',
      linkedinUrl: 'https://www.linkedin.com/in/shakib-howlader',
    ),
    TeamMember(
      name: 'Sabbir Ahamed',
      role: 'Backend Integrator',
      imageUrl: 'lib\\assets\\Images\\sabbir_dev.jpg',
      description:
          'Skilled in integrating RESTful APIs and Firebase services into Flutter applications. Focused on creating responsive, data-driven features that enhance app functionality and reliability.',
      portfolio: 'https://sites.google.com/diu.edu.bd/sabbir-ahamed-rs/home',
      githubUrl: 'https://github.com/Redoy0',
      linkedinUrl: 'https://www.linkedin.com/in/md-sabbir-ahamed',
    ),

    // TeamMember(
    //   name: 'Sakib Mahmudd Rahat',
    //   role: 'Marketing',
    //   imageUrl: 'assets/images/member2.jpg',
    //   description:
    //       'Strategic marketer with a strong background in brand communication and digital engagement. Passionate about crafting compelling messages and driving user growth through innovative campaigns.',
    //   githubUrl: 'https://github.com/member2',
    //   linkedinUrl: 'https://linkedin.com/in/member2',
    // ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Meet Our Team',
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onSurface,
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
                      color: colorScheme.surfaceVariant,
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
                                  backgroundColor:
                                      colorScheme.onSurface.withOpacity(0.1),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.name,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        member.role,
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withOpacity(0.7),
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
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Image.asset(
                                    'assets/images/portfolio.png',
                                    width: 28,
                                    height: 28,
                                  ),
                                  onPressed: () =>
                                      _launchUrl(member.portfolio, context),
                                ),
                                IconButton(
                                  icon: Image.asset(
                                    'assets/images/github-mark-white.png',
                                    width: 24,
                                    height: 24,
                                  ),
                                  onPressed: () =>
                                      _launchUrl(member.githubUrl, context),
                                ),
                                IconButton(
                                  icon: Image.asset(
                                    'assets/images/linkedin_icon.png',
                                    width: 24,
                                    height: 24,
                                  ),
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
          title: Text('Delete Account',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          content: Text(
            'Are you absolutely sure you want to delete your account? '
            'This action cannot be undone and will permanently remove all your data.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete Account',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.surface,
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
              SnackBar(
                content: Text('Account deleted successfully'),
                backgroundColor: Theme.of(context).colorScheme.error,
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
              backgroundColor: Theme.of(context).colorScheme.error,
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
          title: Text('Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Text('Are you sure you want to log out?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Logout',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface)),
            ),
          ],
          backgroundColor: Theme.of(context).colorScheme.surface,
        );
      },
    );

    if (confirmLogout == true) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged out successfully')),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text('Settings',
            style:
                textTheme.titleLarge?.copyWith(color: colorScheme.onSurface)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.dark_mode, color: colorScheme.onSurface),
            title: Text('Dark Mode',
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface)),
            trailing: Switch(
              value: themeService.isDarkMode,
              activeColor: colorScheme.secondary,
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
            leading: Icon(Icons.notifications, color: colorScheme.onSurface),
            title: Text('Notifications',
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface)),
            trailing: Switch(
              value: isNotificationsEnabled,
              activeColor: colorScheme.secondary,
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
            leading: Icon(Icons.chat, color: colorScheme.onSurface),
            title: Text('Support Chat',
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface)),
            trailing:
                Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  final userId = _authService.getCurrentUserId();
                  if (userId != null) {
                    return SupportContactPage(userId: userId);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('User ID is null')),
                    );
                    return Container();
                  }
                }),
              );
            },
          ),
          // ListTile(
          //   leading: Icon(Icons.language, color: colorScheme.onSurface),
          //   title: Text('Language',
          //       style: textTheme.bodyLarge
          //           ?.copyWith(color: colorScheme.onSurface)),
          //   trailing:
          //       Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface),
          //   onTap: () {
          //     showDialog(
          //       context: context,
          //       builder: (context) {
          //         return AlertDialog(
          //           title: Text('Select Language',
          //               style: textTheme.titleLarge
          //                   ?.copyWith(color: colorScheme.onSurface)),
          //           content: Column(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               ListTile(
          //                 title: Text('English',
          //                     style: textTheme.bodyLarge
          //                         ?.copyWith(color: colorScheme.onSurface)),
          //                 onTap: () {
          //                   Navigator.pop(context);
          //                   ScaffoldMessenger.of(context).showSnackBar(
          //                     SnackBar(
          //                         content: Text('Language set to English')),
          //                   );
          //                 },
          //               ),
          //               ListTile(
          //                 title: Text('Bangla',
          //                     style: textTheme.bodyLarge
          //                         ?.copyWith(color: colorScheme.onSurface)),
          //                 onTap: () {
          //                   Navigator.pop(context);
          //                   ScaffoldMessenger.of(context).showSnackBar(
          //                     SnackBar(content: Text('Language set to Bangla')),
          //                   );
          //                 },
          //               ),
          //             ],
          //           ),
          //           backgroundColor: colorScheme.surface,
          //         );
          //       },
          //     );
          //   },
          // ),
          ListTile(
            leading: Icon(Icons.info, color: colorScheme.onSurface),
            title: Text('About Devs',
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface)),
            trailing:
                Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface),
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
            leading: Icon(Icons.privacy_tip, color: colorScheme.onSurface),
            title: Text('Privacy Policy',
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface)),
            trailing:
                Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PrivacyPolicyPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.description, color: colorScheme.onSurface),
            title: Text('Terms & Conditions',
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface)),
            trailing:
                Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TermsConditionsPage()),
              );
            },
          ),

          ListTile(
            leading: Icon(Icons.delete_forever, color: colorScheme.onSurface),
            title: Text('Delete Account',
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface)),
            subtitle: Text(
                'Permanently remove your account and all associated data',
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurface.withOpacity(0.7))),
            trailing: Icon(Icons.warning, color: colorScheme.onSurface),
            onTap: () => _handleAccountDeletion(context),
          ),

          const SizedBox(
            height: 30,
          ),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: InkWell(
              onTap: () => _handleLogout(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [Colors.deepPurple, Colors.indigo] // Dark mode colors
                        : [
                            Colors.deepOrangeAccent,
                            Colors.deepPurpleAccent,
                          ], // Light mode colors
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Logout',
                        style:
                            textTheme.bodyLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
