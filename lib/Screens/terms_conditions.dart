import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background for contrast
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Terms & Conditions", 
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
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
                color: Colors.white,
                letterSpacing: 1.2
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _buildTermsSection(
              "1. Eligibility", 
              "The app is only available for DIU students."
            ),
            _buildTermsSection(
              "2. User Responsibilities", 
              "Users must not misuse the app or provide false information."
            ),
            _buildTermsSection(
              "3. Data Accuracy", 
              "We do not guarantee 100% accuracy of CGPA data as it depends on university sources."
            ),
            _buildTermsSection(
              "4. App Usage", 
              "Unauthorized access, modification, or distribution of the app is strictly prohibited."
            ),
            _buildTermsSection(
              "5. Termination", 
              "We reserve the right to terminate access in case of any violation."
            ),
            SizedBox(height: 20),
            Text(
              "By using this app, you agree to these terms.",
              style: TextStyle(
                fontSize: 16, 
                fontStyle: FontStyle.italic,
                color: Colors.white,
                letterSpacing: 0.5
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[900], // Slightly lighter than black for contrast
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
              color: Colors.white
            ),
          ),
          SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16, 
              color: Colors.white70
            ),
          ),
        ],
      ),
    );
  }
}