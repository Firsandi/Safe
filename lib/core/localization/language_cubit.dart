import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageCubit extends Cubit<Locale> {
  static const String _keyLanguage = 'language_code';

  LanguageCubit() : super(const Locale('id')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_keyLanguage) ?? 'id';
      emit(Locale(code));
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    emit(Locale(languageCode));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, languageCode);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }

  Future<void> toggleLanguage() async {
    final newCode = state.languageCode == 'id' ? 'en' : 'id';
    emit(Locale(newCode));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, newCode);
    } catch (e) {
      debugPrint('Error toggling language: $e');
    }
  }
}
