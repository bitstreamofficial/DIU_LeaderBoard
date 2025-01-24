import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          "Privacy Policy", 
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
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
                color: Colors.white,
                letterSpacing: 1.2
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _buildPrivacySection(
              "1. Data Collection", 
              "We collect student ID, CGPA, batch, and department to display rankings."
            ),
            _buildPrivacySection(
              "2. Data Usage", 
              "The collected data is used solely for leaderboard ranking purposes."
            ),
            _buildPrivacySection(
              "3. Data Storage", 
              "Data is stored securely in JSON format within the app."
            ),
            _buildPrivacySection(
              "4. User Rights", 
              "You can choose to display your name or remain anonymous."
            ),
            _buildPrivacySection(
              "5. Third-Party Sharing", 
              "Your data is not shared with any third parties."
            ),
            SizedBox(height: 20),
            Text(
              "For more details, contact our support team.",
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

  Widget _buildPrivacySection(String title, String content) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
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