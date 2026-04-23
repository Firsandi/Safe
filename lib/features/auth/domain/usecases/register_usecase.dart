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
      name: params.name,
      phoneNumber: params.phoneNumber,
      email: params.email,
      password: params.password,
      bloodType: params.bloodType,
      medicalNotes: params.medicalNotes,
    );
  }
}

class RegisterParams {
  final String name;
  final String phoneNumber;
  final String email;
  final String password;
  final String? bloodType;
  final String? medicalNotes;

  RegisterParams({
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.password,
    this.bloodType,
    this.medicalNotes,
  });
}