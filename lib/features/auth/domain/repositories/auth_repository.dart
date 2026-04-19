import 'package:dartz/dartz.dart';
import 'package:safe/core/error/failure.dart';
import 'package:safe/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);

  Future<Either<Failure, UserEntity>> register({
    required String nama,
    required String nomorHp,
    required String email,
    required String password,
    String? golDarah,
    String? catatanMedis,
  });
}