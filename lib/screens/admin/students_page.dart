import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/utils/theme.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 + 추가 버튼
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '이름, 학년, 전공으로 검색...',
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
                onPressed: () => _showStudentForm(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('학생 추가'),
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

          // 학생 테이블
          _buildStudentTable(),
        ],
      ),
    );
  }

  Widget _buildStudentTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: 'student')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var students = snapshot.data?.docs ?? [];

        // 검색 필터
        if (_searchQuery.isNotEmpty) {
          students = students.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final grade = (data['grade'] ?? '').toString().toLowerCase();
            final major = (data['major'] ?? '').toString().toLowerCase();
            return name.contains(_searchQuery) ||
                grade.contains(_searchQuery) ||
                major.contains(_searchQuery);
          }).toList();
        }

        if (students.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                _searchQuery.isEmpty ? '등록된 학생이 없습니다.' : '검색 결과가 없습니다.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: const Row(
                  children: [
                    _Cell('이름', flex: 3, isHeader: true),
                    _Cell('학년', flex: 2, isHeader: true),
                    _Cell('전공', flex: 2, isHeader: true),
                    _Cell('학부모 연락처', flex: 3, isHeader: true),
                    _Cell('이메일', flex: 3, isHeader: true),
                    _Cell('관리', flex: 2, isHeader: true),
                  ],
                ),
              ),
              // 행
              ...students.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildRow(doc.id, data);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(String id, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          _Cell(data['name'] ?? '-', flex: 3),
          _Cell(data['grade'] ?? '-', flex: 2),
          _Cell(data['major'] ?? '-', flex: 2),
          _Cell(data['parentPhone'] ?? '-', flex: 3),
          _Cell(data['email'] ?? '-', flex: 3),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                _IconBtn(Icons.edit_outlined, AppTheme.primaryColor, () => _showStudentForm(context, id: id, data: data)),
                const SizedBox(width: 4),
                _IconBtn(Icons.delete_outline, AppTheme.errorColor, () => _confirmDelete(id, data['name'] ?? '')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentForm(BuildContext context, {String? id, Map<String, dynamic>? data}) {
    final nameC = TextEditingController(text: data?['name'] ?? '');
    final gradeC = TextEditingController(text: data?['grade'] ?? '');
    final majorC = TextEditingController(text: data?['major'] ?? '');
    final parentPhoneC = TextEditingController(text: data?['parentPhone'] ?? '');
    final emailC = TextEditingController(text: data?['email'] ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = id != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '학생 수정' : '학생 추가'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FormField(controller: nameC, label: '이름', validator: _required),
                const SizedBox(height: 12),
                _FormField(controller: gradeC, label: '학년 (예: 중2, 고1)', validator: _required),
                const SizedBox(height: 12),
                _FormField(controller: majorC, label: '전공/관심과목'),
                const SizedBox(height: 12),
                _FormField(controller: parentPhoneC, label: '학부모 연락처', validator: _phoneValidator),
                const SizedBox(height: 12),
                _FormField(controller: emailC, label: '이메일', validator: _emailValidator),
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
                'grade': gradeC.text.trim(),
                'major': majorC.text.trim(),
                'parentPhone': parentPhoneC.text.trim(),
                'email': emailC.text.trim(),
                'role': 'student',
                if (!isEdit) 'createdAt': FieldValue.serverTimestamp(),
              };
              final ref = FirebaseFirestore.instance.collection(AppConstants.usersCollection);
              if (isEdit) {
                await ref.doc(id).update(doc);
              } else {
                await ref.add(doc);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(isEdit ? '수정' : '추가'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('학생 삭제'),
        content: Text('$name 학생을 삭제할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(AppConstants.usersCollection)
                  .doc(id)
                  .delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? '필수 입력입니다.' : null;
  String? _phoneValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!RegExp(r'^01[0-9]-?\d{3,4}-?\d{4}$').hasMatch(v.trim())) return '올바른 전화번호를 입력하세요.';
    return null;
  }
  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return '올바른 이메일을 입력하세요.';
    return null;
  }
}

// 공통 위젯
class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool isHeader;
  const _Cell(this.text, {this.flex = 1, this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: isHeader ? 12 : 13,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          color: isHeader ? AppTheme.onSurfaceColor.withValues(alpha: 0.6) : AppTheme.onSurfaceColor,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  const _FormField({required this.controller, required this.label, this.validator});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
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
