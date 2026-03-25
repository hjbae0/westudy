import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:westudy/models/booking_model.dart';
import 'package:westudy/models/user_model.dart';
import 'package:westudy/screens/student/ai_chat_screen.dart';
import 'package:westudy/services/auth_service.dart';
import 'package:westudy/services/booking_service.dart';
import 'package:westudy/services/lmt_service.dart';
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
          children: [
            const _HomeTab(),
            const AiChatScreen(),
            const _ScheduleTab(),
            const _ReportTab(),
            const _ProfileTab(),
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
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy_rounded),
            label: 'AI',
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

    return StreamBuilder<QuerySnapshot>(
      stream: user != null
          ? FirebaseFirestore.instance
              .collection(AppConstants.bookingsCollection)
              .where('studentId', isEqualTo: user.uid)
              .where('status', whereIn: ['confirmed', 'completed'])
              .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monday))
              .where('bookedAt', isLessThan: Timestamp.fromDate(friday))
              .snapshots()
          : null,
      builder: (context, snapshot) {
        final bookings = snapshot.data?.docs
                .map((doc) => BookingModel.fromFirestore(doc))
                .toList() ??
            [];

        final Map<int, List<BookingModel>> weekBookings = {};
        for (final b in bookings) {
          final weekday = b.bookedAt.weekday;
          weekBookings.putIfAbsent(weekday, () => []).add(b);
        }

        return _buildCalendarBody(context, weekDays, now, weekBookings);
      },
    );
  }

  Widget _buildCalendarBody(
    BuildContext context,
    List<DateTime> weekDays,
    DateTime now,
    Map<int, List<BookingModel>> weekBookings,
  ) {
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
                        context,
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

// ═══════════════════════════════════════════════════════════════════════
// 일정 탭 (Schedule Tab)
// ═══════════════════════════════════════════════════════════════════════
class _ScheduleTab extends StatefulWidget {
  const _ScheduleTab();

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  final BookingService _bookingService = BookingService();
  late DateTime _selectedDate;
  late DateTime _weekStart;

  static const Map<String, Color> _statusColors = {
    'confirmed': Color(0xFF27AE60),
    'pending': Color(0xFFF39C12),
    'cancelled': Color(0xFFE74C3C),
    'completed': Color(0xFF3498DB),
  };

  static const Map<String, String> _statusLabels = {
    'confirmed': '확정',
    'pending': '대기',
    'cancelled': '취소',
    'completed': '완료',
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _weekStart = _getMonday(_selectedDate);
  }

  DateTime _getMonday(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '일정',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                DateFormat('yyyy년 M월').format(_selectedDate),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 주간 캘린더
          _buildWeekCalendar(),
          const SizedBox(height: 20),

          // 선택된 날짜 표시
          Text(
            DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDate),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // 수업 목록
          if (user != null) _buildBookingList(user.uid),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    final weekDays = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // 이전 주 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _weekStart = _weekStart.subtract(const Duration(days: 7));
                _selectedDate = _weekStart;
              });
            },
            child: Icon(
              Icons.chevron_left_rounded,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.4),
              size: 22,
            ),
          ),
          ...weekDays.map((day) {
            final isSelected = day.year == _selectedDate.year &&
                day.month == _selectedDate.month &&
                day.day == _selectedDate.day;
            final isToday = day.year == now.year &&
                day.month == now.month &&
                day.day == now.day;
            final isSunday = day.weekday == DateTime.sunday;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDate = day),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E', 'ko_KR').format(day),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white70
                              : isSunday
                                  ? Colors.red.shade400
                                  : AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.2)
                              : isToday
                                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isToday && !isSelected
                              ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : isSunday
                                      ? Colors.red.shade400
                                      : AppTheme.onSurfaceColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          // 다음 주 버튼
          GestureDetector(
            onTap: () {
              setState(() {
                _weekStart = _weekStart.add(const Duration(days: 7));
                _selectedDate = _weekStart;
              });
            },
            child: Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.4),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(String studentId) {
    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.getStudentBookings(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allBookings = snapshot.data ?? [];

        // 선택된 날짜의 예약만 필터링
        final bookings = allBookings.where((b) {
          return b.bookedAt.year == _selectedDate.year &&
              b.bookedAt.month == _selectedDate.month &&
              b.bookedAt.day == _selectedDate.day;
        }).toList()
          ..sort((a, b) => a.bookedAt.compareTo(b.bookedAt));

        if (bookings.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: bookings.map((booking) => _buildBookingCard(booking)).toList(),
        );
      },
    );
  }

  Widget _buildBookingCard(BookingModel booking) {
    final statusColor = _statusColors[booking.status] ?? Colors.grey;
    final statusLabel = _statusLabels[booking.status] ?? booking.status;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 시간 표시
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                DateFormat('HH:mm').format(booking.bookedAt),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // 수업 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.subject,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  booking.teacherName ?? '선생님 미배정',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // 상태 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(
              '예약된 수업이 없습니다',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/student/booking'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  '수업 예약하기',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 리포트 탭 (Report Tab)
// ═══════════════════════════════════════════════════════════════════════
class _ReportTab extends StatefulWidget {
  const _ReportTab();

  @override
  State<_ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<_ReportTab> {
  final BookingService _bookingService = BookingService();

  static const List<String> _subjects = ['국어', '영어', '수학', '사회', '과학'];

  static const Map<String, Color> _subjectColors = {
    '국어': Color(0xFF27AE60),
    '영어': Color(0xFFF39C12),
    '수학': Color(0xFF3498DB),
    '사회': Color(0xFF8E44AD),
    '과학': Color(0xFFE74C3C),
  };

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          const Text(
            '리포트',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '나의 학습 현황을 확인해보세요',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),

          if (user != null)
            StreamBuilder<List<BookingModel>>(
              stream: _bookingService.getStudentBookings(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final allBookings = snapshot.data ?? [];
                final now = DateTime.now();
                final monday = now.subtract(Duration(days: now.weekday - 1));
                final startOfWeek = DateTime(monday.year, monday.month, monday.day);
                final endOfWeek = startOfWeek.add(const Duration(days: 7));

                // 이번 주 예약
                final weekBookings = allBookings.where((b) {
                  return b.bookedAt.isAfter(startOfWeek) &&
                      b.bookedAt.isBefore(endOfWeek);
                }).toList();

                // 확정/완료된 수업
                final confirmedBookings = weekBookings
                    .where((b) => b.status == 'confirmed' || b.status == 'completed')
                    .toList();

                // 완료된 수업
                final completedBookings = weekBookings
                    .where((b) => b.status == 'completed')
                    .toList();

                // 출석률 계산
                final attendanceRate = confirmedBookings.isNotEmpty
                    ? (completedBookings.length / confirmedBookings.length * 100)
                    : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 주간 요약 카드
                    _buildWeeklySummary(
                      classCount: confirmedBookings.length,
                      totalHours: confirmedBookings.length * 0.5,
                      attendanceRate: attendanceRate,
                    ),
                    const SizedBox(height: 24),

                    // 과목별 진도
                    const Text(
                      '과목별 수업 현황',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildSubjectProgress(allBookings),
                    const SizedBox(height: 24),

                    // 최근 수업 기록
                    const Text(
                      '최근 수업 기록',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    _buildRecentClasses(allBookings),
                    const SizedBox(height: 24),

                    // AI 학습 조언 카드
                    _buildAiAdviceCard(),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummary({
    required int classCount,
    required double totalHours,
    required double attendanceRate,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.insights_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '이번 주 요약',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: '수업 횟수',
                  value: '$classCount회',
                  icon: Icons.school_rounded,
                  color: const Color(0xFF3498DB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  label: '총 학습시간',
                  value: '${totalHours.toStringAsFixed(1)}시간',
                  icon: Icons.timer_rounded,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  label: '출석률',
                  value: '${attendanceRate.toStringAsFixed(0)}%',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF27AE60),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectProgress(List<BookingModel> allBookings) {
    // 과목별 수업 횟수 계산
    final Map<String, int> subjectCounts = {};
    for (final subject in _subjects) {
      subjectCounts[subject] = 0;
    }
    for (final booking in allBookings) {
      for (final subject in _subjects) {
        if (booking.subject.contains(subject)) {
          subjectCounts[subject] = (subjectCounts[subject] ?? 0) + 1;
        }
      }
    }

    final maxCount = subjectCounts.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: _subjects.map((subject) {
          final count = subjectCounts[subject] ?? 0;
          final ratio = maxCount > 0 ? count / maxCount : 0.0;
          final color = _subjectColors[subject] ?? AppTheme.primaryColor;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 14,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 32,
                  child: Text(
                    '$count회',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentClasses(List<BookingModel> allBookings) {
    // 최근 10개 수업
    final sorted = List<BookingModel>.from(allBookings)
      ..sort((a, b) => b.bookedAt.compareTo(a.bookedAt));
    final recent = sorted.take(10).toList();

    if (recent.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '수업 기록이 없습니다',
            style: TextStyle(
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: recent.asMap().entries.map((entry) {
          final index = entry.key;
          final booking = entry.value;
          final isLast = index == recent.length - 1;
          final statusColor = booking.status == 'confirmed'
              ? const Color(0xFF27AE60)
              : booking.status == 'completed'
                  ? const Color(0xFF3498DB)
                  : booking.status == 'cancelled'
                      ? const Color(0xFFE74C3C)
                      : const Color(0xFFF39C12);
          final statusLabel = booking.status == 'confirmed'
              ? '확정'
              : booking.status == 'completed'
                  ? '완료'
                  : booking.status == 'cancelled'
                      ? '취소'
                      : '대기';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: isLast
                  ? null
                  : Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              children: [
                // 날짜
                SizedBox(
                  width: 60,
                  child: Text(
                    DateFormat('M/d').format(booking.bookedAt),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                // 과목
                Expanded(
                  child: Text(
                    booking.subject,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                // 상태
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAiAdviceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI 학습 조언',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI 분석 준비 중입니다. 수업 데이터가 쌓이면 맞춤 조언을 제공합니다.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// 프로필 탭 (Profile Tab)
// ═══════════════════════════════════════════════════════════════════════
class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final LmtService _lmtService = LmtService();
  LmtStatus? _lmtStatus;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadLmtStatus();
  }

  Future<void> _loadLmtStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final status = await _lmtService.getStatus(user.uid);
      if (mounted) {
        setState(() => _lmtStatus = status);
      }
    } catch (_) {
      // LMT 로드 실패 시 무시
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userModel = authService.userModel;
    final firebaseUser = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          const Text(
            '내 정보',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // 프로필 헤더 카드
          _buildProfileHeader(userModel, firebaseUser),
          const SizedBox(height: 20),

          // 정보 섹션
          _buildInfoSection(userModel, firebaseUser),
          const SizedBox(height: 20),

          // LMT 상태
          _buildLmtSection(),
          const SizedBox(height: 20),

          // 설정 메뉴
          _buildSettingsSection(authService),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel? userModel, User? firebaseUser) {
    final name = userModel?.name ?? firebaseUser?.displayName ?? '사용자';
    final email = userModel?.email ?? firebaseUser?.email ?? '';
    final photoUrl = userModel?.profileImageUrl ?? firebaseUser?.photoURL;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // 아바타
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '학생',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(UserModel? userModel, User? firebaseUser) {
    final email = userModel?.email ?? firebaseUser?.email ?? '-';
    final createdAt = userModel?.createdAt;
    final role = userModel?.role ?? 'student';

    final roleLabels = {
      'student': '학생',
      'parent': '학부모',
      'admin': '관리자',
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계정 정보',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: '이메일',
            value: email,
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.calendar_month_outlined,
            label: '가입일',
            value: createdAt != null
                ? DateFormat('yyyy년 M월 d일').format(createdAt)
                : '-',
          ),
          const Divider(height: 20),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: '역할',
            value: roleLabels[role] ?? role,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.onSurfaceColor.withValues(alpha: 0.4),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildLmtSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '긴급변경권 (LMT)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (_lmtStatus != null)
                Text(
                  '${_lmtStatus!.remaining}/${_lmtStatus!.weeklyLimit}회 남음',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _lmtStatus!.isExhausted
                        ? AppTheme.errorColor
                        : _lmtStatus!.isWarning
                            ? const Color(0xFFE17055)
                            : AppTheme.secondaryColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (_lmtStatus != null)
            Row(
              children: List.generate(LmtService.weeklyLimit, (i) {
                final isUsed = i < _lmtStatus!.used;
                final color = _lmtStatus!.isExhausted
                    ? AppTheme.errorColor
                    : _lmtStatus!.isWarning
                        ? const Color(0xFFE17055)
                        : AppTheme.secondaryColor;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < LmtService.weeklyLimit - 1 ? 8 : 0),
                    height: 8,
                    decoration: BoxDecoration(
                      color: isUsed ? Colors.grey.shade200 : color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            )
          else
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            '매주 월요일 초기화됩니다',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.onSurfaceColor.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(AuthService authService) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // 알림 설정
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '알림 설정',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                  activeTrackColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),

          // 앱 정보
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '앱 정보',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Text(
                  'v${AppConstants.appVersion}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),

          // 로그아웃
          InkWell(
            onTap: () => _showLogoutDialog(authService),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: AppTheme.errorColor,
                  ),
                  SizedBox(width: 12),
                  Text(
                    '로그아웃',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthService authService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authService.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
}
