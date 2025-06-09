import 'package:book/models/user.dart' as UserModel;
import 'package:book/services/auth_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Manual Mock for FirebaseAuth
class MockFirebaseAuth extends Mock implements FirebaseAuth.FirebaseAuth {
  @override
  Future<FirebaseAuth.UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return super.noSuchMethod(
      Invocation.method(#createUserWithEmailAndPassword, [], {#email: email, #password: password}),
      returnValue: Future.value(MockUserCredential(email: email)), // Return a mock UserCredential
      returnValueForMissingStub: Future.value(MockUserCredential(email: email)),
    ) as Future<FirebaseAuth.UserCredential>;
  }

  // Mock other FirebaseAuth methods if needed by AuthService for other tests
}

// Manual Mock for UserCredential (can be shared or defined per test file)
class MockUserCredential extends Mock implements FirebaseAuth.UserCredential {
  final MockFirebaseAuthUser _user;

  MockUserCredential({String uid = 'test_uid', String? email = 'default@example.com'})
      : _user = MockFirebaseAuthUser(uid: uid, email: email);

  @override
  FirebaseAuth.User? get user => _user;
}

// Manual Mock for firebase_auth.User (can be shared or defined per test file)
class MockFirebaseAuthUser extends Mock implements FirebaseAuth.User {
  final String _uid;
  final String? _email;

  MockFirebaseAuthUser({required String uid, String? email}) : _uid = uid, _email = email;

  @override
  String get uid => _uid;

  @override
  String? get email => _email;
  // Add other properties if your tests/code rely on them
}


void main() {
  late AuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;
  late FakeFirebaseFirestore fakeFirestore;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    fakeFirestore = FakeFirebaseFirestore();
    // To test AuthService, we need to inject its dependencies (FirebaseAuth, FirebaseFirestore)
    // This requires AuthService to be refactored to accept these in its constructor.
    // e.g. AuthService(this._auth, this._firestore);
    // Similar to AuthProvider, I'm proceeding with the assumption this refactor is done.
    authService = AuthService(auth: mockFirebaseAuth, firestore: fakeFirestore);
  });

  group('AuthService Unit Tests', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testUid = 'test_user_123';

    group('signUp', () {
      test('calls FirebaseAuth.createUserWithEmailAndPassword and creates user document in Firestore', () async {
        // Arrange
        final mockFbUser = MockFirebaseAuthUser(uid: testUid, email: testEmail);
        final mockUserCredential = MockUserCredential(uid: testUid, email: testEmail);

        when(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockUserCredential);

        // Act
        await authService.signUp(testEmail, testPassword, true); // isDoctor: true

        // Assert
        // 1. Verify createUserWithEmailAndPassword was called
        verify(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword)).called(1);

        // 2. Verify Firestore document creation
        final docSnapshot = await fakeFirestore.collection('users').doc(testUid).get();
        expect(docSnapshot.exists, isTrue);
        expect(docSnapshot.data()?['email'], testEmail);
        expect(docSnapshot.data()?['isDoctor'], true);
        expect(docSnapshot.data()?['uid'], isNull); // UID is doc ID, not in fields for this model
        expect(docSnapshot.data()?['name'], isNull); // Name is optional
      });

      test('creates user document with isDoctor: false correctly', () async {
        // Arrange
        final mockFbUser = MockFirebaseAuthUser(uid: 'patient_uid', email: 'patient@example.com');
         final mockUserCredential = MockUserCredential(uid: 'patient_uid', email: 'patient@example.com');

        when(mockFirebaseAuth.createUserWithEmailAndPassword(email: 'patient@example.com', password: testPassword))
            .thenAnswer((_) async => mockUserCredential);

        // Act
        await authService.signUp('patient@example.com', testPassword, false); // isDoctor: false

        // Assert
        final docSnapshot = await fakeFirestore.collection('users').doc('patient_uid').get();
        expect(docSnapshot.exists, isTrue);
        expect(docSnapshot.data()?['email'], 'patient@example.com');
        expect(docSnapshot.data()?['isDoctor'], false);
      });

       test('returns UserCredential on successful sign up', () async {
        final mockUserCredential = MockUserCredential(uid: testUid, email: testEmail);
        when(mockFirebaseAuth.createUserWithEmailAndPassword(email: testEmail, password: testPassword))
            .thenAnswer((_) async => mockUserCredential);

        final result = await authService.signUp(testEmail, testPassword, true);

        expect(result, isA<FirebaseAuth.UserCredential>());
        expect(result.user?.uid, testUid);
      });

      test('propagates FirebaseAuthException on createUserWithEmailAndPassword failure', () async {
        when(mockFirebaseAuth.createUserWithEmailAndPassword(email: anyNamed('email'), password: anyNamed('password')))
            .thenThrow(FirebaseAuth.FirebaseAuthException(code: 'email-already-in-use'));

        expect(
          () => authService.signUp('bad@example.com', 'password', false),
          throwsA(isA<FirebaseAuth.FirebaseAuthException>()),
        );

        // Ensure no document is created in Firestore on failure
        final docSnapshot = await fakeFirestore.collection('users').doc(testUid).get();
        expect(docSnapshot.exists, isFalse);
      });
    });
  });
}

// NOTE: This test suite assumes AuthService has been refactored
// to allow injection of FirebaseAuth and FirebaseFirestore instances.
// Example:
// class AuthService {
//   final FirebaseAuth _auth;
//   final FirebaseFirestore _firestore;

//   AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
//       : _auth = auth ?? FirebaseAuth.instance,
//         _firestore = firestore ?? FirebaseFirestore.instance;
//   // ... rest of the class
// }
// The actual AuthService uses:
// final FirebaseAuth _auth = FirebaseAuth.instance;
// final FirebaseFirestore _firestore = FirebaseFirestore.instance;
// This needs to be changed for these tests to pass as written.
