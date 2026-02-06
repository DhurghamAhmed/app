import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _autoCleanupKey = 'auto_cleanup_enabled';
  static const String _limitTransactionsKey = 'limit_transactions_enabled';
  static const String _maxTransactionsKey = 'max_transactions_count';

  bool _autoCleanupEnabled = true; // Default: enabled
  bool _limitTransactionsEnabled = false; // Default: disabled
  int _maxTransactionsCount = 30; // Default: 30
  bool _isLoading = true;

  bool get autoCleanupEnabled => _autoCleanupEnabled;
  bool get limitTransactionsEnabled => _limitTransactionsEnabled;
  int get maxTransactionsCount => _maxTransactionsCount;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoCleanupEnabled = prefs.getBool(_autoCleanupKey) ?? true;
      _limitTransactionsEnabled = prefs.getBool(_limitTransactionsKey) ?? false;
      _maxTransactionsCount = prefs.getInt(_maxTransactionsKey) ?? 30;
    } catch (e) {
      debugPrint('Error loading settings: $e');
      _autoCleanupEnabled = true;
      _limitTransactionsEnabled = false;
      _maxTransactionsCount = 30;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setAutoCleanupEnabled(bool value) async {
    if (_autoCleanupEnabled == value) return;

    _autoCleanupEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoCleanupKey, value);
      debugPrint('Auto cleanup setting saved: $value');
    } catch (e) {
      debugPrint('Error saving auto cleanup setting: $e');
    }
  }

  Future<void> toggleAutoCleanup() async {
    await setAutoCleanupEnabled(!_autoCleanupEnabled);
  }

  Future<void> setLimitTransactionsEnabled(bool value) async {
    if (_limitTransactionsEnabled == value) return;

    _limitTransactionsEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_limitTransactionsKey, value);
      debugPrint('Limit transactions setting saved: $value');
    } catch (e) {
      debugPrint('Error saving limit transactions setting: $e');
    }
  }

  Future<void> setMaxTransactionsCount(int value) async {
    if (_maxTransactionsCount == value) return;

    _maxTransactionsCount = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_maxTransactionsKey, value);
      debugPrint('Max transactions count saved: $value');
    } catch (e) {
      debugPrint('Error saving max transactions count: $e');
    }
  }

  Future<void> toggleLimitTransactions() async {
    await setLimitTransactionsEnabled(!_limitTransactionsEnabled);
  }
}
