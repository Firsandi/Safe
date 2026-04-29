import '../../domain/entities/contact_entity.dart';

class ContactModel extends ContactEntity {
  const ContactModel({
    required super.id,
    required super.name,
    required super.phoneNumber,
    super.profileImage,
    required super.status,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'].toString(),
      name: json['name'],
      phoneNumber: json['phone_number'],
      profileImage: json['profile_image'],
      status: json['status'] ?? 'Tersambung',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'profile_image': profileImage,
      'status': status,
    };
  }
}
