import 'package:flutter/material.dart';
import 'package:westudy/utils/theme.dart';

class ParentReportScreen extends StatelessWidget {
  const ParentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('학습 리포트', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 학생 정보 카드
            _buildStudentCard(),
            const SizedBox(height: 24),

            // 학습시간 & 출석률
            Row(
              children: [
                Expanded(child: _buildStatCard('이번 주 학습시간', '12시간 30분', Icons.timer_rounded, AppTheme.primaryColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('출석률', '94%', Icons.check_circle_rounded, AppTheme.secondaryColor)),
              ],
            ),
            const SizedBox(height: 24),

            // 과목별 진도
            const Text(
              '과목별 진도',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildSubjectProgress('수학', 0.78, const Color(0xFF4A6FA5), '78% · 이차함수 심화'),
            const SizedBox(height: 12),
            _buildSubjectProgress('영어', 0.65, const Color(0xFFE17055), '65% · 독해 Unit 8'),
            const SizedBox(height: 12),
            _buildSubjectProgress('국어', 0.82, const Color(0xFF6B9080), '82% · 현대시 분석'),
            const SizedBox(height: 12),
            _buildSubjectProgress('과학', 0.55, const Color(0xFF6C5CE7), '55% · 화학반응식'),
            const SizedBox(height: 24),

            // 최근 수업 기록
            const Text(
              '최근 수업 기록',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildRecentClass('3/24 (월)', '수학 심화', '김선생님', '이차함수 그래프 그리기', true),
            _buildRecentClass('3/22 (토)', '영어 독해', '이선생님', '지문 분석 연습', true),
            _buildRecentClass('3/21 (금)', '국어 문학', '박선생님', '현대시 3편 감상', false),
            _buildRecentClass('3/20 (목)', '수학 기초', '김선생님', '일차방정식 복습', true),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '김민준',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '중학교 2학년 · 수학/영어/국어/과학',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgress(String subject, double progress, Color color, String detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subject,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentClass(String date, String subject, String teacher, String topic, bool attended) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            attended ? Icons.check_circle : Icons.cancel,
            color: attended ? AppTheme.secondaryColor : AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(
                      teacher,
                      style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceColor.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  topic,
                  style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceColor.withValues(alpha: 0.6)),
                ),
              ],
            ),
          ),
          Text(
            date,
            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceColor.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }
}
