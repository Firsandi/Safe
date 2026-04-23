import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.userId,
    required super.email,
    required super.name,
    required super.phoneNumber,
    super.bloodType,
    super.medicalNotes,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? '',      
      email: json['email'] ?? '',    
      name: json['name'] ?? '',      
      phoneNumber: json['phone_number'] ?? '',
      bloodType: json['blood_type'],
      medicalNotes: json['medical_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'name': name,
      'phone_number': phoneNumber,
      'blood_type': bloodType,
      'medical_notes': medicalNotes,
    };
  }
}
