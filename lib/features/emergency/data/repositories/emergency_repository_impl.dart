import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/exception.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/repositories/emergency_repository.dart';
import '../datasources/emergency_remote_data_source.dart';

class EmergencyRepositoryImpl implements EmergencyRepository {
  final EmergencyRemoteDataSource remoteDataSource;

  EmergencyRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<ContactEntity>>> getContacts() async {
    try {
      final contacts = await remoteDataSource.getContacts();
      return Right(contacts);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ContactEntity>>> getPendingRequests() async {
    try {
      final requests = await remoteDataSource.getPendingRequests();
      return Right(requests);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ContactEntity>>> searchUsers(String query) async {
    try {
      final users = await remoteDataSource.searchUsers(query);
      return Right(users);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> addContact(String userId, String name, String phoneNumber) async {
    try {
      await remoteDataSource.addContact(userId, name, phoneNumber);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> acceptRequest(String requestId) async {
    try {
      await remoteDataSource.acceptRequest(requestId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> rejectRequest(String requestId) async {
    try {
      await remoteDataSource.rejectRequest(requestId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
