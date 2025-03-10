import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
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
          "Terms & Conditions",
          style: TextStyle(color: colorScheme.onBackground), // Use onBackground color
        ),
        iconTheme: IconThemeData(color: colorScheme.onBackground), // Use onBackground color
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Terms & Conditions",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground, // Use onBackground color
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _buildTermsSection(
              context,
              "1. Eligibility",
              "The app is only available for DIU students.",
            ),
            _buildTermsSection(
              context,
              "2. User Responsibilities",
              "Users must not misuse the app or provide false information.",
            ),
            _buildTermsSection(
              context,
              "3. Data Accuracy",
              "We do not guarantee 100% accuracy of CGPA data as it depends on university sources.",
            ),
            _buildTermsSection(
              context,
              "4. App Usage",
              "Unauthorized access, modification, or distribution of the app is strictly prohibited.",
            ),
            _buildTermsSection(
              context,
              "5. Termination",
              "We reserve the right to terminate access in case of any violation.",
            ),
            SizedBox(height: 20),
            Text(
              "By using this app, you agree to these terms.",
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

  Widget _buildTermsSection(BuildContext context, String title, String content) {
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