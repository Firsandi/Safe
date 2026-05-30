import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart'; 
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;
  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    return await repository.login(params.email, params.password, deviceToken: params.deviceToken);
  }
}

class LoginParams {
  final String email;
  final String password;
  final String? deviceToken;

  LoginParams({required this.email, required this.password, this.deviceToken});
}
