import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:westudy/utils/theme.dart';

class TeacherSchedulePage extends StatefulWidget {
  const TeacherSchedulePage({super.key});

  @override
  State<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  String? _selectedTeacherId;
  String? _selectedTeacherName;

  static const _weekdays = ['월', '화', '수', '목', '금', '토'];
  static const _hours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선생님 선택 + 액션 버튼
          Row(
            children: [
              Expanded(child: _buildTeacherDropdown()),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _selectedTeacherId != null ? _importExcel : null,
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('엑셀 일괄등록'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _selectedTeacherId != null ? _syncGoogleCalendar : null,
                icon: const Icon(Icons.sync, size: 18),
                label: const Text('Google 캘린더 연동'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_selectedTeacherId != null) _buildScheduleGrid(),
        ],
      ),
    );
  }

  Widget _buildTeacherDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('teachers').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        final teachers = snapshot.data?.docs ?? [];
        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              hint: const Text('선생님 선택'),
              value: _selectedTeacherId,
              items: teachers.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(value: doc.id, child: Text('${d['name']} (${d['subjects'] ?? ''})'));
              }).toList(),
              onChanged: (v) {
                final doc = teachers.firstWhere((d) => d.id == v);
                setState(() {
                  _selectedTeacherId = v;
                  _selectedTeacherName = (doc.data() as Map<String, dynamic>)['name'];
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleGrid() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teacher_schedules')
          .doc(_selectedTeacherId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        // availability: { "월": [9,10,14,15,...], "화": [...] }
        final availability = Map<String, List<int>>.from(
          (data['availability'] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, List<int>.from(v as List)),
          ),
        );
        final googleSynced = data['googleCalendarSynced'] == true;

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      '$_selectedTeacherName 선생님 스케줄',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    if (googleSynced) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Google 연동', style: TextStyle(fontSize: 11, color: AppTheme.secondaryColor)),
                      ),
                    ],
                    const Spacer(),
                    // 범례
                    _legend(AppTheme.primaryColor.withValues(alpha: 0.15), '가용'),
                    const SizedBox(width: 12),
                    _legend(Colors.grey.shade100, '불가'),
                  ],
                ),
              ),
              // 그리드
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade200, width: 0.5),
                  columnWidths: const {0: FixedColumnWidth(50)},
                  children: [
                    // 헤더
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.05)),
                      children: [
                        _gridHeader('시간'),
                        ..._weekdays.map(_gridHeader),
                      ],
                    ),
                    // 시간 행
                    ..._hours.map((hour) {
                      return TableRow(
                        children: [
                          _gridCell('$hour:00', isLabel: true),
                          ..._weekdays.map((day) {
                            final isAvailable = availability[day]?.contains(hour) ?? false;
                            return _gridSlot(day, hour, isAvailable);
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gridHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
    );
  }

  Widget _gridCell(String text, {bool isLabel = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Text(text, style: TextStyle(fontSize: 11, color: isLabel ? Colors.grey.shade600 : null)),
      ),
    );
  }

  Widget _gridSlot(String day, int hour, bool isAvailable) {
    return InkWell(
      onTap: () => _toggleSlot(day, hour, isAvailable),
      child: Container(
        height: 36,
        color: isAvailable ? AppTheme.primaryColor.withValues(alpha: 0.15) : Colors.grey.shade50,
        child: Center(
          child: isAvailable
              ? Icon(Icons.check, size: 14, color: AppTheme.primaryColor)
              : null,
        ),
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  Future<void> _toggleSlot(String day, int hour, bool current) async {
    final ref = FirebaseFirestore.instance.collection('teacher_schedules').doc(_selectedTeacherId);
    if (current) {
      await ref.set({
        'availability': {day: FieldValue.arrayRemove([hour])}
      }, SetOptions(merge: true));
    } else {
      await ref.set({
        'availability': {day: FieldValue.arrayUnion([hour])}
      }, SetOptions(merge: true));
    }
  }

  void _importExcel() {
    // xlsx 파일 파싱은 웹에서 file_picker + xlsx 패키지 사용
    // 여기서는 CSV 텍스트 입력으로 대체 가능한 폼 제공
    showDialog(
      context: context,
      builder: (ctx) {
        final textC = TextEditingController();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('엑셀 일괄 등록'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CSV 형식으로 입력하세요:', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 4),
                Text('요일,시작시간,종료시간', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                Text('예) 월,9,12', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                Text('    화,14,18', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                const SizedBox(height: 12),
                TextField(
                  controller: textC,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: '월,9,12\n화,14,18\n수,9,20',
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
            ElevatedButton(
              onPressed: () async {
                await _parseCsvAndSave(textC.text);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('등록'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _parseCsvAndSave(String csv) async {
    final lines = const LineSplitter().convert(csv.trim());
    final Map<String, List<int>> availability = {};

    for (final line in lines) {
      final parts = line.split(',').map((e) => e.trim()).toList();
      if (parts.length < 3) continue;
      final day = parts[0];
      final start = int.tryParse(parts[1]);
      final end = int.tryParse(parts[2]);
      if (start == null || end == null) continue;

      availability.putIfAbsent(day, () => []);
      for (var h = start; h < end; h++) {
        if (!availability[day]!.contains(h)) {
          availability[day]!.add(h);
        }
      }
    }

    await FirebaseFirestore.instance
        .collection('teacher_schedules')
        .doc(_selectedTeacherId)
        .set({'availability': availability}, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스케줄이 등록되었습니다.')),
      );
    }
  }

  void _syncGoogleCalendar() {
    // Google Calendar API 연동 (OAuth2 + Calendar API)
    // 실제 구현은 Cloud Functions에서 처리
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.sync, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Google 캘린더 연동'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('선생님의 Google 캘린더와 자동 동기화합니다.'),
              const SizedBox(height: 12),
              Text(
                '• 구글 캘린더의 바쁜 시간은 자동으로 불가 처리\n'
                '• 30분마다 자동 동기화\n'
                '• Cloud Functions에서 처리',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.6),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Google Calendar API 키 설정이 필요합니다.',
                        style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              // 연동 플래그 설정
              await FirebaseFirestore.instance
                  .collection('teacher_schedules')
                  .doc(_selectedTeacherId)
                  .set({'googleCalendarSynced': true}, SetOptions(merge: true));
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google 캘린더 연동이 활성화되었습니다.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('연동 시작'),
          ),
        ],
      ),
    );
  }
}
