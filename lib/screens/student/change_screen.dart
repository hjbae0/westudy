import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:westudy/models/booking_model.dart';
import 'package:westudy/models/slot_model.dart';
import 'package:westudy/services/booking_service.dart';
import 'package:westudy/services/lmt_service.dart';
import 'package:westudy/services/slot_service.dart';
import 'package:westudy/utils/theme.dart';

class ChangeScreen extends StatefulWidget {
  const ChangeScreen({super.key});

  @override
  State<ChangeScreen> createState() => _ChangeScreenState();
}

class _ChangeScreenState extends State<ChangeScreen> {
  final BookingService _bookingService = BookingService();
  final LmtService _lmtService = LmtService();
  final SlotService _slotService = SlotService();

  BookingModel? _selectedBooking;
  SlotModel? _selectedNewSlot;
  DateTime _selectedDate = DateTime.now();
  LmtStatus? _lmtStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLmtStatus();
  }

  Future<void> _loadLmtStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final status = await _lmtService.getStatus(user.uid);
    setState(() => _lmtStatus = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('수업 변경', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LMT 상태 카드
            _buildLmtStatusCard(),
            const SizedBox(height: 24),

            // Step 1: 변경할 수업 선택
            const Text(
              '변경할 수업 선택',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildMyBookingsList(),
            const SizedBox(height: 24),

            // Step 2: 대체 시간 선택
            if (_selectedBooking != null) ...[
              const Text(
                '대체 시간 선택',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              _buildDateChips(),
              const SizedBox(height: 12),
              _buildAvailableSlots(),
              const SizedBox(height: 24),

              // 변경 버튼
              if (_selectedNewSlot != null)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _lmtStatus?.canChange == true && !_isLoading
                        ? _executeChange
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
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            '${DateFormat('HH:mm').format(_selectedNewSlot!.startTime)}으로 변경 (LMT 1회 사용)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLmtStatusCard() {
    if (_lmtStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final status = _lmtStatus!;
    Color statusColor;
    String statusText;

    if (status.isExhausted) {
      statusColor = AppTheme.errorColor;
      statusText = '소진됨 - 이번 주 변경 불가';
    } else if (status.isWarning) {
      statusColor = const Color(0xFFE17055);
      statusText = '주의 - 1회 남음';
    } else {
      statusColor = AppTheme.secondaryColor;
      statusText = '사용 가능';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.swap_horiz_rounded, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '긴급변경권 (LMT)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText,
                  style: TextStyle(fontSize: 12, color: statusColor),
                ),
              ],
            ),
          ),
          // 잔여 횟수 표시
          Row(
            children: List.generate(LmtService.weeklyLimit, (i) {
              final isUsed = i < status.used;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isUsed ? Colors.grey.shade200 : statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isUsed ? Icons.close : Icons.check,
                    size: 14,
                    color: isUsed ? Colors.grey.shade400 : statusColor,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBookingsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('로그인이 필요합니다.');
    }

    return StreamBuilder<List<BookingModel>>(
      stream: _bookingService.getStudentBookings(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '변경 가능한 수업이 없습니다.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
        }

        return Column(
          children: bookings.map((booking) {
            final isSelected = _selectedBooking?.id == booking.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBooking = booking;
                  _selectedNewSlot = null;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: booking.id,
                      groupValue: _selectedBooking?.id,
                      onChanged: (val) {
                        setState(() {
                          _selectedBooking = booking;
                          _selectedNewSlot = null;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.subject,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('M/d (E) HH:mm', 'ko_KR').format(booking.bookedAt),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.status,
                        style: const TextStyle(fontSize: 11, color: AppTheme.secondaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDateChips() {
    final now = DateTime.now();
    final dates = List.generate(7, (i) => now.add(Duration(days: i)));

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(DateFormat('M/d (E)', 'ko_KR').format(date)),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedDate = date;
                  _selectedNewSlot = null;
                });
              },
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : AppTheme.onSurfaceColor,
              ),
              backgroundColor: Colors.white,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvailableSlots() {
    return StreamBuilder<List<SlotModel>>(
      stream: _slotService.getSlotsByDate(_selectedDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final slots = (snapshot.data ?? []).where((s) => s.isAvailable).toList();

        if (slots.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '가용 시간이 없습니다.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          );
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
            final isSelected = _selectedNewSlot?.id == slot.id;

            return GestureDetector(
              onTap: () => setState(() => _selectedNewSlot = slot),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
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
                        color: isSelected ? Colors.white : AppTheme.onSurfaceColor,
                      ),
                    ),
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

  Future<void> _executeChange() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedBooking == null || _selectedNewSlot == null) return;

    setState(() => _isLoading = true);

    try {
      await _lmtService.executeChange(
        bookingId: _selectedBooking!.id,
        newSlotId: _selectedNewSlot!.id,
        studentId: user.uid,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('수업이 변경되었습니다.')),
      );

      setState(() {
        _selectedBooking = null;
        _selectedNewSlot = null;
      });
      _loadLmtStatus();
    } on LmtExhaustedException catch (e) {
      if (!mounted) return;
      _showExhaustedDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('변경 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showExhaustedDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('변경 불가'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
