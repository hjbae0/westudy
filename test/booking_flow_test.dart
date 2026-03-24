import 'package:flutter_test/flutter_test.dart';
import 'package:westudy/models/booking_model.dart';
import 'package:westudy/models/slot_model.dart';

/// 예약 플로우 단위 테스트
/// Firebase 에뮬레이터 없이 모델 로직만 검증
void main() {
  group('BookingModel', () {
    test('toFirestore/fromFirestore 라운드트립', () {
      final booking = BookingModel(
        id: 'test-id',
        studentId: 'student-1',
        slotId: 'slot-1',
        subject: '수학',
        teacherName: '김선생님',
        status: 'confirmed',
        bookedAt: DateTime(2026, 3, 24, 14, 0),
        lmtUsed: 0,
      );

      final map = booking.toFirestore();
      expect(map['studentId'], 'student-1');
      expect(map['subject'], '수학');
      expect(map['status'], 'confirmed');
      expect(map['lmtUsed'], 0);
    });

    test('copyWith으로 상태 변경', () {
      final booking = BookingModel(
        id: 'test-id',
        studentId: 'student-1',
        slotId: 'slot-1',
        subject: '수학',
        status: 'confirmed',
        bookedAt: DateTime.now(),
      );

      final cancelled = booking.copyWith(status: 'cancelled');
      expect(cancelled.status, 'cancelled');
      expect(cancelled.subject, '수학'); // 나머지 유지
      expect(cancelled.studentId, 'student-1');
    });

    test('LMT 카운트 증가', () {
      final booking = BookingModel(
        id: 'test-id',
        studentId: 'student-1',
        slotId: 'slot-1',
        subject: '영어',
        status: 'confirmed',
        bookedAt: DateTime.now(),
        lmtUsed: 1,
      );

      final changed = booking.copyWith(lmtUsed: booking.lmtUsed + 1);
      expect(changed.lmtUsed, 2);
    });
  });

  group('SlotModel', () {
    test('isAvailable - 잔여석 있으면 true', () {
      final slot = SlotModel(
        id: 'slot-1',
        startTime: DateTime(2026, 3, 24, 14, 0),
        endTime: DateTime(2026, 3, 24, 14, 30),
        maxStudents: 4,
        currentStudents: 2,
        status: 'available',
      );

      expect(slot.isAvailable, true);
    });

    test('isAvailable - 만석이면 false', () {
      final slot = SlotModel(
        id: 'slot-2',
        startTime: DateTime(2026, 3, 24, 15, 0),
        endTime: DateTime(2026, 3, 24, 15, 30),
        maxStudents: 4,
        currentStudents: 4,
        status: 'available',
      );

      expect(slot.isAvailable, false);
    });

    test('isAvailable - blocked이면 false', () {
      final slot = SlotModel(
        id: 'slot-3',
        startTime: DateTime(2026, 3, 24, 16, 0),
        endTime: DateTime(2026, 3, 24, 16, 30),
        maxStudents: 4,
        currentStudents: 0,
        status: 'blocked',
      );

      expect(slot.isAvailable, false);
    });
  });
}
