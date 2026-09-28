import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Profil utilisateur stocké dans `users/{uid}`.
class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.whatsappNumber,
    required this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'client' ou 'seller'
  final String? whatsappNumber;
  final DateTime createdAt;

  bool get isSeller => role == AppConstants.roleSeller;
  bool get isClient => role == AppConstants.roleClient;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'whatsappNumber': whatsappNumber,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      role: (map['role'] as String?) ?? AppConstants.roleClient,
      whatsappNumber: map['whatsappNumber'] as String?,
      createdAt: parseDate(map['createdAt']),
    );
  }

  UserModel copyWith({String? name, String? phone, String? whatsappNumber}) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      createdAt: createdAt,
    );
  }
}
