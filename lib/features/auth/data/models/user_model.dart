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
      user_id: json['user_id'] ?? '',      
      email: json['email'] ?? '',    
      nama: json['nama'] ?? '',      
      nomorHp: json['nomor_hp'] ?? '',
      golDarah: json['gol_darah'],
      catatanMedis: json['catatan_medis'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'email': email,
      'nama': nama,
      'nomor_hp': nomorHp,
      'gol_darah': golDarah,
      'catatan_medis': catatanMedis,
    };
  }
}
