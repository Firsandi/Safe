import 'package:dartz/dartz.dart';
import 'package:safe/core/error/failure.dart';
import 'package:safe/core/usecase/usecase.dart';
import 'package:safe/features/auth/domain/entities/user_entity.dart';
import 'package:safe/features/auth/domain/repositories/auth_repository.dart';

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) async {
    return await repository.register(
      nama: params.nama,
      nomorHp: params.nomorHp,
      email: params.email,
      password: params.password,
      golDarah: params.golDarah,
      catatanMedis: params.catatanMedis,
    );
  }
}

class RegisterParams {
  final String nama;
  final String nomorHp;
  final String email;
  final String password;
  final String? golDarah;
  final String? catatanMedis;

  RegisterParams({
    required this.nama,
    required this.nomorHp,
    required this.email,
    required this.password,
    this.golDarah,
    this.catatanMedis,
  });
}