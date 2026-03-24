import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String id;
  final String studentId;
  final String slotId;
  final String status; // pending, confirmed, cancelled, completed
  final DateTime bookedAt;
  final String? note;

  BookingModel({
    required this.id,
    required this.studentId,
    required this.slotId,
    required this.status,
    required this.bookedAt,
    this.note,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      slotId: data['slotId'] ?? '',
      status: data['status'] ?? 'pending',
      bookedAt: (data['bookedAt'] as Timestamp).toDate(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'slotId': slotId,
      'status': status,
      'bookedAt': Timestamp.fromDate(bookedAt),
      'note': note,
    };
  }
}
