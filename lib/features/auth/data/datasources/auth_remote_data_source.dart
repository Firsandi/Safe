import 'package:dio/dio.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/error/dio_error_handler.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password, {String? deviceToken});
  Future<UserModel> verifyLoginOtp(String email, String otp);

  Future<UserModel> register({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
    String? bloodType,
    String? medicalNotes,
  });

  Future<void> forgotPassword(String email);
  Future<void> verifyResetOtp(String email, String otp);
  Future<void> resetPassword(String email, String otp, String newPassword);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login(String email, String password, {String? deviceToken}) async {
    try {
      final response = await dio.post(
        '/api/login',
        data: {
          'email': email,
          'password': password,
          if (deviceToken != null) 'device_token': deviceToken,
        },
      );

      if (response.data['require_otp'] == true) {
        throw OtpRequiredException(response.data['message'] ?? 'OTP diperlukan');
      }

      final token = response.data['token'] as String?;
      return UserModel.fromJson(response.data['user'], token: token);
    } on OtpRequiredException {
      rethrow;
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    } catch (e) {
      throw ServerException('Gagal login. Silakan coba lagi.');
    }
  }

  @override
  Future<UserModel> verifyLoginOtp(String email, String otp) async {
    try {
      final response = await dio.post(
        '/api/verify-login-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );

      final token = response.data['token'] as String?;
      final deviceToken = response.data['device_token'] as String?;
      
      final userData = Map<String, dynamic>.from(response.data['user']);
      if (deviceToken != null) {
        userData['device_token'] = deviceToken;
      }
      
      return UserModel.fromJson(userData, token: token);
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    } catch (e) {
      throw ServerException('Gagal memverifikasi OTP.');
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
    String? bloodType,
    String? medicalNotes,
  }) async {
    try {
      final response = await dio.post(
        '/api/register',
        data: {
          'name': name,
          'phone_number': phoneNumber,
          'email': email,
          'password': password,
          'blood_type': bloodType,
          'medical_notes': medicalNotes,
        },
      );

      final token = response.data['token'] as String?;
      return UserModel.fromJson(response.data['user'], token: token);
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    } catch (e) {
      throw ServerException('Gagal mendaftar. Periksa koneksi internet Anda.');
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await dio.post(
        '/api/forgot-password',
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    } catch (e) {
      throw ServerException('Gagal memproses permintaan lupa password.');
    }
  }

  @override
  Future<void> verifyResetOtp(String email, String otp) async {
    try {
      await dio.post(
        '/api/verify-reset-otp',
        data: {
          'email': email,
          'otp': otp,
        },
      );
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    } catch (e) {
      throw ServerException('Gagal memverifikasi OTP.');
    }
  }

  @override
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    try {
      await dio.post(
        '/api/reset-password',
        data: {
          'email': email,
          'otp': otp,
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    } catch (e) {
      throw ServerException('Gagal mereset password.');
    }
  }
}

