import 'package:flutter/material.dart';
import 'package:flutter_first/Screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
      name: 'Shakib Howlader',
      role: 'Flutter Developer',
      imageUrl: 'lib\\assets\\Images\\shakib_dev.jpg',
      description: 'Passionate about creating beautiful and functional Flutter applications.',
      githubUrl: 'https://github.com/mr-shakib',
      linkedinUrl: 'https://www.linkedin.com/in/shakib-howlader',
    ),
    TeamMember(
      name: 'Syed Sabbir Ahmed',
      role: 'Flutter Developer',
      imageUrl: '',
      description:
          'Passionate about creating beautiful and functional Flutter applications.',
      githubUrl: 'https://github.com/member2',
      linkedinUrl: 'https://linkedin.com/in/member2',
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
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                  onPressed: () => _launchUrl(member.githubUrl, context),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.people),
                                  color: Colors.white,
                                  onPressed: () => _launchUrl(member.linkedinUrl, context),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1A1A1A),
      ),
      body: ListView(
        children: [
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
                    content: Text(value
                        ? 'Notifications enabled'
                        : 'Notifications disabled'),
                  ),
                );
              },
            ),
          ),
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
          ListTile(
            leading: const Icon(Icons.info, color: Colors.white),
            title:
                const Text('About Devs', style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
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
