import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// A staff member (administrator or manager) stored in the `users` collection.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final UserRole role;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role.isAdmin;

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      role: UserRole.fromString(map['role'] as String?),
      isActive: (map['isActive'] ?? true) as bool,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppUser.fromMap(doc.id, doc.data() ?? const {});
  }

  /// Serializes to Firestore. Timestamps are written by the repository via
  /// `FieldValue.serverTimestamp()` so they are intentionally omitted here.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'role': role.asString,
      'isActive': isActive,
    };
  }

  AppUser copyWith({
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
