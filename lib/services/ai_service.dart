import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:westudy/models/booking_model.dart';
import 'package:westudy/models/slot_model.dart';
import 'package:westudy/utils/constants.dart';

class AiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 자연어 → 의도 파악 → 응답
  Future<AiResponse> processMessage(String input) async {
    final normalized = input.trim().toLowerCase();
    final intent = _parseIntent(normalized);

    switch (intent.type) {
      case IntentType.book:
        return _handleBook(intent);
      case IntentType.cancel:
        return _handleCancel(intent);
      case IntentType.change:
        return _handleChange(intent);
      case IntentType.query:
        return _handleQuery(intent);
      case IntentType.available:
        return _handleAvailable(intent);
      case IntentType.unknown:
        return AiResponse(
          message: '이해하지 못했어요. "내일 수학 잡아줘", "이번 주 일정", "빈 시간 알려줘" 같이 말해보세요.',
        );
    }
  }

  // 의도 파싱
  ParsedIntent _parseIntent(String input) {
    String? subject;
    String? dayKeyword;
    IntentType type = IntentType.unknown;

    // 과목 추출
    final subjects = ['수학', '영어', '국어', '과학', '사회'];
    for (final s in subjects) {
      if (input.contains(s)) {
        subject = s;
        break;
      }
    }

    // 날짜 키워드 추출
    final dayKeywords = ['오늘', '내일', '모레', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일',
      '이번 주', '다음 주'];
    for (final d in dayKeywords) {
      if (input.contains(d)) {
        dayKeyword = d;
        break;
      }
    }

    // 의도 판별
    if (input.contains('잡아') || input.contains('예약') || input.contains('넣어') || input.contains('신청')) {
      type = IntentType.book;
    } else if (input.contains('취소') || input.contains('빼') || input.contains('없애')) {
      type = IntentType.cancel;
    } else if (input.contains('변경') || input.contains('바꿔') || input.contains('옮겨')) {
      type = IntentType.change;
    } else if (input.contains('일정') || input.contains('스케줄') || input.contains('뭐 있') || input.contains('알려')) {
      if (input.contains('빈') || input.contains('가능')) {
        type = IntentType.available;
      } else {
        type = IntentType.query;
      }
    } else if (input.contains('빈') || input.contains('가능') || input.contains('언제')) {
      type = IntentType.available;
    }

    return ParsedIntent(type: type, subject: subject, dayKeyword: dayKeyword);
  }

  // 날짜 키워드 → DateTime
  DateTime _resolveDate(String? keyword) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (keyword == null) return today.add(const Duration(days: 1));

    switch (keyword) {
      case '오늘':
        return today;
      case '내일':
        return today.add(const Duration(days: 1));
      case '모레':
        return today.add(const Duration(days: 2));
      case '이번 주':
        return today;
      case '다음 주':
        final monday = today.add(Duration(days: 8 - today.weekday));
        return monday;
      default:
        // 요일 처리
        final weekdays = {'월요일': 1, '화요일': 2, '수요일': 3, '목요일': 4, '금요일': 5, '토요일': 6};
        final targetWeekday = weekdays[keyword];
        if (targetWeekday != null) {
          var diff = targetWeekday - today.weekday;
          if (diff <= 0) diff += 7;
          return today.add(Duration(days: diff));
        }
        return today.add(const Duration(days: 1));
    }
  }

  // 실기 레슨 시간 (자동 제외)
  static const Set<String> _practiceHours = {'12:00', '12:30', '13:00', '13:30'};

  // 빈 슬롯 검색
  Future<List<SlotModel>> _findAvailableSlots(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _db
        .collection(AppConstants.slotsCollection)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'available')
        .orderBy('startTime')
        .get();

    return snap.docs
        .map((doc) => SlotModel.fromFirestore(doc))
        .where((slot) => slot.isAvailable)
        .where((slot) {
          // 실기 레슨 시간 제외
          final timeStr = DateFormat('HH:mm').format(slot.startTime);
          return !_practiceHours.contains(timeStr);
        })
        .toList();
  }

  // 내 예약 조회
  Future<List<BookingModel>> _getMyBookings({DateTime? from, DateTime? to}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    var query = _db
        .collection(AppConstants.bookingsCollection)
        .where('studentId', isEqualTo: user.uid)
        .where('status', whereIn: ['confirmed', 'pending']);

    if (from != null) {
      query = query.where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      query = query.where('bookedAt', isLessThan: Timestamp.fromDate(to));
    }

    final snap = await query.orderBy('bookedAt').get();
    return snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
  }

  // 예약 처리
  Future<AiResponse> _handleBook(ParsedIntent intent) async {
    final date = _resolveDate(intent.dayKeyword);
    final dayStr = DateFormat('M월 d일 (E)', 'ko_KR').format(date);
    final subject = intent.subject ?? '수학';

    final slots = await _findAvailableSlots(date);

    if (slots.isEmpty) {
      return AiResponse(
        message: '$dayStr에는 빈 시간이 없어요.\n다른 날짜를 말씀해주세요.',
      );
    }

    // 최적 시간 추천 (오후 2~6시 선호)
    final preferred = slots.where((s) {
      final h = s.startTime.hour;
      return h >= 14 && h <= 18;
    }).toList();

    final recommend = (preferred.isNotEmpty ? preferred : slots).take(3).toList();

    return AiResponse(
      message: '$dayStr $subject 수업이요! 빈 시간을 찾았어요.\n원하는 시간을 탭하세요:',
      recommendedSlots: recommend.map((s) => RecommendedSlot(
        slotId: s.id,
        day: dayStr,
        time: DateFormat('HH:mm').format(s.startTime),
        subject: subject,
        remaining: s.maxStudents - s.currentStudents,
      )).toList(),
    );
  }

  // 취소 처리
  Future<AiResponse> _handleCancel(ParsedIntent intent) async {
    final date = _resolveDate(intent.dayKeyword);
    final dayStr = DateFormat('M월 d일 (E)', 'ko_KR').format(date);
    final endDate = date.add(const Duration(days: 1));

    final bookings = await _getMyBookings(from: date, to: endDate);

    if (bookings.isEmpty) {
      return AiResponse(message: '$dayStr에 예약된 수업이 없어요.');
    }

    // 과목 필터
    final filtered = intent.subject != null
        ? bookings.where((b) => b.subject.contains(intent.subject!)).toList()
        : bookings;

    if (filtered.isEmpty) {
      return AiResponse(message: '$dayStr ${intent.subject} 수업은 예약되어 있지 않아요.');
    }

    final b = filtered.first;
    return AiResponse(
      message: '${DateFormat('HH:mm').format(b.bookedAt)} ${b.subject} 수업을 취소할까요?\n취소하려면 "네"라고 말씀해주세요.',
    );
  }

  // 변경 처리
  Future<AiResponse> _handleChange(ParsedIntent intent) async {
    return AiResponse(
      message: '수업 변경은 긴급변경권(LMT)이 필요해요.\n변경하고 싶은 수업과 원하는 시간을 알려주세요.\n\n예) "내일 수학을 금요일로 옮겨줘"',
    );
  }

  // 일정 조회
  Future<AiResponse> _handleQuery(ParsedIntent intent) async {
    final date = _resolveDate(intent.dayKeyword);
    final isWeek = intent.dayKeyword == '이번 주' || intent.dayKeyword == '다음 주';

    DateTime from, to;
    if (isWeek) {
      final monday = date.subtract(Duration(days: date.weekday - 1));
      from = DateTime(monday.year, monday.month, monday.day);
      to = from.add(const Duration(days: 5));
    } else {
      from = DateTime(date.year, date.month, date.day);
      to = from.add(const Duration(days: 1));
    }

    final bookings = await _getMyBookings(from: from, to: to);
    final label = isWeek
        ? '${DateFormat('M/d').format(from)}~${DateFormat('M/d').format(to)}'
        : DateFormat('M월 d일 (E)', 'ko_KR').format(date);

    if (bookings.isEmpty) {
      return AiResponse(message: '$label 예약된 수업이 없어요.');
    }

    final lines = bookings.map((b) {
      return '• ${DateFormat('M/d (E) HH:mm', 'ko_KR').format(b.bookedAt)} ${b.subject}';
    }).join('\n');

    return AiResponse(message: '$label 수업 일정이에요:\n\n$lines');
  }

  // 빈 시간 조회
  Future<AiResponse> _handleAvailable(ParsedIntent intent) async {
    final date = _resolveDate(intent.dayKeyword);
    final dayStr = DateFormat('M월 d일 (E)', 'ko_KR').format(date);

    final slots = await _findAvailableSlots(date);

    if (slots.isEmpty) {
      return AiResponse(message: '$dayStr에는 빈 시간이 없어요.');
    }

    final times = slots.take(8).map((s) {
      final t = DateFormat('HH:mm').format(s.startTime);
      return '$t (${s.maxStudents - s.currentStudents}석)';
    }).join(', ');

    return AiResponse(
      message: '$dayStr 빈 시간이에요:\n$times\n\n예약하려면 "내일 수학 잡아줘" 처럼 말해보세요.',
    );
  }
}

// 응답 모델
class AiResponse {
  final String message;
  final List<RecommendedSlot>? recommendedSlots;

  AiResponse({required this.message, this.recommendedSlots});
}

class RecommendedSlot {
  final String slotId;
  final String day;
  final String time;
  final String subject;
  final int remaining;

  RecommendedSlot({
    required this.slotId,
    required this.day,
    required this.time,
    required this.subject,
    required this.remaining,
  });
}

// 의도 모델
enum IntentType { book, cancel, change, query, available, unknown }

class ParsedIntent {
  final IntentType type;
  final String? subject;
  final String? dayKeyword;

  ParsedIntent({required this.type, this.subject, this.dayKeyword});
}
