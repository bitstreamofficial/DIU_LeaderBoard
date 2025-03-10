import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Access the current theme from Theme.of(context)
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background, // Use background color from the theme
      appBar: AppBar(
        backgroundColor: colorScheme.background, // Match the background color
        title: Text(
          "Privacy Policy",
          style: TextStyle(color: colorScheme.onBackground), // Use onBackground color
        ),
        iconTheme: IconThemeData(color: colorScheme.onBackground), // Use onBackground color
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Privacy Policy",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground, // Use onBackground color
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _buildPrivacySection(
              context,
              "1. Data Collection",
              "We collect student ID, CGPA, batch, and department to display rankings.",
            ),
            _buildPrivacySection(
              context,
              "2. Data Usage",
              "The collected data is used solely for leaderboard ranking purposes.",
            ),
            _buildPrivacySection(
              context,
              "3. Data Storage",
              "Data is stored securely in JSON format within the app.",
            ),
            _buildPrivacySection(
              context,
              "4. User Rights",
              "You can choose to display your name or remain anonymous.",
            ),
            _buildPrivacySection(
              context,
              "5. Third-Party Sharing",
              "Your data is not shared with any third parties.",
            ),
            SizedBox(height: 20),
            Text(
              "For more details, contact our support team.",
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: colorScheme.onBackground, // Use onBackground color
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colorScheme.surface, // Use surface color for containers
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface, // Use onSurface color
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7), // Slightly transparent onSurface color
            ),
          ),
        ],
      ),
    );
  }
}