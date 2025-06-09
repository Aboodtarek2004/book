import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User; // Hide Firebase User
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuth show User; // Import with prefix
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as UserModel; // Import with prefix

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final FirebaseFirestore _firestore;
  FirebaseAuth.User? _firebaseUser; // Renamed to avoid conflict
  UserModel.User? _userDetails; // To store user details including role

  FirebaseAuth.User? get firebaseUser => _firebaseUser; // Getter for Firebase User
  UserModel.User? get userDetails => _userDetails; // Getter for custom user model
  bool get isLoggedIn => _firebaseUser != null;
  bool get isDoctor => _userDetails?.isDoctor ?? false;

  AuthProvider({AuthService? authService, FirebaseFirestore? firestore})
      : _authService = authService ?? AuthService(),
        _firestore = firestore ?? FirebaseFirestore.instance {
    // Listen to authStateChanges from the provided _authService instance
    _authService.authStateChanges.listen((u) async {
      _firebaseUser = u;
      if (u != null) {
        await _fetchUserDetails(u);
      } else {
        _userDetails = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserDetails(FirebaseAuth.User firebaseUser) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        _userDetails = UserModel.User.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }
    } catch (e) {
      // Handle potential errors, e.g., network issues or user not found
      print('Error fetching user details: $e');
      _userDetails = null;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _authService.signIn(email, password);
    // User details will be fetched by the authStateChanges listener
  }

  Future<void> signUp(String email, String password, bool isDoctor) async {
    UserCredential userCredential = await _authService.signUp(email, password, isDoctor);
    if (userCredential.user != null) {
      // After sign up, user details are set in auth_service,
      // and authStateChanges listener in AuthProvider will call _fetchUserDetails.
      // However, to ensure isDoctor is available immediately for UI,
      // we can manually create a basic UserModel here or rely on the listener.
      // For simplicity, we'll rely on the listener which gets triggered by signUp.
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _userDetails = null; // Clear user details on sign out
  }
}
