import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Register
  Future<String?> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ⭐ CASHFLOW: Initialize balance
      await _firestore.collection('users').doc(result.user!.uid).set({
        'name': name,
        'email': email,
        'role': role,
        'balance': 0.0, // ⭐ Available balance
        'totalEarnings': 0.0, // ⭐ Total earned
        'totalSpent': 0.0, // ⭐ Total spent (for clients)
        'totalWithdrawn': 0.0, // ⭐ Total withdrawn
        'rating': 0.0,
        'completedProjects': 0,
        'jobsPosted': 0, // ⭐ Jobs posted (for clients)
        'activeProjects': 0, // ⭐ Active projects
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } catch (e) {
      return e.toString();
    }
  }

  // Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return 'Login failed: ${e.toString()}';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;

    DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    return doc.data() as Map<String, dynamic>?;
  }
}
