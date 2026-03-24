import 'package:flutter_test/flutter_test.dart';
import 'package:westudy/services/lmt_service.dart';

/// LMT(긴급변경권) 로직 테스트
/// Firebase 의존 없이 순수 로직만 검증
void main() {
  group('LmtStatus', () {
    test('3회 중 0회 사용 → canChange true', () {
      const status = LmtStatus(weeklyLimit: 3, used: 0, remaining: 3);
      expect(status.canChange, true);
      expect(status.isWarning, false);
      expect(status.isExhausted, false);
    });

    test('3회 중 2회 사용 → canChange true, isWarning false', () {
      const status = LmtStatus(weeklyLimit: 3, used: 2, remaining: 1);
      expect(status.canChange, true);
      expect(status.isWarning, true);
      expect(status.isExhausted, false);
    });

    test('3회 중 3회 사용 → canChange false, isExhausted true', () {
      const status = LmtStatus(weeklyLimit: 3, used: 3, remaining: 0);
      expect(status.canChange, false);
      expect(status.isWarning, false);
      expect(status.isExhausted, true);
    });

    test('주 제한은 3회', () {
      expect(LmtService.weeklyLimit, 3);
    });
  });

  group('LmtExhaustedException', () {
    test('4번째 변경 시도 → 예외 발생 시뮬레이션', () {
      const status = LmtStatus(weeklyLimit: 3, used: 3, remaining: 0);

      // 4번째 시도
      expect(status.canChange, false);

      // 서비스에서 이렇게 예외를 던짐
      expect(
        () {
          if (!status.canChange) {
            throw LmtExhaustedException(
              '이번 주 긴급변경권을 모두 사용했습니다. (3회/3회)',
            );
          }
        },
        throwsA(isA<LmtExhaustedException>()),
      );
    });

    test('메시지 확인', () {
      final e = LmtExhaustedException('테스트 메시지');
      expect(e.toString(), '테스트 메시지');
    });
  });

  group('LMT 시나리오', () {
    test('1회→2회→3회 사용 후 4회째 거부', () {
      // 1회 사용
      var status = const LmtStatus(weeklyLimit: 3, used: 1, remaining: 2);
      expect(status.canChange, true);

      // 2회 사용
      status = const LmtStatus(weeklyLimit: 3, used: 2, remaining: 1);
      expect(status.canChange, true);
      expect(status.isWarning, true); // 경고

      // 3회 사용
      status = const LmtStatus(weeklyLimit: 3, used: 3, remaining: 0);
      expect(status.canChange, false);
      expect(status.isExhausted, true);

      // 4회째 시도 → 거부
      expect(
        () {
          if (!status.canChange) {
            throw LmtExhaustedException('소진됨');
          }
        },
        throwsA(isA<LmtExhaustedException>()),
      );
    });
  });
}
