import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class VerifyLoginOtpUseCase {
  final AuthRepository repository;
  VerifyLoginOtpUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call(String email, String otp) async {
    return await repository.verifyLoginOtp(email, otp);
  }
}
