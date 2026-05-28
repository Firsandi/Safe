import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'injection.dart';
import 'session_manager.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../theme/app_colors.dart';
import '../services/notification_manager.dart';

class GoogleAuthHelper {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
    }
  }

  /// Triggers Google Authentication
  static Future<void> signIn(BuildContext context) async {
    try {
      await _googleSignIn.signOut();

      // 1. Try real Google Sign-In on the device
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final String? idToken = googleAuth.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw PlatformException(
            code: 'missing_id_token',
            message: 'Token Google tidak tersedia. Periksa konfigurasi OAuth/SHA-1 aplikasi.',
          );
        }
        
        // Authenticated successfully with a real device account
        if (context.mounted) {
          await _processBackendAuth(
            context: context,
            email: googleUser.email,
            name: googleUser.displayName ?? 'Google User',
            idToken: idToken,
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint('Real Google Sign-In platform exception: ${e.message} (code: ${e.code})');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal masuk dengan Google: ${e.message ?? e.code}'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    } catch (e) {
      debugPrint('Real Google Sign-In general exception: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal masuk dengan Google: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  /// Processes authentication (either Login or Auto-Register) with the Go Backend
  static Future<void> _processBackendAuth({
    required BuildContext context,
    required String email,
    required String name,
    String? idToken,
  }) async {
    // Show a loading overlay dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      ),
    );

    final dio = sl<Dio>();

    try {
      // Send a single POST request to the custom Google Auth endpoint on Go Backend
      final response = await dio.post('/api/auth/google', data: {
        'id_token': idToken,
        'email': email,
        'name': name,
      });

      if (context.mounted) Navigator.pop(context); // Close loading indicator

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final token = responseData['token'] as String;
        final userMap = responseData['user'] as Map<String, dynamic>;

        final user = UserModel.fromJson(userMap);
        await SessionManager.saveSession(token: token, userData: userMap);
        NotificationManager.uploadFcmToken();

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage(user: user)),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // Close loading indicator
      await signOut();
      
      String errorMsg = 'Gagal masuk dengan Google untuk $email.';
      if (e is DioException) {
        errorMsg += ' Keterangan: ${e.response?.data?["error"] ?? e.message}';
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.primaryRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
