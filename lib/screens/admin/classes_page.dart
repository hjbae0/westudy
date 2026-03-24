import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/utils/theme.dart';

class ClassesPage extends StatelessWidget {
  const ClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('수업 생성'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTable(),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .orderBy('bookedAt', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('수업이 없습니다.', style: TextStyle(color: Colors.grey.shade500))),
          );
        }

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    _hdr('날짜/시간', 3),
                    _hdr('과목', 2),
                    _hdr('학생 ID', 3),
                    _hdr('선생님', 2),
                    _hdr('상태', 2),
                    _hdr('관리', 2),
                  ],
                ),
              ),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final bookedAt = (d['bookedAt'] as Timestamp?)?.toDate();
                final timeStr = bookedAt != null
                    ? DateFormat('M/d (E) HH:mm', 'ko_KR').format(bookedAt)
                    : '-';
                final status = d['status'] ?? 'pending';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      _cell(timeStr, 3),
                      _cell(d['subject'] ?? '-', 2),
                      _cell(_truncate(d['studentId'] ?? '-', 10), 3),
                      _cell(d['teacherName'] ?? '-', 2),
                      Expanded(
                        flex: 2,
                        child: _statusBadge(status),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            if (status == 'confirmed') ...[
                              _iconBtn(Icons.edit_outlined, AppTheme.primaryColor, () => _showEditForm(context, doc.id, d)),
                              const SizedBox(width: 4),
                              _iconBtn(Icons.cancel_outlined, AppTheme.errorColor, () => _cancelClass(context, doc.id)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'confirmed':
        color = AppTheme.secondaryColor;
        label = '확정';
        break;
      case 'cancelled':
        color = AppTheme.errorColor;
        label = '취소';
        break;
      case 'completed':
        color = AppTheme.primaryColor;
        label = '완료';
        break;
      default:
        color = Colors.grey;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  static void _showCreateForm(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final subjectC = TextEditingController();
    final teacherC = TextEditingController();
    String? selectedStudentId;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('수업 생성'),
          content: SizedBox(
            width: 450,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 학생 선택
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(AppConstants.usersCollection)
                        .where('role', isEqualTo: 'student')
                        .snapshots(),
                    builder: (context, snap) {
                      final students = snap.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        decoration: _inputDeco('학생 선택'),
                        value: selectedStudentId,
                        validator: (v) => v == null ? '학생을 선택하세요.' : null,
                        items: students.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(value: doc.id, child: Text(d['name'] ?? doc.id));
                        }).toList(),
                        onChanged: (v) => setDialogState(() => selectedStudentId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subjectC,
                    validator: (v) => (v == null || v.isEmpty) ? '필수 입력' : null,
                    decoration: _inputDeco('과목'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(controller: teacherC, decoration: _inputDeco('선생님 이름')),
                  const SizedBox(height: 12),
                  // 날짜/시간
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                            );
                            if (picked != null) setDialogState(() => selectedDate = picked);
                          },
                          child: Text(DateFormat('M/d (E)', 'ko_KR').format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                            if (picked != null) setDialogState(() => selectedTime = picked);
                          },
                          child: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final bookedAt = DateTime(
                  selectedDate.year, selectedDate.month, selectedDate.day,
                  selectedTime.hour, selectedTime.minute,
                );
                await FirebaseFirestore.instance.collection(AppConstants.bookingsCollection).add({
                  'studentId': selectedStudentId,
                  'subject': subjectC.text.trim(),
                  'teacherName': teacherC.text.trim(),
                  'status': 'confirmed',
                  'bookedAt': Timestamp.fromDate(bookedAt),
                  'slotId': '',
                  'lmtUsed': 0,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('생성'),
            ),
          ],
        ),
      ),
    );
  }

  static void _showEditForm(BuildContext context, String id, Map<String, dynamic> data) {
    final subjectC = TextEditingController(text: data['subject'] ?? '');
    final teacherC = TextEditingController(text: data['teacherName'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('수업 수정'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(controller: subjectC, decoration: _inputDeco('과목')),
              const SizedBox(height: 12),
              TextFormField(controller: teacherC, decoration: _inputDeco('선생님 이름')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(AppConstants.bookingsCollection)
                  .doc(id)
                  .update({
                'subject': subjectC.text.trim(),
                'teacherName': teacherC.text.trim(),
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('수정'),
          ),
        ],
      ),
    );
  }

  static void _cancelClass(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('수업 취소'),
        content: const Text('이 수업을 취소할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('아니오')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(AppConstants.bookingsCollection)
                  .doc(id)
                  .update({'status': 'cancelled'});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  static InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppTheme.backgroundColor,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  static Widget _hdr(String t, int f) => Expanded(flex: f, child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceColor.withValues(alpha: 0.6))));
  static Widget _cell(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));
  static Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6), child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 18, color: color)));
  static String _truncate(String s, int max) => s.length > max ? '${s.substring(0, max)}...' : s;
}
