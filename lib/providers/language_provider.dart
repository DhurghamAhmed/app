import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  
  Locale _locale = const Locale('en');
  bool _isLoading = true;
  String? _userId;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;
  bool get isArabic => _locale.languageCode == 'ar';
  bool get isEnglish => _locale.languageCode == 'en';
  String get languageCode => _locale.languageCode;
  String get languageName => isArabic ? 'العربية' : 'English';

  LanguageProvider() {
    _loadLanguage();
  }

  /// Load language from local storage
  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey) ?? 'en';
      _locale = Locale(languageCode);
    } catch (e) {
      debugPrint('Error loading language: $e');
      _locale = const Locale('en');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set user ID and load language preference from Firebase
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    if (userId != null) {
      await _loadLanguageFromFirebase(userId);
    }
  }

  /// Load language preference from Firebase
  Future<void> _loadLanguageFromFirebase(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final languageCode = data?['language'] as String?;
        if (languageCode != null && (languageCode == 'en' || languageCode == 'ar')) {
          _locale = Locale(languageCode);
          
          // Also save to local storage
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_languageKey, languageCode);
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading language from Firebase: $e');
    }
  }

  /// Change language and save to Firebase
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'en' && languageCode != 'ar') return;
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    notifyListeners();

    try {
      // Save to local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      // Save to Firebase if user is logged in
      if (_userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .set({
          'language': languageCode,
          'languageUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('Language saved to Firebase: $languageCode');
      }
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  /// Toggle between Arabic and English
  Future<void> toggleLanguage() async {
    final newLanguage = isArabic ? 'en' : 'ar';
    await setLanguage(newLanguage);
  }

  /// Set to Arabic
  Future<void> setArabic() async {
    await setLanguage('ar');
  }

  /// Set to English
  Future<void> setEnglish() async {
    await setLanguage('en');
  }
}