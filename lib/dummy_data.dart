import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  print('Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Firebase initialized.');

  final auth = FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;

  // Try to sign in anonymously or with dummy account
  try {
    await auth.signInAnonymously();
    print('Signed in anonymously.');
  } catch (e) {
    print('Anonymous sign in failed: $e');
    // Try to create a dummy user
    try {
      await auth.createUserWithEmailAndPassword(
        email: 'dummy@example.com',
        password: 'password123',
      );
      print('Created dummy user.');
    } catch (e) {
      print('Create user failed: $e');
      return;
    }
  }

  // Dummy users
  await firestore.collection('users').doc('user1').set({
    'name': 'John Doe',
    'email': 'john@example.com',
    'role': 'freelancer',
    'balance': 500000.0,
    'totalEarnings': 1500000.0,
    'totalWithdrawn': 1000000.0,
    'rating': 4.5,
    'completedProjects': 5,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await firestore.collection('users').doc('user2').set({
    'name': 'Jane Smith',
    'email': 'jane@example.com',
    'role': 'client',
    'balance': 2000000.0,
    'totalEarnings': 0.0,
    'totalWithdrawn': 0.0,
    'rating': 0.0,
    'completedProjects': 0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Dummy jobs
  await firestore.collection('jobs').add({
    'title': 'Mobile App Development',
    'description': 'Build a Flutter app for e-commerce',
    'category': 'Development',
    'budget': 2000000.0,
    'clientId': 'user2',
    'status': 'open',
    'createdAt': FieldValue.serverTimestamp(),
  });

  await firestore.collection('jobs').add({
    'title': 'Logo Design',
    'description': 'Create modern logo for startup',
    'category': 'Design',
    'budget': 500000.0,
    'clientId': 'user2',
    'status': 'open',
    'createdAt': FieldValue.serverTimestamp(),
  });

  // Dummy transactions
  await firestore.collection('transactions').add({
    'projectId': 'project1',
    'fromUserId': 'user2',
    'toUserId': 'user1',
    'type': 'payment',
    'amount': 1000000.0,
    'netAmount': 950000.0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  await firestore.collection('transactions').add({
    'projectId': 'project2',
    'fromUserId': 'user2',
    'toUserId': 'user1',
    'type': 'payment',
    'amount': 500000.0,
    'netAmount': 475000.0,
    'createdAt': FieldValue.serverTimestamp(),
  });

  print('Dummy data inserted successfully!');
}
