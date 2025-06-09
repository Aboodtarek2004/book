import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final List<User> _registeredUsers = [];
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void register(String username, String password, String name) {
    _registeredUsers.add(User(username: username, password: password, name: name));
    notifyListeners();
  }

  bool login(String username, String password) {
    try {
      final user = _registeredUsers.firstWhere(
        (u) => u.username == username && u.password == password,
      );
      _currentUser = user;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
