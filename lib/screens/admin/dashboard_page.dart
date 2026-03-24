import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/utils/theme.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 지표 4개 카드
          _MetricCardsSection(),
          const SizedBox(height: 24),

          // 차트 영역
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _WeeklyClassChart()),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _SubjectPieChart()),
            ],
          ),
          const SizedBox(height: 24),

          // 오늘 수업 테이블
          const Text('오늘 수업', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _TodayClassesTable(),
        ],
      ),
    );
  }
}

// 지표 4개
class _MetricCardsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection(AppConstants.bookingsCollection)
          .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('bookedAt', isLessThan: Timestamp.fromDate(todayEnd))
          .where('status', isEqualTo: 'confirmed')
          .snapshots(),
      builder: (context, todaySnap) {
        final todayCount = todaySnap.data?.docs.length ?? 0;

        return FutureBuilder<List<int>>(
          future: _fetchOtherMetrics(db),
          builder: (context, otherSnap) {
            final others = otherSnap.data ?? [0, 0, 0];
            final metrics = [
              _MetricData('오늘 수업', '$todayCount', Icons.school_rounded, const Color(0xFF4A6FA5)),
              _MetricData('등록 학생', '${others[0]}', Icons.people_rounded, const Color(0xFF6B9080)),
              _MetricData('선생님', '${others[1]}', Icons.person_rounded, const Color(0xFFE17055)),
              _MetricData('이번 달', '${others[2]}', Icons.calendar_month_rounded, const Color(0xFF6C5CE7)),
            ];

            return Row(
              children: metrics.map((m) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildCard(m),
                ),
              )).toList(),
            );
          },
        );
      },
    );
  }

  Future<List<int>> _fetchOtherMetrics(FirebaseFirestore db) async {
    final students = await db.collection(AppConstants.usersCollection).where('role', isEqualTo: 'student').count().get();
    final teachers = await db.collection('teachers').count().get();
    final monthStart = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthly = await db
        .collection(AppConstants.bookingsCollection)
        .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('status', isEqualTo: 'confirmed')
        .count()
        .get();
    return [students.count ?? 0, teachers.count ?? 0, monthly.count ?? 0];
  }

  Widget _buildCard(_MetricData m) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(m.label, style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceColor.withValues(alpha: 0.6))),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: m.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(m.icon, color: m.color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(m.value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// 주간 수업 수 바 차트
class _WeeklyClassChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('이번 주 수업 수', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.bookingsCollection)
                .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monday))
                .where('bookedAt', isLessThan: Timestamp.fromDate(monday.add(const Duration(days: 7))))
                .where('status', whereIn: ['confirmed', 'completed'])
                .snapshots(),
            builder: (context, snapshot) {
              // 요일별 카운트
              final counts = List.filled(7, 0);
              for (final doc in snapshot.data?.docs ?? []) {
                final d = doc.data() as Map<String, dynamic>;
                final dt = (d['bookedAt'] as Timestamp?)?.toDate();
                if (dt != null) {
                  final dayIndex = dt.weekday - 1;
                  if (dayIndex >= 0 && dayIndex < 7) counts[dayIndex]++;
                }
              }
              final maxCount = counts.reduce(max).clamp(1, 999);

              return SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final isToday = weekDays[i].day == now.day && weekDays[i].month == now.month;
                    final ratio = counts[i] / maxCount;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${counts[i]}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isToday ? AppTheme.primaryColor : Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              height: max(4, ratio * 140),
                              decoration: BoxDecoration(
                                color: isToday ? AppTheme.primaryColor : AppTheme.primaryColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('E', 'ko_KR').format(weekDays[i]),
                              style: TextStyle(fontSize: 11, color: isToday ? AppTheme.primaryColor : Colors.grey.shade500),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 과목별 분포 파이 차트
class _SubjectPieChart extends StatelessWidget {
  static const _colors = [
    Color(0xFF4A6FA5),
    Color(0xFFE17055),
    Color(0xFF6B9080),
    Color(0xFF6C5CE7),
    Color(0xFFFDAA5E),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('과목별 분포', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.bookingsCollection)
                .where('status', whereIn: ['confirmed', 'completed'])
                .snapshots(),
            builder: (context, snapshot) {
              final subjectCounts = <String, int>{};
              for (final doc in snapshot.data?.docs ?? []) {
                final d = doc.data() as Map<String, dynamic>;
                final subject = (d['subject'] ?? '기타').toString();
                subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
              }

              if (subjectCounts.isEmpty) {
                return SizedBox(
                  height: 200,
                  child: Center(child: Text('데이터 없음', style: TextStyle(color: Colors.grey.shade400))),
                );
              }

              final total = subjectCounts.values.fold(0, (a, b) => a + b);
              final entries = subjectCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Column(
                children: [
                  // 커스텀 파이 차트
                  SizedBox(
                    height: 160,
                    width: 160,
                    child: CustomPaint(
                      painter: _PieChartPainter(entries, total, _colors),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 범례
                  ...entries.asMap().entries.map((e) {
                    final idx = e.key;
                    final entry = e.value;
                    final pct = (entry.value / total * 100).round();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10, height: 10,
                            decoration: BoxDecoration(color: _colors[idx % _colors.length], borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(entry.key, style: const TextStyle(fontSize: 12))),
                          Text('$pct%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int total;
  final List<Color> colors;

  _PieChartPainter(this.entries, this.total, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    var startAngle = -pi / 2;

    for (var i = 0; i < entries.length; i++) {
      final sweepAngle = (entries[i].value / total) * 2 * pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      startAngle += sweepAngle;
    }

    // 도넛 구멍
    canvas.drawCircle(center, radius * 0.55, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 오늘 수업 테이블
class _TodayClassesTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('bookedAt', isLessThan: Timestamp.fromDate(todayEnd))
          .where('status', whereIn: ['confirmed', 'completed'])
          .orderBy('bookedAt')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('오늘 수업이 없습니다.', style: TextStyle(color: Colors.grey.shade500))),
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
                    _hdr('시간', 2), _hdr('과목', 3), _hdr('학생', 3), _hdr('선생님', 2), _hdr('상태', 2),
                  ],
                ),
              ),
              ...docs.map((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final t = (d['bookedAt'] as Timestamp?)?.toDate();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                  child: Row(
                    children: [
                      _cell(t != null ? DateFormat('HH:mm').format(t) : '-', 2),
                      _cell(d['subject'] ?? '-', 3),
                      _cell(_trunc(d['studentId'] ?? '-', 10), 3),
                      _cell(d['teacherName'] ?? '-', 2),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            d['status'] == 'completed' ? '완료' : '확정',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.secondaryColor),
                          ),
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

  static Widget _hdr(String t, int f) => Expanded(flex: f, child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceColor.withValues(alpha: 0.6))));
  static Widget _cell(String t, int f) => Expanded(flex: f, child: Text(t, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis));
  static String _trunc(String s, int m) => s.length > m ? '${s.substring(0, m)}...' : s;
}

class _MetricData {
  final String label, value;
  final IconData icon;
  final Color color;
  const _MetricData(this.label, this.value, this.icon, this.color);
}
