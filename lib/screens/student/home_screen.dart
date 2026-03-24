import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:westudy/models/booking_model.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/utils/theme.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            _HomeTab(),
            _ScheduleTab(),
            _ReportTab(),
            _ProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: '일정',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: '리포트',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}

// 홈 탭
class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WeStudy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '오늘도 화이팅!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          // 오늘 수업 목록
          const Text(
            '오늘 수업',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildClassCard('수학 심화', '14:00 - 15:00', '김선생님', Colors.blue),
          const SizedBox(height: 8),
          _buildClassCard('영어 독해', '16:00 - 17:00', '이선생님', Colors.orange),
          const SizedBox(height: 8),
          _buildClassCard('국어 문학', '18:00 - 19:00', '박선생님', Colors.green),
          const SizedBox(height: 28),

          // 이번 주 캘린더
          const Text(
            '이번 주 일정',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _WeekCalendar(),
          const SizedBox(height: 24),

          // 빠른 메뉴
          const Text(
            '빠른 메뉴',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildQuickMenu(context, Icons.calendar_month_rounded, '수업 예약', AppTheme.primaryColor),
              const SizedBox(width: 12),
              _buildQuickMenu(context, Icons.assignment_rounded, '학습 리포트', AppTheme.secondaryColor),
              const SizedBox(width: 12),
              _buildQuickMenu(context, Icons.notifications_rounded, '알림', const Color(0xFFE17055)),
              const SizedBox(width: 12),
              _buildQuickMenu(context, Icons.help_outline_rounded, '문의하기', const Color(0xFF6C5CE7)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildClassCard(String subject, String time, String teacher, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '$time  |  $teacher',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  static Widget _buildQuickMenu(BuildContext context, IconData icon, String label, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (label == '수업 예약') {
            context.go('/student/booking');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 이번 주 캘린더 (Calendly 스타일 타임라인 - Firestore 연동)
class _WeekCalendar extends StatelessWidget {
  static const int _startHour = 9;
  static const int _endHour = 21;
  static const double _hourHeight = 40.0;

  // 과목별 컬러
  static const Map<String, Color> _subjectColors = {
    '수학': Colors.blue,
    '영어': Colors.orange,
    '국어': Colors.green,
    '과학': Colors.purple,
    '사회': Colors.teal,
  };

  static Color _colorForSubject(String subject) {
    for (final entry in _subjectColors.entries) {
      if (subject.contains(entry.key)) return entry.value;
    }
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final friday = monday.add(const Duration(days: 5));
    final weekDays = List.generate(5, (i) => monday.add(Duration(days: i)));
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return _buildEmptyCalendar(weekDays, now);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .where('studentId', isEqualTo: user.uid)
          .where('status', whereIn: ['confirmed', 'completed'])
          .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monday))
          .where('bookedAt', isLessThan: Timestamp.fromDate(friday))
          .snapshots(),
      builder: (context, snapshot) {
        final bookings = snapshot.data?.docs
                .map((doc) => BookingModel.fromFirestore(doc))
                .toList() ??
            [];

        // 요일별로 그룹핑
        final Map<int, List<BookingModel>> weekBookings = {};
        for (final b in bookings) {
          final weekday = b.bookedAt.weekday;
          weekBookings.putIfAbsent(weekday, () => []).add(b);
        }

        return _buildCalendarBody(context, weekDays, now, weekBookings);
      },
    );
  }

  Widget _buildEmptyCalendar(List<DateTime> weekDays, DateTime now) {
    return _buildCalendarBody(null, weekDays, now, {});
  }

  Widget _buildCalendarBody(
    BuildContext? ctx,
    List<DateTime> weekDays,
    DateTime now,
    Map<int, List<BookingModel>> weekBookings,
  ) {
    final context = ctx ?? weekDays.first as dynamic; // fallback
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildDayHeader(weekDays, now),
          const Divider(height: 1),
          SizedBox(
            height: (_endHour - _startHour) * _hourHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeLabels(),
                ...weekDays.map((day) => Expanded(
                      child: _buildDayColumn(
                        ctx!,
                        day,
                        now,
                        weekBookings[day.weekday] ?? [],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(List<DateTime> weekDays, DateTime now) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 36),
          ...weekDays.map((day) {
            final isToday = day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;
            return Expanded(
              child: Column(
                children: [
                  Text(
                    DateFormat('E', 'ko_KR').format(day),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? AppTheme.primaryColor
                          : AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isToday ? AppTheme.primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isToday ? Colors.white : AppTheme.onSurfaceColor,
                        ),
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
  }

  Widget _buildTimeLabels() {
    return SizedBox(
      width: 36,
      child: Column(
        children: List.generate(_endHour - _startHour, (i) {
          final hour = _startHour + i;
          return SizedBox(
            height: _hourHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${hour.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.35),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(
    BuildContext context,
    DateTime day,
    DateTime now,
    List<BookingModel> bookings,
  ) {
    final isPast = day.isBefore(DateTime(now.year, now.month, now.day));

    return GestureDetector(
      onTap: isPast ? null : () => context.go('/student/booking'),
      child: Stack(
        children: [
          // 시간 구분선
          Column(
            children: List.generate(_endHour - _startHour, (i) {
              return Container(
                height: _hourHeight,
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade100, width: 0.5),
                    left: BorderSide(color: Colors.grey.shade100, width: 0.5),
                  ),
                ),
              );
            }),
          ),
          // Firestore 예약 블록
          ...bookings.map((booking) {
            final startMinutes =
                booking.bookedAt.hour * 60 + booking.bookedAt.minute - (_startHour * 60);
            // 30분 수업 기본
            const durationMinutes = 30;
            final top = startMinutes * _hourHeight / 60;
            final height = durationMinutes * _hourHeight / 60;
            final color = _colorForSubject(booking.subject);

            if (top < 0) return const SizedBox.shrink();

            return Positioned(
              top: top,
              left: 2,
              right: 2,
              height: height,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border(
                    left: BorderSide(color: color, width: 2.5),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.subject,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('HH:mm').format(booking.bookedAt),
                      style: TextStyle(
                        fontSize: 8,
                        color: color.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// 일정 탭 (placeholder)
class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('일정'));
  }
}

// 리포트 탭 (placeholder)
class _ReportTab extends StatelessWidget {
  const _ReportTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('리포트'));
  }
}

// 내 정보 탭 (placeholder)
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('내 정보'));
  }
}
