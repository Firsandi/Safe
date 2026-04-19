import 'package:dio/dio.dart';
import '../../../../core/error/exception.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);

  Future<UserModel> register({
    required String nama,
    required String nomorHp,
    required String email,
    required String password,
    String? golDarah,
    String? catatanMedis,
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
      final message = e.response?.data['error'] ?? 'Terjadi kesalahan pada server (Login)';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Gagal Login: $e');
    }
  }

  @override
  Future<UserModel> register({
    required String nama,
    required String nomorHp,
    required String email,
    required String password,
    String? golDarah,
    String? catatanMedis,
  }) async {
    try {
      final response = await dio.post(
        '/api/register',
        data: {
          'nama': nama,
          'nomor_hp': nomorHp,
          'email': email,
          'password': password,
          'gol_darah': golDarah,
          'catatan_medis': catatanMedis,
        },
      );

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      final message = e.response?.data['error'] ?? 'Terjadi kesalahan pada server (Register)';
      throw ServerException(message);
    } catch (e) {
      throw ServerException('Gagal Registrasi: $e');
    }
  }
}
