import 'package:dartz/dartz.dart';
import 'package:safe/core/error/failure.dart';
import 'package:safe/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password, {String? deviceToken});
  Future<Either<Failure, UserEntity>> verifyLoginOtp(String email, String otp);

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
    String? bloodType,
    String? medicalNotes,
  });

  Future<Either<Failure, void>> forgotPassword(String email);
  Future<Either<Failure, void>> verifyResetOtp(String email, String otp);
  Future<Either<Failure, void>> resetPassword(String email, String otp, String newPassword);
}