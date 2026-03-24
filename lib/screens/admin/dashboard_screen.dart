import 'package:flutter/material.dart';
import 'package:westudy/utils/theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('관리자 대시보드', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 지표 4개 카드
            _buildMetricCards(),
            const SizedBox(height: 28),

            // 오늘 수업 테이블
            const Text(
              '오늘 수업',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildClassTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    final metrics = [
      _MetricData('오늘 수업', '12', Icons.school_rounded, const Color(0xFF4A6FA5)),
      _MetricData('등록 학생', '48', Icons.people_rounded, const Color(0xFF6B9080)),
      _MetricData('출석률', '94%', Icons.check_circle_rounded, const Color(0xFFE17055)),
      _MetricData('이번 달 매출', '₩3.2M', Icons.payments_rounded, const Color(0xFF6C5CE7)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: metrics.map((m) => _buildMetricCard(m)).toList(),
    );
  }

  Widget _buildMetricCard(_MetricData metric) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                metric.label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(metric.icon, color: metric.color, size: 20),
              ),
            ],
          ),
          Text(
            metric.value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassTable() {
    final classes = [
      _ClassRow('14:00', '수학 심화', '김민준', '김선생님', '진행중'),
      _ClassRow('15:00', '영어 독해', '이서윤', '이선생님', '대기'),
      _ClassRow('16:00', '국어 문학', '박지호', '박선생님', '대기'),
      _ClassRow('17:00', '수학 기초', '최수아', '김선생님', '대기'),
      _ClassRow('18:00', '과학 실험', '정예준', '최선생님', '대기'),
      _ClassRow('19:00', '영어 회화', '한서연', '이선생님', '대기'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                _headerCell('시간', flex: 2),
                _headerCell('과목', flex: 3),
                _headerCell('학생', flex: 2),
                _headerCell('강사', flex: 2),
                _headerCell('상태', flex: 2),
              ],
            ),
          ),
          // 테이블 행
          ...classes.map((c) => _buildTableRow(c)),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildTableRow(_ClassRow cls) {
    final isActive = cls.status == '진행중';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(cls.time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(cls.subject, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(cls.student, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(cls.teacher, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                cls.status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppTheme.secondaryColor : Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _MetricData(this.label, this.value, this.icon, this.color);
}

class _ClassRow {
  final String time;
  final String subject;
  final String student;
  final String teacher;
  final String status;
  const _ClassRow(this.time, this.subject, this.student, this.teacher, this.status);
}
