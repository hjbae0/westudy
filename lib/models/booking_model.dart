import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String studentId;
  final String slotId;
  final String subject;
  final String? teacherName;
  final String status; // pending, confirmed, cancelled, completed
  final DateTime bookedAt;
  final String? note;
  final int lmtUsed; // 긴급변경권 사용 횟수

  BookingModel({
    required this.id,
    required this.studentId,
    required this.slotId,
    required this.subject,
    this.teacherName,
    required this.status,
    required this.bookedAt,
    this.note,
    this.lmtUsed = 0,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      slotId: data['slotId'] ?? '',
      subject: data['subject'] ?? '',
      teacherName: data['teacherName'],
      status: data['status'] ?? 'pending',
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      note: data['note'],
      lmtUsed: data['lmtUsed'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'slotId': slotId,
      'subject': subject,
      'teacherName': teacherName,
      'status': status,
      'bookedAt': Timestamp.fromDate(bookedAt),
      'note': note,
      'lmtUsed': lmtUsed,
    };
  }

  BookingModel copyWith({
    String? id,
    String? studentId,
    String? slotId,
    String? subject,
    String? teacherName,
    String? status,
    DateTime? bookedAt,
    String? note,
    int? lmtUsed,
  }) {
    return BookingModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      slotId: slotId ?? this.slotId,
      subject: subject ?? this.subject,
      teacherName: teacherName ?? this.teacherName,
      status: status ?? this.status,
      bookedAt: bookedAt ?? this.bookedAt,
      note: note ?? this.note,
      lmtUsed: lmtUsed ?? this.lmtUsed,
    );
  }
}
