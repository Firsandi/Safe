import 'package:dartz/dartz.dart'; 
import 'package:safe/core/error/exception.dart';
import 'package:safe/core/error/failure.dart';
import 'package:safe/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:safe/features/auth/domain/entities/user_entity.dart';
import 'package:safe/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserEntity>> login(String email, String password) async {
    try {
      final remoteUser = await remoteDataSource.login(email, password);
      return Right(remoteUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unknown error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String phoneNumber,
    required String email,
    required String password,
    String? bloodType,
    String? medicalNotes,
  }) async {
    try {
      final remoteUser = await remoteDataSource.register(
        name: name,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        bloodType: bloodType,
        medicalNotes: medicalNotes,
      );

      return Right(remoteUser);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Registration failed: Connection or server issue.'));
    }
  }
}
