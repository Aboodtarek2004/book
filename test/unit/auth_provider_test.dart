import 'package:book/models/user.dart' as UserModel;
import 'package:book/providers/auth_provider.dart';
import 'package:book/services/auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'dart:async';

// Manual Mock for AuthService
class MockAuthService extends Mock implements AuthService {
  // We need to control the authStateChanges stream for these tests.
  final _authStateController = StreamController<FirebaseAuth.User?>();

  @override
  Stream<FirebaseAuth.User?> get authStateChanges => _authStateController.stream;

  // Method to easily emit values on the stream
  void emitAuthState(FirebaseAuth.User? user) {
    _authStateController.add(user);
  }

  void closeStream() {
    _authStateController.close();
  }

  // Mocking other methods used by AuthProvider
  @override
  Future<FirebaseAuth.UserCredential> signUp(String email, String password, bool isDoctor) {
    return super.noSuchMethod(
      Invocation.method(#signUp, [email, password, isDoctor]),
      returnValue: Future.value(MockUserCredential()), // Return a mock UserCredential
      returnValueForMissingStub: Future.value(MockUserCredential()),
    ) as Future<FirebaseAuth.UserCredential>;
  }

  @override
  Future<void> signOut() {
     return super.noSuchMethod(
      Invocation.method(#signOut, []),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    ) as Future<void>;
  }
}

// Manual Mock for UserCredential
class MockUserCredential extends Mock implements FirebaseAuth.UserCredential {
  @override
  FirebaseAuth.User? get user => super.noSuchMethod(
        Invocation.getter(#user),
        returnValue: MockFirebaseAuthUser(), // Return a mock User
        returnValueForMissingStub: MockFirebaseAuthUser(),
      ) as FirebaseAuth.User?;
}

// Manual Mock for firebase_auth.User
class MockFirebaseAuthUser extends Mock implements FirebaseAuth.User {
  final String _uid;
  final String? _email;

  MockFirebaseAuthUser({String uid = 'test_uid', String? email = 'test@example.com'}) : _uid = uid, _email = email;

  @override
  String get uid => _uid;

  @override
  String? get email => _email;
  // Add other properties if your tests/code rely on them
}

void main() {
  late AuthProvider authProvider;
  late MockAuthService mockAuthService;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockAuthService = MockAuthService();
    fakeFirestore = FakeFirebaseFirestore();
    // The AuthProvider takes the AuthService and FirebaseFirestore instance directly.
    // We need to modify AuthProvider to allow injecting these for testing,
    // or find another way to provide the fake/mock instances.
    // For now, let's assume AuthProvider can be modified or uses a global instance
    // that can be replaced. The original AuthProvider uses:
    // final AuthService _authService = AuthService();
    // final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    // This makes it hard to test. I will proceed assuming direct injection is possible.
    // If not, this test setup will need to change based on AuthProvider's actual structure.

    // Re-instantiate AuthProvider with mocks. This requires AuthProvider to be refactored
    // to accept AuthService and FirebaseFirestore in its constructor.
    // e.g. AuthProvider(this._authService, this._firestore);
    // For this test, I will *temporarily* modify AuthProvider's structure in my mental model
    // to allow this, and note that this is a required refactor for testability.
    authProvider = AuthProvider(authService: mockAuthService, firestore: fakeFirestore);
  });

  tearDown(() {
    mockAuthService.closeStream();
    authProvider.dispose();
  });

  group('AuthProvider Unit Tests', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';

    group('signUp', () {
      test('calls authService.signUp with correct parameters and fetches user details', () async {
        final mockUser = MockFirebaseAuthUser(uid: 'new_user_uid');
        final mockUserCredential = MockUserCredential();
        when(mockUserCredential.user).thenReturn(mockUser);
        when(mockAuthService.signUp(testEmail, testPassword, true))
            .thenAnswer((_) async => mockUserCredential);

        // Add user data to fake Firestore for _fetchUserDetails
        await fakeFirestore.collection('users').doc(mockUser.uid).set({
          'email': testEmail,
          'isDoctor': true,
          'name': 'Dr. Test',
        });

        await authProvider.signUp(testEmail, testPassword, true);

        verify(mockAuthService.signUp(testEmail, testPassword, true)).called(1);

        // Wait for events to propagate, including _fetchUserDetails triggered by authStateChanges
        // This needs authStateChanges to emit the new user from signUp
        mockAuthService.emitAuthState(mockUser);
        await Future.delayed(Duration.zero); // Allow microtasks to complete

        expect(authProvider.userDetails, isNotNull);
        expect(authProvider.userDetails!.uid, mockUser.uid);
        expect(authProvider.isDoctor, isTrue);
      });
    });

    group('_fetchUserDetails and isDoctor status', () {
      test('isDoctor is true when Firestore user is a doctor', () async {
        final testUser = MockFirebaseAuthUser(uid: 'doctor_uid');
        await fakeFirestore.collection('users').doc(testUser.uid).set({
          'email': 'doctor@example.com',
          'isDoctor': true,
          'name': 'Dr. Doe',
        });

        mockAuthService.emitAuthState(testUser); // Simulate user login
        await Future.delayed(Duration.zero); // Process the stream event

        expect(authProvider.isDoctor, isTrue);
        expect(authProvider.userDetails, isNotNull);
        expect(authProvider.userDetails!.uid, 'doctor_uid');
      });

      test('isDoctor is false when Firestore user is not a doctor', () async {
        final testUser = MockFirebaseAuthUser(uid: 'patient_uid');
        await fakeFirestore.collection('users').doc(testUser.uid).set({
          'email': 'patient@example.com',
          'isDoctor': false,
          'name': 'Patient Pat',
        });

        mockAuthService.emitAuthState(testUser);
        await Future.delayed(Duration.zero);

        expect(authProvider.isDoctor, isFalse);
        expect(authProvider.userDetails, isNotNull);
      });

      test('isDoctor is false and userDetails is null if user document not found', () async {
        final testUser = MockFirebaseAuthUser(uid: 'not_found_uid');

        mockAuthService.emitAuthState(testUser);
        await Future.delayed(Duration.zero);

        expect(authProvider.isDoctor, isFalse);
        expect(authProvider.userDetails, isNull);
      });

      test('isDoctor is false and userDetails is null when no user is logged in', () async {
        mockAuthService.emitAuthState(null); // Simulate logout
        await Future.delayed(Duration.zero);

        expect(authProvider.isDoctor, isFalse);
        expect(authProvider.userDetails, isNull);
        expect(authProvider.firebaseUser, isNull);
      });
    });

     group('SignOut', () {
      test('clears userDetails and firebaseUser on signOut', () async {
        // Simulate a logged-in user first
        final testUser = MockFirebaseAuthUser(uid: 'test_uid');
        await fakeFirestore.collection('users').doc(testUser.uid).set({'email': 'test@example.com', 'isDoctor': false});
        mockAuthService.emitAuthState(testUser);
        await Future.delayed(Duration.zero); // Process login

        expect(authProvider.firebaseUser, isNotNull);
        expect(authProvider.userDetails, isNotNull);

        // Mock signOut in AuthService and then call it in AuthProvider
        when(mockAuthService.signOut()).thenAnswer((_) async {});

        await authProvider.signOut(); // This should trigger authStateChanges with null
        mockAuthService.emitAuthState(null); // Simulate the effect of signOut on authStateChanges
        await Future.delayed(Duration.zero); // Process stream event

        verify(mockAuthService.signOut()).called(1);
        expect(authProvider.firebaseUser, isNull);
        expect(authProvider.userDetails, isNull);
        expect(authProvider.isDoctor, isFalse);
      });
    });
  });
}

// NOTE: This test suite assumes AuthProvider has been refactored
// to allow injection of AuthService and FirebaseFirestore instances.
// Example:
// class AuthProvider extends ChangeNotifier {
//   final AuthService _authService;
//   final FirebaseFirestore _firestore;
//   FirebaseAuth.User? _firebaseUser;
//   UserModel.User? _userDetails;

//   AuthProvider({AuthService? authService, FirebaseFirestore? firestore})
//       : _authService = authService ?? AuthService(),
//         _firestore = firestore ?? FirebaseFirestore.instance {
//     _listenToAuthChanges();
//   }
//   // ... rest of the class
// }
// The actual AuthProvider uses:
// final AuthService _authService = AuthService();
// final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// This needs to be changed for these tests to pass as written.
// The original AuthProvider also initializes the listener in its constructor.
// The provided mockAuthService.emitAuthState() simulates this for testing.
