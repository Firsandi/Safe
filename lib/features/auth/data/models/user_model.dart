import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.user_id,
    required super.email,
    required super.nama,
    required super.nomorHp,
    super.golDarah,
    super.catatanMedis,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      user_id: json['id'] ?? '',      
      email: json['email'] ?? '',    
      nama: json['name'] ?? '',      
      nomorHp: json['phone'] ?? '',
      golDarah: json['blood_type'],
      catatanMedis: json['medical_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': user_id,
      'email': email,
      'name': nama,
      'phone': nomorHp,
      'blood_type': golDarah,
      'medical_notes': catatanMedis,
    };
  }
}
