import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String user_id;
  final String email;
  final String nama;
  final String nomorHp;
  final String? golDarah;
  final String? catatanMedis;

  const UserEntity({
    required this.user_id,
    required this.email,
    required this.nama,
    required this.nomorHp,
    this.golDarah,
    this.catatanMedis,
  });

  @override
  List<Object?> get props => [user_id, email, nama, nomorHp, golDarah, catatanMedis];
}