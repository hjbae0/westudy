import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // student, parent, admin
  final String? phone;
  final String? profileImageUrl;
  final String? parentId; // 학생 → 학부모 연결
  final List<String> childrenIds; // 학부모 → 학생 목록
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImageUrl,
    this.parentId,
    this.childrenIds = const [],
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      phone: data['phone'],
      profileImageUrl: data['profileImageUrl'],
      parentId: data['parentId'],
      childrenIds: List<String>.from(data['childrenIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'parentId': parentId,
      'childrenIds': childrenIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
