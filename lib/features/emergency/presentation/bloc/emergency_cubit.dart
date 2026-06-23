import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/contact_entity.dart';
import '../../domain/usecases/emergency_usecases.dart';
import '../../../../core/usecase/usecase.dart';

abstract class EmergencyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EmergencyInitial extends EmergencyState {}
class EmergencyLoading extends EmergencyState {}
class EmergencyLoaded extends EmergencyState {
  final List<ContactEntity> contacts;
  final List<ContactEntity> requests;
  EmergencyLoaded({required this.contacts, required this.requests});
  @override
  List<Object?> get props => [contacts, requests];
}
class EmergencyError extends EmergencyState {
  final String message;
  EmergencyError(this.message);
  @override
  List<Object?> get props => [message];
}

class EmergencySearchLoading extends EmergencyState {}
class EmergencySearchSuccess extends EmergencyState {
  final List<ContactEntity> users;
  EmergencySearchSuccess(this.users);
  @override
  List<Object?> get props => [users];
}

class EmergencyCubit extends Cubit<EmergencyState> {
  final GetContactsUseCase getContactsUseCase;
  final GetPendingRequestsUseCase getPendingRequestsUseCase;
  final SearchUserUseCase searchUserUseCase;
  final AddContactUseCase addContactUseCase;
  final AcceptRequestUseCase acceptRequestUseCase;
  final RejectRequestUseCase rejectRequestUseCase;
  final DeleteContactUseCase deleteContactUseCase;

  EmergencyCubit({
    required this.getContactsUseCase,
    required this.getPendingRequestsUseCase,
    required this.searchUserUseCase,
    required this.addContactUseCase,
    required this.acceptRequestUseCase,
    required this.rejectRequestUseCase,
    required this.deleteContactUseCase,
  }) : super(EmergencyInitial());

  Future<void> loadContacts() async {
    emit(EmergencyLoading());
    final contactsResult = await getContactsUseCase(NoParams());
    final requestsResult = await getPendingRequestsUseCase(NoParams());

    contactsResult.fold(
      (failure) => emit(EmergencyError(failure.message)),
      (contacts) {
        requestsResult.fold(
          (failure) => emit(EmergencyError(failure.message)),
          (requests) => emit(EmergencyLoaded(contacts: contacts, requests: requests)),
        );
      },
    );
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      emit(EmergencyInitial());
      return;
    }
    emit(EmergencySearchLoading());
    final result = await searchUserUseCase(query);
    result.fold(
      (failure) => emit(EmergencyError(failure.message)),
      (users) => emit(EmergencySearchSuccess(users)),
    );
  }

  Future<void> addContact(String userId, String name, String phoneNumber) async {
    final result = await addContactUseCase(AddContactParams(
      userId: userId,
      name: name,
      phoneNumber: phoneNumber,
    ));
    result.fold(
      (failure) => emit(EmergencyError(failure.message)),
      (_) => loadContacts(),
    );
  }

  Future<void> acceptRequest(String requestId) async {
    final result = await acceptRequestUseCase(requestId);
    result.fold(
      (failure) => emit(EmergencyError(failure.message)),
      (_) => loadContacts(),
    );
  }

  Future<void> rejectRequest(String requestId) async {
    final result = await rejectRequestUseCase(requestId);
    result.fold(
      (failure) => emit(EmergencyError(failure.message)),
      (_) => loadContacts(),
    );
  }

  Future<void> deleteContact(String contactId) async {
    final result = await deleteContactUseCase(contactId);
    result.fold(
      (failure) => emit(EmergencyError(failure.message)),
      (_) => loadContacts(),
    );
  }
}
