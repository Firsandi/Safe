import 'package:equatable/equatable.dart';

class ContactEntity extends Equatable {
  final String id;
  final String name;
  final String phoneNumber;
  final String? profileImage;
  final String status; // e.g., 'Tersambung', 'Menunggu Konfirmasi'
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastLocationUpdate;

  const ContactEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.profileImage,
    required this.status,
    this.lastLatitude,
    this.lastLongitude,
    this.lastLocationUpdate,
  });

  @override
  List<Object?> get props => [id, name, phoneNumber, profileImage, status, lastLatitude, lastLongitude, lastLocationUpdate];
}
