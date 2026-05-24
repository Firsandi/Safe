import 'package:dio/dio.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/error/dio_error_handler.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);

  Future<UserModel> register({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
    String? bloodType,
    String? medicalNotes,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/api/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['token'] as String?;
      return UserModel.fromJson(response.data['user'], token: token);
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    } catch (e) {
      throw ServerException('Gagal login. Silakan coba lagi.');
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
}
