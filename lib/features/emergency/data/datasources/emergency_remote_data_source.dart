import 'package:dio/dio.dart';
import '../../../../core/error/exception.dart';
import '../../../../core/error/dio_error_handler.dart';
import '../models/contact_model.dart';

abstract class EmergencyRemoteDataSource {
  Future<List<ContactModel>> getContacts();
  Future<List<ContactModel>> getPendingRequests();
  Future<List<ContactModel>> searchUsers(String query);
  Future<void> addContact(String userId, String name, String phoneNumber);
  Future<void> acceptRequest(String requestId);
  Future<void> rejectRequest(String requestId);
  Future<void> deleteContact(String contactId);
}

class EmergencyRemoteDataSourceImpl implements EmergencyRemoteDataSource {
  final Dio dio;

  EmergencyRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ContactModel>> getContacts() async {
    try {
      final response = await dio.get('/api/contacts');
      final list = response.data['contacts'] as List?;
      if (list == null) return [];
      return list.map((json) => ContactModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    }
  }

  @override
  Future<List<ContactModel>> getPendingRequests() async {
    try {
      final response = await dio.get('/api/contacts/requests');
      final list = response.data['requests'] as List?;
      if (list == null) return [];
      return list.map((json) => ContactModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    }
  }

  @override
  Future<List<ContactModel>> searchUsers(String query) async {
    try {
      final response = await dio.get('/api/users/search', queryParameters: {'q': query});
      final list = response.data['users'] as List?;
      if (list == null) return [];
      return list.map((json) => ContactModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
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
      throw ServerException(DioErrorHandler.getMessage(e));
    }
  }

  @override
  Future<void> acceptRequest(String requestId) async {
    try {
      await dio.post('/api/contacts/requests/$requestId/accept');
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    }
  }

  @override
  Future<void> rejectRequest(String requestId) async {
    try {
      await dio.post('/api/contacts/requests/$requestId/reject');
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    }
  }

  @override
  Future<void> deleteContact(String contactId) async {
    try {
      await dio.delete('/api/contacts/$contactId');
    } on DioException catch (e) {
      throw ServerException(DioErrorHandler.getMessage(e));
    }
  }
}
