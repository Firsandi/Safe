import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/contact_entity.dart';

abstract class EmergencyRepository {
  Future<Either<Failure, List<ContactEntity>>> getContacts();
  Future<Either<Failure, List<ContactEntity>>> getPendingRequests();
  Future<Either<Failure, List<ContactEntity>>> searchUsers(String query);
  Future<Either<Failure, void>> addContact(String userId, String name, String phoneNumber);
  Future<Either<Failure, void>> acceptRequest(String requestId);
  Future<Either<Failure, void>> rejectRequest(String requestId);
}
