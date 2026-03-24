import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:westudy/models/booking_model.dart';
import 'package:westudy/utils/constants.dart';
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
            // 지표 4개 카드 (Firestore 실시간)
            _buildMetricCards(),
            const SizedBox(height: 28),

            // 오늘 수업 테이블 (Firestore 실시간)
            const Text(
              '오늘 수업',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildTodayBookingsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCards() {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<List<QuerySnapshot>>(
      stream: _combineStreams(db, todayStart, todayEnd),
      builder: (context, snapshot) {
        String todayCount = '-';
        String studentCount = '-';
        String bookingRate = '-';
        String monthlyBookings = '-';

        if (snapshot.hasData) {
          final results = snapshot.data!;
          todayCount = '${results[0].docs.length}';
          studentCount = '${results[1].docs.length}';

          // 출석률: confirmed / (confirmed + cancelled) for today
          final todayAll = results[0].docs.length;
          final todayCancelled = results[2].docs.length;
          final total = todayAll + todayCancelled;
          if (total > 0) {
            bookingRate = '${((todayAll / total) * 100).round()}%';
          } else {
            bookingRate = '-';
          }

          monthlyBookings = '${results[3].docs.length}';
        }

        final metrics = [
          _MetricData('오늘 수업', todayCount, Icons.school_rounded, const Color(0xFF4A6FA5)),
          _MetricData('등록 학생', studentCount, Icons.people_rounded, const Color(0xFF6B9080)),
          _MetricData('출석률', bookingRate, Icons.check_circle_rounded, const Color(0xFFE17055)),
          _MetricData('이번 달', monthlyBookings, Icons.payments_rounded, const Color(0xFF6C5CE7)),
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
      },
    );
  }

  Stream<List<QuerySnapshot>> _combineStreams(
    FirebaseFirestore db,
    DateTime todayStart,
    DateTime todayEnd,
  ) {
    final monthStart = DateTime(todayStart.year, todayStart.month, 1);
    final monthEnd = DateTime(todayStart.year, todayStart.month + 1, 1);

    // 오늘 confirmed 예약
    final todayConfirmed = db
        .collection(AppConstants.bookingsCollection)
        .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('bookedAt', isLessThan: Timestamp.fromDate(todayEnd))
        .where('status', isEqualTo: 'confirmed')
        .snapshots();

    // 전체 학생 수
    final students = db
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'student')
        .snapshots();

    // 오늘 취소 예약 (출석률 계산용)
    final todayCancelled = db
        .collection(AppConstants.bookingsCollection)
        .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('bookedAt', isLessThan: Timestamp.fromDate(todayEnd))
        .where('status', isEqualTo: 'cancelled')
        .snapshots();

    // 이번 달 예약
    final monthlyBookings = db
        .collection(AppConstants.bookingsCollection)
        .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('bookedAt', isLessThan: Timestamp.fromDate(monthEnd))
        .where('status', isEqualTo: 'confirmed')
        .snapshots();

    // 4개 스트림을 결합
    return todayConfirmed.asyncMap((todaySnap) async {
      final studentSnap = await students.first;
      final cancelledSnap = await todayCancelled.first;
      final monthlySnap = await monthlyBookings.first;
      return [todaySnap, studentSnap, cancelledSnap, monthlySnap];
    });
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

  Widget _buildTodayBookingsTable() {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: db
          .collection(AppConstants.bookingsCollection)
          .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('bookedAt', isLessThan: Timestamp.fromDate(todayEnd))
          .where('status', whereIn: ['confirmed', 'completed'])
          .orderBy('bookedAt')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data?.docs
                .map((doc) => BookingModel.fromFirestore(doc))
                .toList() ??
            [];

        if (bookings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '오늘 예약된 수업이 없습니다.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }

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
                    _headerCell('학생ID', flex: 3),
                    _headerCell('상태', flex: 2),
                  ],
                ),
              ),
              // 테이블 행
              ...bookings.map((b) => _buildBookingRow(b)),
            ],
          ),
        );
      },
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

  Widget _buildBookingRow(BookingModel booking) {
    final timeStr = DateFormat('HH:mm').format(booking.bookedAt);
    final isCompleted = booking.status == 'completed';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(timeStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 3,
            child: Text(booking.subject, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              booking.studentId.length > 8
                  ? '${booking.studentId.substring(0, 8)}...'
                  : booking.studentId,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.secondaryColor.withValues(alpha: 0.1)
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                booking.status == 'confirmed' ? '확정' : '완료',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isCompleted ? AppTheme.secondaryColor : AppTheme.primaryColor,
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
