import 'package:cloud_firestore/cloud_firestore.dart';

class SlotModel {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int maxStudents;
  final int currentStudents;
  final String status; // available, booked, blocked
  final String? subject;
  final String? teacherName;

  SlotModel({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.maxStudents,
    required this.currentStudents,
    required this.status,
    this.subject,
    this.teacherName,
  });

  bool get isAvailable => status == 'available' && currentStudents < maxStudents;

  factory SlotModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SlotModel(
      id: doc.id,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      maxStudents: data['maxStudents'] ?? 0,
      currentStudents: data['currentStudents'] ?? 0,
      status: data['status'] ?? 'available',
      subject: data['subject'],
      teacherName: data['teacherName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'maxStudents': maxStudents,
      'currentStudents': currentStudents,
      'status': status,
      'subject': subject,
      'teacherName': teacherName,
    };
  }
}
