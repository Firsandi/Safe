import 'package:dartz/dartz.dart';
import 'package:safe/core/error/failure.dart';
import 'package:safe/features/auth/domain/repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  final AuthRepository repository;

  ForgotPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String email) {
    return repository.forgotPassword(email);
  }
}

class VerifyResetOtpUseCase {
  final AuthRepository repository;

  VerifyResetOtpUseCase(this.repository);

  Future<Either<Failure, void>> call(String email, String otp) {
    return repository.verifyResetOtp(email, otp);
  }
}

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String email, String otp, String newPassword) {
    return repository.resetPassword(email, otp, newPassword);
  }
}
