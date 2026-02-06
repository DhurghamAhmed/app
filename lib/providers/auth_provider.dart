import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  UserModel? _userModel;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;
  StreamSubscription<User?>? _authSubscription;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get userId => _user?.uid;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Listen to auth state changes
      _authSubscription = _authService.authStateChanges.listen(
        (user) async {
          _user = user;
          if (user != null) {
            try {
              _userModel = await _authService.getUserData(user.uid);
            } catch (e) {
              debugPrint('Error fetching user data: $e');
              // Create a basic user model from Firebase Auth user
              _userModel = UserModel(
                id: user.uid,
                fullName: user.displayName ?? 'User',
                email: user.email ?? '',
                createdAt: DateTime.now(),
              );
            }
          } else {
            _userModel = null;
          }
          _isInitialized = true;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Auth state error: $error');
          _error = error.toString();
          _isInitialized = true;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      _error = e.toString();
      _isInitialized = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Handle Pigeon type cast errors gracefully
      final errorStr = e.toString();
      if (errorStr.contains('type') && errorStr.contains('subtype')) {
        // This is likely a Pigeon serialization error, but auth might have succeeded
        // Check if user is now authenticated
        await Future.delayed(const Duration(milliseconds: 500));
        if (_authService.currentUser != null) {
          _user = _authService.currentUser;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
      _error = _parseErrorMessage(errorStr);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _userModel = null;
    } catch (e) {
      _error = _parseErrorMessage(e.toString());
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getAuthErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = _parseErrorMessage(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseErrorMessage(String error) {
    // Handle Pigeon type cast errors
    if (error.contains('type') && error.contains('subtype')) {
      return 'An unexpected error occurred. Please try again.';
    }
    // Remove exception prefix
    if (error.startsWith('Exception: ')) {
      return error.substring(11);
    }
    return error;
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
