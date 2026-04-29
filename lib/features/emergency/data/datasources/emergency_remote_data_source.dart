import 'package:dio/dio.dart';
import '../../../../core/error/exception.dart';
import '../models/contact_model.dart';

abstract class EmergencyRemoteDataSource {
  Future<List<ContactModel>> getContacts();
  Future<List<ContactModel>> getPendingRequests();
  Future<List<ContactModel>> searchUsers(String query);
  Future<void> addContact(String userId, String name, String phoneNumber);
  Future<void> acceptRequest(String requestId);
  Future<void> rejectRequest(String requestId);
}

class EmergencyRemoteDataSourceImpl implements EmergencyRemoteDataSource {
  final Dio dio;

  EmergencyRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ContactModel>> getContacts() async {
    try {
      final response = await dio.get('/api/contacts');
      return (response.data['contacts'] as List)
          .map((json) => ContactModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data['error'] ?? 'Server error (GetContacts)');
    }
  }

  @override
  Future<List<ContactModel>> getPendingRequests() async {
    try {
      final response = await dio.get('/api/contacts/requests');
      return (response.data['requests'] as List)
          .map((json) => ContactModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data['error'] ?? 'Server error (GetRequests)');
    }
  }

  @override
  Future<List<ContactModel>> searchUsers(String query) async {
    try {
      final response = await dio.get('/api/users/search', queryParameters: {'q': query});
      return (response.data['users'] as List)
          .map((json) => ContactModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw ServerException(e.response?.data['error'] ?? 'Server error (SearchUsers)');
    }
  }

  @override
  Future<void> addContact(String userId, String name, String phoneNumber) async {
    try {
      await dio.post('/api/contacts', data: {
        'target_user_id': userId,
        'contact_name': name,
        'phone_number': phoneNumber,
      });
    } on DioException catch (e) {
      throw ServerException(e.response?.data['error'] ?? 'Server error (AddContact)');
    }
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    try {
      await dio.post('/api/contacts/requests/$requestId/accept');
    } on DioException catch (e) {
      throw ServerException(e.response?.data['error'] ?? 'Server error (AcceptRequest)');
    }
  }

  @override
  Future<void> rejectRequest(String requestId) async {
    try {
      await dio.post('/api/contacts/requests/$requestId/reject');
    } on DioException catch (e) {
      throw ServerException(e.response?.data['error'] ?? 'Server error (RejectRequest)');
    }
  }
}
