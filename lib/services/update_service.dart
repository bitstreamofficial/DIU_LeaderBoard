import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateService {
  static const String currentAppVersion = "1.0.0";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> checkUpdate() async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('checkUpdate').doc('status').get();

      if (doc.exists) {
        return {
          'isUnderMaintenance': doc.get('Updating') ?? false,
          'latestVersion': doc.get('LatestVersion') ?? currentAppVersion,
          'needsUpdate': doc.get('LatestVersion') != currentAppVersion,
        };
      }
      return {
        'isUnderMaintenance': false,
        'latestVersion': currentAppVersion,
        'needsUpdate': false,
      };
    } catch (e) {
      print('Error checking update: $e');
      return {
        'isUnderMaintenance': false,
        'latestVersion': currentAppVersion,
        'needsUpdate': false,
      };
    }
  }
}
