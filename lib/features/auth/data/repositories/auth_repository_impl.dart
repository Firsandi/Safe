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
  Future<Either<Failure, UserEntity>> login(String email, String password, {String? deviceToken}) async {
    try {
      final remoteUser = await remoteDataSource.login(email, password, deviceToken: deviceToken);
      return Right(remoteUser);
    } on OtpRequiredException catch (e) {
      return Left(OtpRequiredFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unknown error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> verifyLoginOtp(String email, String otp) async {
    try {
      final remoteUser = await remoteDataSource.verifyLoginOtp(email, otp);
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

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await remoteDataSource.forgotPassword(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unknown error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyResetOtp(String email, String otp) async {
    try {
      await remoteDataSource.verifyResetOtp(email, otp);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unknown error occurred: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email, String otp, String newPassword) async {
    try {
      await remoteDataSource.resetPassword(email, otp, newPassword);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unknown error occurred: $e'));
    }
  }
}
