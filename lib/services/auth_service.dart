import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  // Add this new method to get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  Future<User?> createUserWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      print('Create user error: $e');
      return null;
    }
  }

  Future<User?> loginUserWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return cred.user;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<void> sendEmailVerification(context) async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      print('Verification error: $e');
      throw e;
    }
  }

  bool isEmailVerified() {
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> sendResetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Reset error: $e');
      throw e;
    }
  }

  Future<void> signout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Signout error: $e');
      throw e;
    }
  }

  Future<void> deleteUser() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        await currentUser.delete();
        // Clear any stored login state
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        print('User account deleted successfully');
      } else {
        throw Exception('No user currently logged in');
      }
    } catch (e) {
      print('Delete user error: $e');
      throw e;
    }
  }
}
