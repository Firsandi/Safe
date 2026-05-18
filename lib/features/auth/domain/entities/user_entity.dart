import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String email;
  final String name;
  final String phoneNumber;
  final String? bloodType;
  final String? medicalNotes;
  final String? token;
  final String? profileImage;

  const UserEntity({
    required this.userId,
    required this.email,
    required this.name,
    required this.phoneNumber,
    this.bloodType,
    this.medicalNotes,
    this.token,
    this.profileImage,
  });

  @override
  List<Object?> get props => [userId, email, name, phoneNumber, bloodType, medicalNotes, token, profileImage];
}