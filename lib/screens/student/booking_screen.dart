import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:westudy/models/slot_model.dart';
import 'package:westudy/services/booking_service.dart';
import 'package:westudy/services/slot_service.dart';
import 'package:westudy/utils/theme.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedSubject = '수학';
  SlotModel? _selectedSlot;
  bool _isLoading = false;

  final List<String> _subjects = ['수학', '영어', '국어', '과학', '사회'];
  final BookingService _bookingService = BookingService();
  final SlotService _slotService = SlotService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('수업 예약', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 선택
            _buildDateSelector(),
            const SizedBox(height: 20),

            // 과목 선택 칩
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '과목 선택',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _subjects.map((subject) {
                      final isSelected = subject == _selectedSubject;
                      return ChoiceChip(
                        label: Text(subject),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedSubject = subject);
                        },
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.onSurfaceColor,
                          fontWeight: FontWeight.w500,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 시간 슬롯 그리드 (Firestore 연동)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '시간 선택',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '30분 단위로 선택하세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSlotGrid(),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 예약 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _selectedSlot != null && !_isLoading
                      ? () => _showConfirmDialog()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _selectedSlot != null
                              ? '$_selectedSubject  |  ${DateFormat('HH:mm').format(_selectedSlot!.startTime)} 예약하기'
                              : '시간을 선택하세요',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    final now = DateTime.now();
    final dates = List.generate(14, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;
          final isToday = date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
          final isSunday = date.weekday == DateTime.sunday;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _selectedSlot = null;
              });
            },
            child: Container(
              width: 56,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: isToday && !isSelected
                    ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E', 'ko_KR').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white70
                          : isSunday
                              ? Colors.red.shade400
                              : AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : isSunday
                              ? Colors.red.shade400
                              : AppTheme.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('M월').format(date),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected
                          ? Colors.white70
                          : AppTheme.onSurfaceColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotGrid() {
    return StreamBuilder<List<SlotModel>>(
      stream: _slotService.getSlotsByDate(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final slots = snapshot.data ?? [];

        // Firestore에 슬롯이 없으면 기본 타임테이블 표시
        if (slots.isEmpty) {
          return _buildDefaultTimeGrid();
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 2.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: slots.length,
          itemBuilder: (context, index) {
            final slot = slots[index];
            final timeStr = DateFormat('HH:mm').format(slot.startTime);
            final isUnavailable = !slot.isAvailable;
            final isSelected = _selectedSlot?.id == slot.id;

            return GestureDetector(
              onTap: isUnavailable
                  ? null
                  : () => setState(() => _selectedSlot = slot),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : isUnavailable
                          ? Colors.grey.shade100
                          : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : isUnavailable
                            ? Colors.grey.shade200
                            : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? Colors.white
                            : isUnavailable
                                ? Colors.grey.shade400
                                : AppTheme.onSurfaceColor,
                      ),
                    ),
                    if (!isUnavailable)
                      Text(
                        '${slot.currentStudents}/${slot.maxStudents}',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Firestore에 슬롯이 없을 때 기본 그리드 (오프라인/데모)
  Widget _buildDefaultTimeGrid() {
    final timeSlots = List.generate(24, (i) {
      final hour = 9 + i ~/ 2;
      final minute = (i % 2) * 30;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    });

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: timeSlots.length,
      itemBuilder: (context, index) {
        final time = timeSlots[index];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Text(
              time,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ),
        );
      },
    );
  }

  void _showConfirmDialog() {
    final dateStr = DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDate);
    final timeStr = DateFormat('HH:mm').format(_selectedSlot!.startTime);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('예약 확인'),
        content: Text('$dateStr $timeStr\n$_selectedSubject 수업을 예약할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _createBooking();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('예약'),
          ),
        ],
      ),
    );
  }

  Future<void> _createBooking() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('로그인이 필요합니다.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _bookingService.createBooking(
        studentId: user.uid,
        slotId: _selectedSlot!.id,
        subject: _selectedSubject,
      );
      _showSnackBar('예약이 완료되었습니다!');
      setState(() => _selectedSlot = null);
    } catch (e) {
      _showSnackBar('예약 실패: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
