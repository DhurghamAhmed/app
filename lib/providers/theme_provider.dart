import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;
  String? _userId;

  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  // Initialize theme from Firebase
  Future<void> initializeTheme(String userId) async {
    _userId = userId;
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestore
          .collection('user_settings')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final themeString = data?['themeMode'] as String? ?? 'system';
        _themeMode = _parseThemeMode(themeString);
      } else {
        // Create default settings
        await _firestore.collection('user_settings').doc(userId).set({
          'themeMode': 'system',
          'createdAt': FieldValue.serverTimestamp(),
        });
        _themeMode = ThemeMode.system;
      }
    } catch (e) {
      debugPrint('Error loading theme: $e');
      _themeMode = ThemeMode.system;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Toggle theme mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }

  // Set specific theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    if (_userId != null) {
      try {
        await _firestore.collection('user_settings').doc(_userId).set({
          'themeMode': _themeModeToString(mode),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving theme: $e');
      }
    }
  }

  // Parse theme mode from string
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  // Convert theme mode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      default:
        return 'system';
    }
  }

  // Reset when user logs out
  void reset() {
    _userId = null;
    _themeMode = ThemeMode.system;
    _isLoading = true;
    notifyListeners();
  }
}
