import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/utils/theme.dart';

class ParentsPage extends StatelessWidget {
  const ParentsPage({super.key});

  CollectionReference get _usersRef =>
      FirebaseFirestore.instance.collection(AppConstants.usersCollection);

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
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('학부모 추가'),
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
          _buildTable(context),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersRef.where('role', isEqualTo: 'parent').orderBy('createdAt', descending: true).snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('등록된 학부모가 없습니다.', style: TextStyle(color: Colors.grey.shade500))),
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
                  children: [_h('이름', 3), _h('연락처', 3), _h('이메일', 3), _h('연결 학생', 3), _h('관리', 2)],
                ),
              ),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final children = List<String>.from(d['childrenIds'] ?? []);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      _c(d['name'] ?? '-', 3),
                      _c(d['phone'] ?? '-', 3),
                      _c(d['email'] ?? '-', 3),
                      Expanded(
                        flex: 3,
                        child: children.isEmpty
                            ? Text('미연결', style: TextStyle(fontSize: 12, color: Colors.grey.shade400))
                            : Wrap(
                                spacing: 4,
                                children: [
                                  ...children.map((cid) => _StudentChip(studentId: cid)),
                                  InkWell(
                                    onTap: () => _linkStudent(context, doc.id),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppTheme.primaryColor),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text('+', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            InkWell(
                              onTap: () => _showForm(context, id: doc.id, data: d),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.edit_outlined, size: 18, color: AppTheme.primaryColor)),
                            ),
                            const SizedBox(width: 4),
                            if (children.isEmpty)
                              InkWell(
                                onTap: () => _linkStudent(context, doc.id),
                                borderRadius: BorderRadius.circular(6),
                                child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.link, size: 18, color: AppTheme.secondaryColor)),
                              ),
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

  Widget _h(String t, int f) => Expanded(flex: f, child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceColor.withValues(alpha: 0.6))));
  Widget _c(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));

  void _showForm(BuildContext context, {String? id, Map<String, dynamic>? data}) {
    final nameC = TextEditingController(text: data?['name'] ?? '');
    final phoneC = TextEditingController(text: data?['phone'] ?? '');
    final emailC = TextEditingController(text: data?['email'] ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '학부모 수정' : '학부모 추가'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameC, '이름', required: true),
                const SizedBox(height: 12),
                _field(phoneC, '연락처', phone: true),
                const SizedBox(height: 12),
                _field(emailC, '이메일', email: true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final doc = {
                'name': nameC.text.trim(),
                'phone': phoneC.text.trim(),
                'email': emailC.text.trim(),
                'role': 'parent',
                if (!isEdit) 'childrenIds': <String>[],
                if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
              };
              if (isEdit) {
                await _usersRef.doc(id).update(doc);
              } else {
                await _usersRef.add(doc);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: Text(isEdit ? '수정' : '추가'),
          ),
        ],
      ),
    );
  }

  void _linkStudent(BuildContext context, String parentId) {
    String? selectedStudentId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('학생 연결'),
          content: SizedBox(
            width: 400,
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersRef.where('role', isEqualTo: 'student').snapshots(),
              builder: (context, snap) {
                final students = snap.data?.docs ?? [];
                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: '학생 선택',
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                  value: selectedStudentId,
                  items: students.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(value: doc.id, child: Text(d['name'] ?? doc.id));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedStudentId = v),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: selectedStudentId == null ? null : () async {
                final batch = FirebaseFirestore.instance.batch();
                batch.update(_usersRef.doc(parentId), {
                  'childrenIds': FieldValue.arrayUnion([selectedStudentId]),
                });
                batch.update(_usersRef.doc(selectedStudentId!), {
                  'parentId': parentId,
                });
                await batch.commit();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('연결'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool required = false, bool phone = false, bool email = false}) {
    return TextFormField(
      controller: c,
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) return '필수 입력입니다.';
        if (phone && v != null && v.isNotEmpty && !RegExp(r'^01[0-9]-?\d{3,4}-?\d{4}$').hasMatch(v.trim())) return '올바른 전화번호를 입력하세요.';
        if (email && v != null && v.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return '올바른 이메일을 입력하세요.';
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _StudentChip extends StatelessWidget {
  final String studentId;
  const _StudentChip({required this.studentId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection(AppConstants.usersCollection).doc(studentId).get(),
      builder: (ctx, snap) {
        final name = (snap.data?.data() as Map<String, dynamic>?)?['name'] ?? studentId.substring(0, 6);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(name, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor)),
        );
      },
    );
  }
}
