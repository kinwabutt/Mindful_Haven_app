import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? get currentUserUid => _auth.currentUser?.uid;

  bool get isLoggedIn => _auth.currentUser != null;
Future<String?> login(String email, String password) async {
  try {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(), 
      password: password.trim(),
    );
    notifyListeners();
    return null; // Null ka matlab hai "No Error", login successful!
  } on FirebaseAuthException catch (e) {
    debugPrint("Firebase Error Code: ${e.code}");
    // Yahan hum asali wajah return kar rahe hain
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      case 'invalid-email':
        return 'The email address is not valid.';
      default:
        return e.message ?? 'An unknown error occurred.';
    }
  } catch (e) {
    return e.toString();
  }
}

  // 2. SIGNUP / REGISTER
  Future<bool> registerUser(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Registration error: $e");
      return false;
    }
  }

  // 3. PASSWORD RESET
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint("Reset link sent to: $email");
    } catch (e) {
      debugPrint("Reset error: $e");
    }
  }

  // 4. LOGOUT (Updated)
  Future<void> logout() async {
    try {
      // 1. Local data clear karein taake next login par purana data na aaye
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); 
      
      // 2. Firebase sign out
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint("Logout error: $e");
    }
  }
}