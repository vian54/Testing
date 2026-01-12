// Widget test untuk Freelance Hub
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freelance_hub_cashflow/main.dart';

void main() {
  // Setup Firebase Mock untuk testing
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('App should show login screen initially', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());
    
    // Wait for async operations
    await tester.pumpAndSettle();

    // Verify that login screen is shown
    expect(find.text('Freelance Hub'), findsOneWidget);
    expect(find.text('Welcome Back!'), findsOneWidget);
    expect(find.byType(TextField), findsWidgets); // Email & Password fields
  });

  testWidgets('Should show register screen when clicking register link', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle();

    // Find and tap register button
    await tester.tap(find.text('Don\'t have an account? Register'));
    await tester.pumpAndSettle();

    // Verify register screen is shown
    expect(find.text('Create Account'), findsOneWidget);
  });
}

// Mock Firebase for testing
void setupFirebaseAuthMocks() {
  // This is needed to prevent Firebase initialization errors in tests
  TestWidgetsFlutterBinding.ensureInitialized();
}