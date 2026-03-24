import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:westudy/models/booking_model.dart';
import 'package:westudy/services/booking_service.dart';
import 'package:westudy/utils/constants.dart';

/// 긴급변경권(Last Minute Transfer) 서비스
/// - 주 3회 제한
/// - 변경 시 LMT 1회 차감
/// - 소진 시 변경 불가
class LmtService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final BookingService _bookingService = BookingService();

  static const int weeklyLimit = 3;

  /// 이번 주 LMT 사용 횟수 조회
  Future<int> getWeeklyUsage(String studentId) async {
    final now = DateTime.now();
    // 이번 주 월요일
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final snap = await _db
        .collection(AppConstants.bookingsCollection)
        .where('studentId', isEqualTo: studentId)
        .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
        .where('bookedAt', isLessThan: Timestamp.fromDate(endOfWeek))
        .where('lmtUsed', isGreaterThan: 0)
        .get();

    int totalUsed = 0;
    for (final doc in snap.docs) {
      totalUsed += (doc.data()['lmtUsed'] as int?) ?? 0;
    }
    return totalUsed;
  }

  /// 남은 LMT 횟수
  Future<int> getRemainingLmt(String studentId) async {
    final used = await getWeeklyUsage(studentId);
    return (weeklyLimit - used).clamp(0, weeklyLimit);
  }

  /// LMT 사용 가능 여부
  Future<bool> canUseLmt(String studentId) async {
    final remaining = await getRemainingLmt(studentId);
    return remaining > 0;
  }

  /// 긴급 변경 실행
  /// - LMT 잔여 확인 → 기존 예약 취소 → 새 슬롯 예약 → LMT 차감
  Future<BookingModel> executeChange({
    required String bookingId,
    required String newSlotId,
    required String studentId,
  }) async {
    // LMT 잔여 확인
    final remaining = await getRemainingLmt(studentId);
    if (remaining <= 0) {
      throw LmtExhaustedException(
        '이번 주 긴급변경권을 모두 사용했습니다. (${weeklyLimit}회/$weeklyLimit회)',
      );
    }

    // 예약 변경 실행 (booking_service의 트랜잭션)
    final newBooking = await _bookingService.changeBooking(
      bookingId: bookingId,
      newSlotId: newSlotId,
    );

    return newBooking;
  }

  /// LMT 상태 정보 (UI용)
  Future<LmtStatus> getStatus(String studentId) async {
    final used = await getWeeklyUsage(studentId);
    final remaining = (weeklyLimit - used).clamp(0, weeklyLimit);
    return LmtStatus(
      weeklyLimit: weeklyLimit,
      used: used,
      remaining: remaining,
    );
  }
}

class LmtStatus {
  final int weeklyLimit;
  final int used;
  final int remaining;

  const LmtStatus({
    required this.weeklyLimit,
    required this.used,
    required this.remaining,
  });

  bool get canChange => remaining > 0;
  bool get isWarning => remaining == 1;
  bool get isExhausted => remaining <= 0;
}

class LmtExhaustedException implements Exception {
  final String message;
  LmtExhaustedException(this.message);

  @override
  String toString() => message;
}
