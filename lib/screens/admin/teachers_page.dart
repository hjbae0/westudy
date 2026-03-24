import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:westudy/utils/theme.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({super.key});

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  CollectionReference get _teachersRef =>
      FirebaseFirestore.instance.collection('teachers');

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '이름, 과목으로 검색...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('선생님 추가'),
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
      stream: _teachersRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snapshot.data?.docs ?? [];
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final name = (d['name'] ?? '').toString().toLowerCase();
            final subjects = (d['subjects'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) || subjects.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                _searchQuery.isEmpty ? '등록된 선생님이 없습니다.' : '검색 결과가 없습니다.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
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
                    _hdr('이름', 3),
                    _hdr('담당 과목', 3),
                    _hdr('연락처', 3),
                    _hdr('이메일', 3),
                    _hdr('관리', 2),
                  ],
                ),
              ),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(
                    children: [
                      _cell(d['name'] ?? '-', 3),
                      _cell(d['subjects'] ?? '-', 3),
                      _cell(d['phone'] ?? '-', 3),
                      _cell(d['email'] ?? '-', 3),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            _iconBtn(Icons.edit_outlined, AppTheme.primaryColor, () => _showForm(context, id: doc.id, data: d)),
                            const SizedBox(width: 4),
                            _iconBtn(Icons.delete_outline, AppTheme.errorColor, () => _confirmDelete(doc.id, d['name'] ?? '')),
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

  Widget _hdr(String t, int f) => Expanded(
      flex: f,
      child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceColor.withValues(alpha: 0.6))));

  Widget _cell(String t, int f) => Expanded(
      flex: f,
      child: Text(t, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 18, color: color)));

  void _showForm(BuildContext context, {String? id, Map<String, dynamic>? data}) {
    final nameC = TextEditingController(text: data?['name'] ?? '');
    final subjectsC = TextEditingController(text: data?['subjects'] ?? '');
    final phoneC = TextEditingController(text: data?['phone'] ?? '');
    final emailC = TextEditingController(text: data?['email'] ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '선생님 수정' : '선생님 추가'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(nameC, '이름', required: true),
                const SizedBox(height: 12),
                _field(subjectsC, '담당 과목 (예: 수학, 영어)', required: true),
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
                'subjects': subjectsC.text.trim(),
                'phone': phoneC.text.trim(),
                'email': emailC.text.trim(),
                if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
              };
              if (isEdit) {
                await _teachersRef.doc(id).update(doc);
              } else {
                await _teachersRef.add(doc);
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

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('선생님 삭제'),
        content: Text('$name 선생님을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              await _teachersRef.doc(id).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
