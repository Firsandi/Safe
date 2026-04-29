import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyToken = 'auth_token';
  static const String _keyUserData = 'user_data';

  /// Simpan session setelah login berhasil
  static Future<void> saveSession({
    required String token,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserData, jsonEncode(userData));
  }

  /// Cek apakah user sudah login
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyToken) && prefs.containsKey(_keyUserData);
  }

  /// Ambil data user yang tersimpan
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserData);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  /// Ambil token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  /// Hapus session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserData);
  }
}
