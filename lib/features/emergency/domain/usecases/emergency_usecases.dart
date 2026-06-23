import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/contact_entity.dart';
import '../repositories/emergency_repository.dart';

class GetContactsUseCase implements UseCase<List<ContactEntity>, NoParams> {
  final EmergencyRepository repository;
  GetContactsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ContactEntity>>> call(NoParams params) {
    return repository.getContacts();
  }
}

class GetPendingRequestsUseCase implements UseCase<List<ContactEntity>, NoParams> {
  final EmergencyRepository repository;
  GetPendingRequestsUseCase(this.repository);

  @override
  Future<Either<Failure, List<ContactEntity>>> call(NoParams params) {
    return repository.getPendingRequests();
  }
}

class SearchUserUseCase implements UseCase<List<ContactEntity>, String> {
  final EmergencyRepository repository;
  SearchUserUseCase(this.repository);

  @override
  Future<Either<Failure, List<ContactEntity>>> call(String query) {
    return repository.searchUsers(query);
  }
}

class AddContactParams {
  final String userId;
  final String name;
  final String phoneNumber;
  AddContactParams({required this.userId, required this.name, required this.phoneNumber});
}

class AddContactUseCase implements UseCase<void, AddContactParams> {
  final EmergencyRepository repository;
  AddContactUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddContactParams params) {
    return repository.addContact(params.userId, params.name, params.phoneNumber);
  }
}

class AcceptRequestUseCase implements UseCase<void, String> {
  final EmergencyRepository repository;
  AcceptRequestUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String requestId) {
    return repository.acceptRequest(requestId);
  }
}

class RejectRequestUseCase implements UseCase<void, String> {
  final EmergencyRepository repository;
  RejectRequestUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String requestId) {
    return repository.rejectRequest(requestId);
  }
}

class DeleteContactUseCase implements UseCase<void, String> {
  final EmergencyRepository repository;
  DeleteContactUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(String contactId) {
    return repository.deleteContact(contactId);
  }
}
