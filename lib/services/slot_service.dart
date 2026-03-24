import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:westudy/models/slot_model.dart';
import 'package:westudy/utils/constants.dart';

class SlotService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _slotsRef =>
      _db.collection(AppConstants.slotsCollection);

  // 하루치 30분 단위 슬롯 일괄 생성 (관리자용)
  Future<List<SlotModel>> generateDaySlots({
    required DateTime date,
    int startHour = 9,
    int endHour = 21,
    int maxStudents = 4,
  }) async {
    final batch = _db.batch();
    final slots = <SlotModel>[];

    for (var hour = startHour; hour < endHour; hour++) {
      for (var minute = 0; minute < 60; minute += 30) {
        final startTime = DateTime(date.year, date.month, date.day, hour, minute);
        final endTime = startTime.add(const Duration(minutes: 30));

        final ref = _slotsRef.doc();
        final slot = SlotModel(
          id: ref.id,
          startTime: startTime,
          endTime: endTime,
          maxStudents: maxStudents,
          currentStudents: 0,
          status: 'available',
        );

        batch.set(ref, slot.toFirestore());
        slots.add(slot);
      }
    }

    await batch.commit();
    return slots;
  }

  // 특정 날짜의 슬롯 조회
  Stream<List<SlotModel>> getSlotsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _slotsRef
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('startTime')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => SlotModel.fromFirestore(doc)).toList());
  }

  // 특정 날짜의 사용 가능한 슬롯만 조회
  Future<List<SlotModel>> getAvailableSlots(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _slotsRef
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .where('status', isEqualTo: 'available')
        .orderBy('startTime')
        .get();

    return snap.docs
        .map((doc) => SlotModel.fromFirestore(doc))
        .where((slot) => slot.isAvailable)
        .toList();
  }

  // 슬롯 상태 변경 (관리자용)
  Future<void> updateSlotStatus(String slotId, String status) async {
    if (!['available', 'booked', 'blocked'].contains(status)) {
      throw Exception('유효하지 않은 상태: $status');
    }
    await _slotsRef.doc(slotId).update({'status': status});
  }

  // 슬롯 차단 (관리자용 - 특정 시간대 예약 차단)
  Future<void> blockSlot(String slotId) async {
    await _slotsRef.doc(slotId).update({'status': 'blocked'});
  }

  // 슬롯 차단 해제
  Future<void> unblockSlot(String slotId) async {
    await _slotsRef.doc(slotId).update({'status': 'available'});
  }

  // 일주일치 슬롯 일괄 생성
  Future<void> generateWeekSlots({
    required DateTime startDate,
    int startHour = 9,
    int endHour = 21,
    int maxStudents = 4,
    List<int> excludeWeekdays = const [DateTime.sunday],
  }) async {
    for (var i = 0; i < 7; i++) {
      final date = startDate.add(Duration(days: i));
      if (excludeWeekdays.contains(date.weekday)) continue;

      await generateDaySlots(
        date: date,
        startHour: startHour,
        endHour: endHour,
        maxStudents: maxStudents,
      );
    }
  }

  // 슬롯 삭제 (관리자용)
  Future<void> deleteSlot(String slotId) async {
    await _slotsRef.doc(slotId).delete();
  }
}
