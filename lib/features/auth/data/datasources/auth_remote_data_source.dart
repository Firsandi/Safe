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
        'https://api.kamu.com/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException('Ditolak backend: Gagal login dari server');
      }
    } catch (e) {
      throw ServerException(e.toString());
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
        'https://api.kamu.com/register',
        data: {
          'nama': nama,
          'nomor_hp': nomorHp,
          'email': email,
          'password': password,
          'blood_type': golDarah,
          'medical_notes': catatanMedis,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(response.data);
      } else {
        throw ServerException('Gagal mendaftarkan akun dari server');
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
