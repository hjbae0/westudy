import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/utils/theme.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  bool _isWeekView = false;
  DateTime _focusMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 상단 툴바
        _buildToolbar(),
        // 캘린더 + 수업 목록
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 좌: 캘린더
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _isWeekView ? _buildWeekView() : _buildMonthView(),
                ),
              ),
              // 우: 선택한 날짜 수업 목록
              Container(width: 1, color: Colors.grey.shade200),
              Expanded(
                flex: 2,
                child: _DaySidebar(
                  date: _selectedDate,
                  onAddClass: () => showClassForm(context, initialDate: _selectedDate),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // 월/주 토글
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('월간', style: TextStyle(fontSize: 13))),
              ButtonSegment(value: true, label: Text('주간', style: TextStyle(fontSize: 13))),
            ],
            selected: {_isWeekView},
            onSelectionChanged: (s) => setState(() => _isWeekView = s.first),
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 16),
          // 월 네비게이션
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: () => setState(() {
              _focusMonth = DateTime(_focusMonth.year, _focusMonth.month - 1);
            }),
          ),
          Text(
            DateFormat('yyyy년 M월', 'ko_KR').format(_focusMonth),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: () => setState(() {
              _focusMonth = DateTime(_focusMonth.year, _focusMonth.month + 1);
            }),
          ),
          TextButton(
            onPressed: () => setState(() {
              _focusMonth = DateTime(DateTime.now().year, DateTime.now().month);
              _selectedDate = DateTime.now();
            }),
            child: const Text('오늘'),
          ),
          const Spacer(),
          // 수업 추가
          ElevatedButton.icon(
            onPressed: () => showClassForm(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('수업 추가'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // 월간 캘린더
  Widget _buildMonthView() {
    final firstDay = DateTime(_focusMonth.year, _focusMonth.month, 1);
    final lastDay = DateTime(_focusMonth.year, _focusMonth.month + 1, 0);
    final startWeekday = firstDay.weekday; // 1=월
    final totalDays = lastDay.day;
    final startOffset = startWeekday - 1; // 월요일 시작

    final monthStart = firstDay.subtract(Duration(days: startOffset));
    final monthEnd = DateTime(_focusMonth.year, _focusMonth.month + 1, 1);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
          .where('bookedAt', isLessThan: Timestamp.fromDate(monthEnd.add(const Duration(days: 7))))
          .where('status', whereIn: ['confirmed', 'completed'])
          .snapshots(),
      builder: (context, snapshot) {
        // 날짜별 수업 개수 집계
        final dayCounts = <String, int>{};
        final daySubjects = <String, List<String>>{};
        for (final doc in snapshot.data?.docs ?? []) {
          final d = doc.data() as Map<String, dynamic>;
          final dt = (d['bookedAt'] as Timestamp?)?.toDate();
          if (dt == null) continue;
          final key = DateFormat('yyyy-MM-dd').format(dt);
          dayCounts[key] = (dayCounts[key] ?? 0) + 1;
          daySubjects.putIfAbsent(key, () => []).add(d['subject'] ?? '');
        }

        final weeks = ((startOffset + totalDays) / 7).ceil();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // 요일 헤더
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: ['월', '화', '수', '목', '금', '토', '일'].map((d) =>
                    Expanded(
                      child: Center(
                        child: Text(d, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: d == '일' ? Colors.red.shade400 : Colors.grey.shade600,
                        )),
                      ),
                    ),
                  ).toList(),
                ),
              ),
              const Divider(height: 1),
              // 주별 행
              ...List.generate(weeks, (week) {
                return Row(
                  children: List.generate(7, (weekday) {
                    final dayIndex = week * 7 + weekday - startOffset + 1;
                    if (dayIndex < 1 || dayIndex > totalDays) {
                      return Expanded(child: Container(height: 80));
                    }
                    final date = DateTime(_focusMonth.year, _focusMonth.month, dayIndex);
                    return Expanded(child: _buildDayCell(date, dayCounts, daySubjects));
                  }),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayCell(DateTime date, Map<String, int> counts, Map<String, List<String>> subjects) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final count = counts[key] ?? 0;
    final daySubjects = subjects[key] ?? [];
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _isSameDay(date, _selectedDate);
    final isSunday = date.weekday == DateTime.sunday;

    return GestureDetector(
      onTap: () => setState(() => _selectedDate = date),
      onDoubleTap: () => showClassForm(context, initialDate: date),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : null,
          border: Border.all(color: Colors.grey.shade100, width: 0.5),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                color: isToday ? AppTheme.primaryColor : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isToday ? Colors.white : isSunday ? Colors.red.shade400 : null,
                  ),
                ),
              ),
            ),
            // 수업 표시
            if (count > 0) ...[
              const SizedBox(height: 2),
              ...daySubjects.take(2).map((s) => Container(
                margin: const EdgeInsets.only(bottom: 1),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _subjectColor(s).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(s, style: TextStyle(fontSize: 9, color: _subjectColor(s)), maxLines: 1, overflow: TextOverflow.ellipsis),
              )),
              if (count > 2)
                Text('+${count - 2}', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            ],
          ],
        ),
      ),
    );
  }

  // 주간 뷰
  Widget _buildWeekView() {
    final now = _selectedDate;
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    final weekEnd = weekStart.add(const Duration(days: 7));

    const startHour = 9;
    const endHour = 21;
    const hourHeight = 50.0;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
          .where('bookedAt', isLessThan: Timestamp.fromDate(weekEnd))
          .where('status', whereIn: ['confirmed', 'completed'])
          .snapshots(),
      builder: (context, snapshot) {
        final bookings = snapshot.data?.docs ?? [];
        // 요일별 그룹
        final dayBookings = <int, List<QueryDocumentSnapshot>>{};
        for (final doc in bookings) {
          final d = doc.data() as Map<String, dynamic>;
          final dt = (d['bookedAt'] as Timestamp?)?.toDate();
          if (dt == null) continue;
          dayBookings.putIfAbsent(dt.weekday, () => []).add(doc);
        }

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // 요일 헤더
              Row(
                children: [
                  const SizedBox(width: 50),
                  ...weekDays.map((d) {
                    final isToday = _isSameDay(d, DateTime.now());
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedDate = d),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            children: [
                              Text(DateFormat('E', 'ko_KR').format(d), style: TextStyle(fontSize: 11, color: isToday ? AppTheme.primaryColor : Colors.grey.shade600)),
                              const SizedBox(height: 2),
                              Container(
                                width: 26, height: 26,
                                decoration: BoxDecoration(color: isToday ? AppTheme.primaryColor : Colors.transparent, shape: BoxShape.circle),
                                child: Center(child: Text('${d.day}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isToday ? Colors.white : null))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
              const Divider(height: 1),
              // 타임라인
              SizedBox(
                height: (endHour - startHour) * hourHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 시간 라벨
                    SizedBox(
                      width: 50,
                      child: Column(
                        children: List.generate(endHour - startHour, (i) => SizedBox(
                          height: hourHeight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2, right: 8),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: Text('${startHour + i}:00', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                            ),
                          ),
                        )),
                      ),
                    ),
                    // 7개 요일 열
                    ...weekDays.map((day) {
                      final classes = dayBookings[day.weekday] ?? [];
                      return Expanded(
                        child: DragTarget<Map<String, dynamic>>(
                          onAcceptWithDetails: (details) {
                            _handleDrop(context, details.data, day, details.offset, startHour, hourHeight);
                          },
                          builder: (context, candidateData, rejectedData) {
                            final isDropTarget = candidateData.isNotEmpty;
                            return GestureDetector(
                              onTap: () => showClassForm(context, initialDate: day),
                              child: Container(
                                color: isDropTarget ? AppTheme.primaryColor.withValues(alpha: 0.05) : null,
                                child: Stack(
                                  children: [
                                    // 시간선
                                    Column(
                                      children: List.generate(endHour - startHour, (i) => Container(
                                        height: hourHeight,
                                        decoration: BoxDecoration(border: Border(
                                          top: BorderSide(color: Colors.grey.shade100, width: 0.5),
                                          left: BorderSide(color: Colors.grey.shade100, width: 0.5),
                                        )),
                                      )),
                                    ),
                              // 수업 블록 (드래그 가능)
                              ...classes.map((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                final dt = (d['bookedAt'] as Timestamp).toDate();
                                final minutes = dt.hour * 60 + dt.minute - startHour * 60;
                                final top = minutes * hourHeight / 60;
                                final color = _subjectColor(d['subject'] ?? '');

                                final blockWidget = Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border(left: BorderSide(color: color, width: 3)),
                                  ),
                                  child: Text(
                                    '${d['subject'] ?? ''} ${DateFormat('HH:mm').format(dt)}',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                );

                                return Positioned(
                                  top: top.clamp(0, (endHour - startHour) * hourHeight - 30),
                                  left: 2, right: 2,
                                  height: 28,
                                  child: Draggable<Map<String, dynamic>>(
                                    data: {'docId': doc.id, ...d},
                                    feedback: Material(
                                      elevation: 4,
                                      borderRadius: BorderRadius.circular(4),
                                      child: SizedBox(width: 100, height: 28, child: blockWidget),
                                    ),
                                    childWhenDragging: Opacity(opacity: 0.3, child: blockWidget),
                                    child: GestureDetector(
                                      onTap: () => _showClassDetail(context, doc.id, d),
                                      child: blockWidget,
                                    ),
                                  ),
                                );
                              }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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

  // 드래그앤드롭 처리: 수업 시간 변경
  void _handleDrop(BuildContext context, Map<String, dynamic> data, DateTime targetDay, Offset dropOffset, int startHour, double hourHeight) async {
    final docId = data['docId'] as String?;
    if (docId == null) return;

    // 드롭 위치에서 시간 계산 (대략적)
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final localOffset = renderBox.globalToLocal(dropOffset);
    final minutesFromStart = (localOffset.dy / hourHeight * 60).round();
    final hour = startHour + minutesFromStart ~/ 60;
    final minute = (minutesFromStart % 60 ~/ 30) * 30; // 30분 단위 스냅

    final newTime = DateTime(targetDay.year, targetDay.month, targetDay.day, hour.clamp(startHour, 20), minute);
    final timeStr = DateFormat('M/d (E) HH:mm', 'ko_KR').format(newTime);

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('수업 시간 변경'),
        content: Text('${data['subject'] ?? '수업'}을(를)\n$timeStr(으)로 변경할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('변경'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection(AppConstants.bookingsCollection)
          .doc(docId)
          .update({'bookedAt': Timestamp.fromDate(newTime)});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수업이 $timeStr(으)로 변경되었습니다.')),
        );
      }
    }
  }

  void _showClassDetail(BuildContext context, String id, Map<String, dynamic> data) {
    final bookedAt = (data['bookedAt'] as Timestamp?)?.toDate();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(data['subject'] ?? '수업'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bookedAt != null) _detailRow('시간', DateFormat('M/d (E) HH:mm', 'ko_KR').format(bookedAt)),
            _detailRow('선생님', data['teacherName'] ?? '-'),
            _detailRow('상태', data['status'] ?? '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              showClassForm(context, editId: id, editData: data);
            },
            child: const Text('수정'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(AppConstants.bookingsCollection)
                  .doc(id)
                  .update({'status': 'cancelled'});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('취소', style: TextStyle(color: AppTheme.errorColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static Color _subjectColor(String subject) {
    if (subject.contains('수학')) return Colors.blue;
    if (subject.contains('영어')) return Colors.orange;
    if (subject.contains('국어')) return Colors.green;
    if (subject.contains('과학')) return Colors.purple;
    if (subject.contains('사회')) return Colors.teal;
    return AppTheme.primaryColor;
  }
}

// 오른쪽 사이드바: 선택 날짜 수업 목록
class _DaySidebar extends StatelessWidget {
  final DateTime date;
  final VoidCallback onAddClass;
  const _DaySidebar({required this.date, required this.onAddClass});

  @override
  Widget build(BuildContext context) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                DateFormat('M월 d일 (E)', 'ko_KR').format(date),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 22),
                color: AppTheme.primaryColor,
                onPressed: onAddClass,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection(AppConstants.bookingsCollection)
                .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
                .where('bookedAt', isLessThan: Timestamp.fromDate(dayEnd))
                .where('status', whereIn: ['confirmed', 'completed'])
                .orderBy('bookedAt')
                .snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_available, size: 40, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('수업이 없습니다', style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(height: 8),
                      TextButton(onPressed: onAddClass, child: const Text('수업 추가')),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i].data() as Map<String, dynamic>;
                  final dt = (d['bookedAt'] as Timestamp?)?.toDate();
                  final color = _ClassesPageState._subjectColor(d['subject'] ?? '');

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border(left: BorderSide(color: color, width: 3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(d['subject'] ?? '-', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text(dt != null ? DateFormat('HH:mm').format(dt) : '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(d['teacherName'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// 수업 추가/수정 폼 (외부에서 호출 가능)
void showClassForm(BuildContext context, {DateTime? initialDate, String? editId, Map<String, dynamic>? editData}) {
  final isEdit = editId != null;
  final formKey = GlobalKey<FormState>();
  final subjectC = TextEditingController(text: editData?['subject'] ?? '');
  final teacherNameC = TextEditingController(text: editData?['teacherName'] ?? '');
  String? selectedStudentId = editData?['studentId'];
  String? selectedTeacherId;
  DateTime selectedDate = initialDate ?? (editData?['bookedAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 1));
  TimeOfDay selectedTime = editData != null && editData['bookedAt'] != null
      ? TimeOfDay.fromDateTime((editData['bookedAt'] as Timestamp).toDate())
      : const TimeOfDay(hour: 14, minute: 0);
  String repeat = 'none'; // none, weekly, biweekly

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, ss) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? '수업 수정' : '수업 추가'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 학생 선택
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection(AppConstants.usersCollection)
                        .where('role', isEqualTo: 'student')
                        .snapshots(),
                    builder: (context, snap) {
                      final students = snap.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        decoration: _deco('학생 선택'),
                        value: selectedStudentId,
                        validator: (v) => v == null ? '학생을 선택하세요.' : null,
                        items: students.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(value: doc.id, child: Text(d['name'] ?? doc.id));
                        }).toList(),
                        onChanged: (v) => ss(() => selectedStudentId = v),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  // 선생님 선택
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('teachers').snapshots(),
                    builder: (context, snap) {
                      final teachers = snap.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        decoration: _deco('선생님 선택'),
                        value: selectedTeacherId,
                        items: teachers.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          return DropdownMenuItem(value: doc.id, child: Text(d['name'] ?? doc.id));
                        }).toList(),
                        onChanged: (v) {
                          ss(() => selectedTeacherId = v);
                          final doc = snap.data?.docs.firstWhere((d) => d.id == v);
                          if (doc != null) {
                            teacherNameC.text = (doc.data() as Map<String, dynamic>)['name'] ?? '';
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subjectC,
                    validator: (v) => (v == null || v.isEmpty) ? '과목을 입력하세요.' : null,
                    decoration: _deco('과목'),
                  ),
                  const SizedBox(height: 12),
                  // 날짜 + 시간
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(DateFormat('M/d (E)', 'ko_KR').format(selectedDate)),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: ctx, initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 180)),
                            );
                            if (picked != null) ss(() => selectedDate = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, size: 16),
                          label: Text('${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                          onPressed: () async {
                            final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                            if (picked != null) ss(() => selectedTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // 반복 설정
                  if (!isEdit)
                    DropdownButtonFormField<String>(
                      decoration: _deco('반복'),
                      value: repeat,
                      items: const [
                        DropdownMenuItem(value: 'none', child: Text('반복 없음')),
                        DropdownMenuItem(value: 'weekly', child: Text('매주')),
                        DropdownMenuItem(value: 'biweekly', child: Text('격주')),
                      ],
                      onChanged: (v) => ss(() => repeat = v ?? 'none'),
                    ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final bookedAt = DateTime(
                selectedDate.year, selectedDate.month, selectedDate.day,
                selectedTime.hour, selectedTime.minute,
              );
              final doc = {
                'studentId': selectedStudentId,
                'subject': subjectC.text.trim(),
                'teacherName': teacherNameC.text.trim(),
                'status': 'confirmed',
                'bookedAt': Timestamp.fromDate(bookedAt),
                'slotId': '',
                'lmtUsed': 0,
              };

              final ref = FirebaseFirestore.instance.collection(AppConstants.bookingsCollection);
              if (isEdit) {
                await ref.doc(editId).update(doc);
              } else {
                // 반복 생성
                final weeks = repeat == 'weekly' ? 8 : repeat == 'biweekly' ? 4 : 1;
                final interval = repeat == 'biweekly' ? 14 : 7;
                final batch = FirebaseFirestore.instance.batch();
                for (var i = 0; i < weeks; i++) {
                  final dt = bookedAt.add(Duration(days: repeat == 'none' ? 0 : i * interval));
                  batch.set(ref.doc(), {...doc, 'bookedAt': Timestamp.fromDate(dt)});
                }
                await batch.commit();
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: Text(isEdit ? '수정' : '추가'),
          ),
        ],
      ),
    ),
  );
}

InputDecoration _deco(String label) => InputDecoration(
  labelText: label,
  filled: true,
  fillColor: AppTheme.backgroundColor,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
);
