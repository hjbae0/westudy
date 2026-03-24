import 'package:cloud_firestore/cloud_firestore.dart';

class SlotModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int maxStudents;
  final int currentStudents;
  final bool isAvailable;

  SlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.maxStudents,
    required this.currentStudents,
    required this.isAvailable,
  });

  factory SlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SlotModel(
      id: doc.id,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      maxStudents: data['maxStudents'] ?? 0,
      currentStudents: data['currentStudents'] ?? 0,
      isAvailable: data['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'maxStudents': maxStudents,
      'currentStudents': currentStudents,
      'isAvailable': isAvailable,
    };
  }
}
