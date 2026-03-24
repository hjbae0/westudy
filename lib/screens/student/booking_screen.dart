import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:westudy/utils/theme.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedSubject = '수학';
  String? _selectedTime;

  final List<String> _subjects = ['수학', '영어', '국어', '과학', '사회'];

  // 30분 단위 시간 슬롯 (09:00 ~ 21:00)
  final List<String> _timeSlots = List.generate(24, (i) {
    final hour = 9 + i ~/ 2;
    final minute = (i % 2) * 30;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  });

  // 예약 불가 슬롯 (데모용)
  final Set<String> _unavailableSlots = {'10:00', '10:30', '14:00', '15:30', '16:00'};

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

            // 시간 슬롯 그리드
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
                  _buildTimeGrid(),
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
                  onPressed: _selectedTime != null
                      ? () {
                          _showConfirmDialog();
                        }
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
                  child: Text(
                    _selectedTime != null
                        ? '$_selectedSubject  |  $_selectedTime 예약하기'
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
            onTap: () => setState(() => _selectedDate = date),
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

  Widget _buildTimeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 2.2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _timeSlots.length,
      itemBuilder: (context, index) {
        final time = _timeSlots[index];
        final isUnavailable = _unavailableSlots.contains(time);
        final isSelected = time == _selectedTime;

        return GestureDetector(
          onTap: isUnavailable
              ? null
              : () => setState(() => _selectedTime = time),
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
            child: Center(
              child: Text(
                time,
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
            ),
          ),
        );
      },
    );
  }

  void _showConfirmDialog() {
    final dateStr = DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDate);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('예약 확인'),
        content: Text('$dateStr $_selectedTime\n$_selectedSubject 수업을 예약할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('예약이 완료되었습니다!')),
              );
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
}
