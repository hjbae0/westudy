import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/utils/theme.dart';

class ClassesImportPage extends StatelessWidget {
  const ClassesImportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 액션 버튼 3개
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionCard(
                icon: Icons.upload_file,
                title: '엑셀 일괄 등록',
                subtitle: 'CSV/엑셀 파일로 수업 일괄 생성',
                color: AppTheme.primaryColor,
                onTap: () => _showCsvImport(context),
              ),
              _ActionCard(
                icon: Icons.download,
                title: '엑셀 다운로드',
                subtitle: '현재 수업 목록을 CSV로 내보내기',
                color: AppTheme.secondaryColor,
                onTap: () => _exportCsv(context),
              ),
              _ActionCard(
                icon: Icons.table_chart,
                title: 'Google Sheets 연동',
                subtitle: '스프레드시트에서 수업 데이터 가져오기',
                color: const Color(0xFF0F9D58),
                onTap: () => _showGoogleSheetsDialog(context),
              ),
              _ActionCard(
                icon: Icons.calendar_month,
                title: 'Google Calendar 연동',
                subtitle: '선생님별 캘린더에 수업 자동 동기화',
                color: const Color(0xFF4285F4),
                onTap: () => _showGoogleCalendarDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 연동 상태
          const Text('연동 상태', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildSyncStatus(),
        ],
      ),
    );
  }

  // 엑셀(CSV) 일괄 등록
  void _showCsvImport(BuildContext context) {
    final textC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('엑셀 일괄 등록'),
        content: SizedBox(
          width: 550,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CSV 형식 (헤더 포함):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '학생명,과목,선생님,요일,시간\n김민준,수학,김선생님,월,14:00\n이서윤,영어,이선생님,화,16:00',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textC,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: '학생명,과목,선생님,요일,시간\n...',
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final count = await _parseCsvAndCreate(textC.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$count개 수업이 등록되었습니다.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('등록'),
          ),
        ],
      ),
    );
  }

  Future<int> _parseCsvAndCreate(String csv) async {
    final lines = const LineSplitter().convert(csv.trim());
    if (lines.length < 2) return 0; // 헤더만 있으면 무시

    final weekdayMap = {'월': DateTime.monday, '화': DateTime.tuesday, '수': DateTime.wednesday, '목': DateTime.thursday, '금': DateTime.friday, '토': DateTime.saturday, '일': DateTime.sunday};

    final batch = FirebaseFirestore.instance.batch();
    var count = 0;
    final ref = FirebaseFirestore.instance.collection(AppConstants.bookingsCollection);

    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',').map((e) => e.trim()).toList();
      if (parts.length < 5) continue;

      final studentName = parts[0];
      final subject = parts[1];
      final teacherName = parts[2];
      final weekday = weekdayMap[parts[3]];
      final timeParts = parts[4].split(':');
      if (weekday == null || timeParts.length < 2) continue;

      final hour = int.tryParse(timeParts[0]) ?? 14;
      final minute = int.tryParse(timeParts[1]) ?? 0;

      // 다음 해당 요일 계산
      final now = DateTime.now();
      var targetDate = now;
      while (targetDate.weekday != weekday) {
        targetDate = targetDate.add(const Duration(days: 1));
      }
      final bookedAt = DateTime(targetDate.year, targetDate.month, targetDate.day, hour, minute);

      batch.set(ref.doc(), {
        'studentId': studentName, // 이름으로 저장 (나중에 매핑 필요)
        'subject': subject,
        'teacherName': teacherName,
        'status': 'confirmed',
        'bookedAt': Timestamp.fromDate(bookedAt),
        'slotId': '',
        'lmtUsed': 0,
        'importedFrom': 'csv',
      });
      count++;
    }

    if (count > 0) await batch.commit();
    return count;
  }

  // 엑셀(CSV) 다운로드
  void _exportCsv(BuildContext context) async {
    final snap = await FirebaseFirestore.instance
        .collection(AppConstants.bookingsCollection)
        .where('status', whereIn: ['confirmed', 'completed'])
        .orderBy('bookedAt')
        .get();

    final lines = <String>['학생ID,과목,선생님,날짜,시간,상태'];
    for (final doc in snap.docs) {
      final d = doc.data();
      final dt = (d['bookedAt'] as Timestamp?)?.toDate();
      lines.add([
        d['studentId'] ?? '',
        d['subject'] ?? '',
        d['teacherName'] ?? '',
        dt != null ? DateFormat('yyyy-MM-dd').format(dt) : '',
        dt != null ? DateFormat('HH:mm').format(dt) : '',
        d['status'] ?? '',
      ].join(','));
    }

    final csvContent = lines.join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('수업 목록 내보내기'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('총 ${snap.docs.length}개 수업', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  csvContent,
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              Text('위 내용을 복사하여 엑셀에 붙여넣기하세요.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  // Google Sheets 연동
  void _showGoogleSheetsDialog(BuildContext context) {
    final sheetIdC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.table_chart, color: Color(0xFF0F9D58)),
            SizedBox(width: 8),
            Text('Google Sheets 연동'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Google 스프레드시트에서 수업 데이터를 자동으로 가져옵니다.'),
              const SizedBox(height: 16),
              TextFormField(
                controller: sheetIdC,
                decoration: InputDecoration(
                  labelText: '스프레드시트 ID',
                  hintText: '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms',
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• 시트 첫 행: 학생명, 과목, 선생님, 요일, 시간\n'
                '• Google Sheets API 키가 Cloud Functions에 설정되어야 합니다\n'
                '• 30분마다 자동 동기화',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              if (sheetIdC.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('integrations').doc('google_sheets').set({
                'sheetId': sheetIdC.text.trim(),
                'enabled': true,
                'lastSync': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google Sheets 연동이 설정되었습니다.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F9D58), foregroundColor: Colors.white),
            child: const Text('연동'),
          ),
        ],
      ),
    );
  }

  // Google Calendar 연동
  void _showGoogleCalendarDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.calendar_month, color: Color(0xFF4285F4)),
            SizedBox(width: 8),
            Text('Google Calendar 연동'),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('선생님별 Google 캘린더에 수업을 자동으로 동기화합니다.'),
              const SizedBox(height: 16),
              _featureRow(Icons.sync, '양방향 동기화', '캘린더 변경 → 앱 반영'),
              _featureRow(Icons.schedule, '자동 동기화', '수업 생성/변경/취소 시 즉시 반영'),
              _featureRow(Icons.block, '충돌 감지', '선생님 기존 일정과 충돌 시 경고'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Cloud Functions에서 Google Calendar API를 사용합니다.\n'
                  'OAuth2 서비스 계정 키가 필요합니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('integrations').doc('google_calendar').set({
                'enabled': true,
                'syncInterval': 'realtime',
                'lastSync': FieldValue.serverTimestamp(),
              });
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google Calendar 연동이 활성화되었습니다.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4285F4), foregroundColor: Colors.white),
            child: const Text('연동 시작'),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4285F4)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  // 연동 상태 표시
  Widget _buildSyncStatus() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('integrations').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('연동된 서비스가 없습니다.', style: TextStyle(color: Colors.grey.shade400))),
          );
        }

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: docs.map((doc) {
              final d = doc.data() as Map<String, dynamic>;
              final enabled = d['enabled'] == true;
              final lastSync = (d['lastSync'] as Timestamp?)?.toDate();

              return ListTile(
                leading: Icon(
                  doc.id == 'google_sheets' ? Icons.table_chart : Icons.calendar_month,
                  color: enabled ? AppTheme.secondaryColor : Colors.grey,
                ),
                title: Text(doc.id == 'google_sheets' ? 'Google Sheets' : 'Google Calendar'),
                subtitle: Text(
                  lastSync != null ? '마지막 동기화: ${DateFormat('M/d HH:mm').format(lastSync)}' : '연동됨',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: enabled ? AppTheme.secondaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    enabled ? '활성' : '비활성',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: enabled ? AppTheme.secondaryColor : Colors.grey),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
