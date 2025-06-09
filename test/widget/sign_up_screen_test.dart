import 'package:book/providers/auth_provider.dart';
import 'package:book/screens/dashboard.dart';
import 'package:book/screens/sign_up_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

// Generate mocks for AuthProvider
@GenerateMocks([AuthProvider])
import 'sign_up_screen_test.mocks.dart'; // Import generated mocks

void main() {
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    // Stub the isDoctor getter to return a default value (e.g., false)
    // This is important because Dashboard will try to access it.
    when(mockAuthProvider.isDoctor).thenReturn(false);
     // Stubbing authStateChanges to return a stream of null initially
    when(mockAuthProvider.authStateChanges).thenAnswer((_) => Stream.value(null));
    when(mockAuthProvider.isLoggedIn).thenReturn(false);
  });

  Widget createTestableWidget(Widget child) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: mockAuthProvider,
      child: MaterialApp(
        home: child,
        // Adding a navigator observer could be useful for verifying navigation
        // For now, Dashboard is simple enough not to require it for this test.
        routes: {
          '/dashboard': (_) => const Dashboard(), // Mock a route for Dashboard
        },
      ),
    );
  }

  group('SignUpScreen Widget Tests', () {
    testWidgets('displays error message when signUp throws FirebaseAuthException', (WidgetTester tester) async {
      // Arrange
      final specificErrorMessage = 'The email address is already in use by another account.';
      when(mockAuthProvider.signUp(any, any, any)).thenThrow(
        FirebaseAuthException(code: 'email-already-in-use', message: specificErrorMessage),
      );

      await tester.pumpWidget(createTestableWidget(const SignUpScreen()));

      // Act
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(); // Process the async call and UI updates

      // Assert
      expect(find.text(specificErrorMessage), findsOneWidget);
      expect(find.text('Sign up failed'), findsNothing); // Ensure generic message isn't shown
    });

    testWidgets('calls authProvider.signUp with correct data and navigates on success', (WidgetTester tester) async {
      // Arrange
      // Stubbing signUp to complete successfully
      when(mockAuthProvider.signUp(any, any, any)).thenAnswer((_) async => Future.value());
      // Stubbing isLoggedIn to true after signup for navigation guard if any
      when(mockAuthProvider.isLoggedIn).thenReturn(true);
       // After signUp, authStateChanges might emit a user.
      // For Dashboard to build without error, stub isDoctor.
      when(mockAuthProvider.isDoctor).thenReturn(false);


      await tester.pumpWidget(createTestableWidget(const SignUpScreen()));

      // Act
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      // Default is Patient (isDoctor = false)
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(); // Process navigation

      // Assert
      verify(mockAuthProvider.signUp('test@example.com', 'password123', false)).called(1);
      // Check if Dashboard is pushed. Since Dashboard is simple, checking for its title.
      // A more robust way would be to use a mock navigator.
      expect(find.byType(Dashboard), findsOneWidget);
    });

    testWidgets('isDoctor toggle correctly passes value to authProvider.signUp', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.signUp(any, any, any)).thenAnswer((_) async => Future.value());
      when(mockAuthProvider.isLoggedIn).thenReturn(true);
      when(mockAuthProvider.isDoctor).thenReturn(true); // Assume doctor signs up

      await tester.pumpWidget(createTestableWidget(const SignUpScreen()));

      // Act
      await tester.enterText(find.byType(TextFormField).at(0), 'doctor@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');

      // Tap the 'Doctor' toggle button
      await tester.tap(find.text('Doctor'));
      await tester.pump(); // Rebuild after setState

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      verify(mockAuthProvider.signUp('doctor@example.com', 'password123', true)).called(1);
      expect(find.byType(Dashboard), findsOneWidget);
    });

     testWidgets('displays generic error message for non-FirebaseAuth exceptions', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.signUp(any, any, any)).thenThrow(
        Exception('Some other error'), // Generic exception
      );

      await tester.pumpWidget(createTestableWidget(const SignUpScreen()));

      // Act
      await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('An unknown error occurred.'), findsOneWidget);
    });
  });
}
