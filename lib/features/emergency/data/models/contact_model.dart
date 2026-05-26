import '../../domain/entities/contact_entity.dart';

class ContactModel extends ContactEntity {
  const ContactModel({
    required super.id,
    super.userId,
    required super.name,
    required super.phoneNumber,
    super.profileImage,
    required super.status,
    super.lastLatitude,
    super.lastLongitude,
    super.lastLocationUpdate,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'].toString(),
      userId: json['user_id']?.toString(),
      name: json['name'],
      phoneNumber: json['phone_number'],
      profileImage: json['profile_image'],
      status: json['status'] ?? 'Tersambung',
      lastLatitude: json['last_latitude'] != null ? (json['last_latitude'] as num).toDouble() : null,
      lastLongitude: json['last_longitude'] != null ? (json['last_longitude'] as num).toDouble() : null,
      lastLocationUpdate: json['last_location_update'] != null ? DateTime.parse(json['last_location_update']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'status': status,
      'last_latitude': lastLatitude,
      'last_longitude': lastLongitude,
      'last_location_update': lastLocationUpdate?.toIso8601String(),
    };
  }
}
