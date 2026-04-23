import 'package:dio/dio.dart';
import '../../../../core/error/exception.dart';
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

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Server error (Login)';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Login failed: $e');
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

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Server error (Register)';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Registration failed: $e');
    }
  }
}
