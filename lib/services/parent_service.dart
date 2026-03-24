import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:westudy/models/user_model.dart';
import 'package:westudy/models/booking_model.dart';
import 'package:westudy/utils/constants.dart';

class ParentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 학부모-학생 연결 (초대 코드 또는 이메일로)
  Future<void> linkChild({
    required String parentId,
    required String childId,
  }) async {
    final batch = _db.batch();

    // 학생에 parentId 설정
    batch.update(
      _db.collection(AppConstants.usersCollection).doc(childId),
      {'parentId': parentId},
    );

    // 학부모의 childrenIds에 추가
    batch.update(
      _db.collection(AppConstants.usersCollection).doc(parentId),
      {'childrenIds': FieldValue.arrayUnion([childId])},
    );

    await batch.commit();
  }

  // 학부모-학생 연결 해제
  Future<void> unlinkChild({
    required String parentId,
    required String childId,
  }) async {
    final batch = _db.batch();

    batch.update(
      _db.collection(AppConstants.usersCollection).doc(childId),
      {'parentId': FieldValue.delete()},
    );

    batch.update(
      _db.collection(AppConstants.usersCollection).doc(parentId),
      {'childrenIds': FieldValue.arrayRemove([childId])},
    );

    await batch.commit();
  }

  // 학부모의 자녀 목록 조회
  Future<List<UserModel>> getChildren(String parentId) async {
    final parentDoc = await _db
        .collection(AppConstants.usersCollection)
        .doc(parentId)
        .get();

    final childrenIds = List<String>.from(parentDoc.data()?['childrenIds'] ?? []);
    if (childrenIds.isEmpty) return [];

    final children = <UserModel>[];
    for (final childId in childrenIds) {
      final doc = await _db
          .collection(AppConstants.usersCollection)
          .doc(childId)
          .get();
      if (doc.exists) {
        children.add(UserModel.fromFirestore(doc));
      }
    }
    return children;
  }

  // 자녀의 예약 목록 조회
  Stream<List<BookingModel>> getChildBookings(String childId) {
    return _db
        .collection(AppConstants.bookingsCollection)
        .where('studentId', isEqualTo: childId)
        .where('status', whereIn: ['confirmed', 'completed'])
        .orderBy('bookedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  // 이메일로 학생 검색 (연결용)
  Future<UserModel?> findStudentByEmail(String email) async {
    final snap = await _db
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: email)
        .where('role', isEqualTo: 'student')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return UserModel.fromFirestore(snap.docs.first);
  }
}
