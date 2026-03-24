import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String id;
  final String studentId;
  final String adminId;
  final String content;
  final String? attachmentUrl;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.studentId,
    required this.adminId,
    required this.content,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      adminId: data['adminId'] ?? '',
      content: data['content'] ?? '',
      attachmentUrl: data['attachmentUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'adminId': adminId,
      'content': content,
      'attachmentUrl': attachmentUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
