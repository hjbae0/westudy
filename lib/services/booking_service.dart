import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:westudy/models/booking_model.dart';
import 'package:westudy/utils/constants.dart';

class BookingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _bookingsRef =>
      _db.collection(AppConstants.bookingsCollection);

  CollectionReference get _slotsRef =>
      _db.collection(AppConstants.slotsCollection);

  // 예약 생성
  Future<BookingModel> createBooking({
    required String studentId,
    required String slotId,
    required String subject,
    String? teacherName,
    String? note,
  }) async {
    return _db.runTransaction((transaction) async {
      // 슬롯 확인
      final slotDoc = await transaction.get(_slotsRef.doc(slotId));
      if (!slotDoc.exists) throw Exception('슬롯이 존재하지 않습니다.');

      final slotData = slotDoc.data() as Map<String, dynamic>;
      final currentStudents = slotData['currentStudents'] ?? 0;
      final maxStudents = slotData['maxStudents'] ?? 0;
      final isAvailable = slotData['isAvailable'] ?? false;

      if (!isAvailable || currentStudents >= maxStudents) {
        throw Exception('예약 가능한 슬롯이 아닙니다.');
      }

      // 중복 예약 확인
      final existing = await _bookingsRef
          .where('studentId', isEqualTo: studentId)
          .where('slotId', isEqualTo: slotId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('이미 예약된 시간입니다.');
      }

      // 예약 생성
      final bookingRef = _bookingsRef.doc();
      final booking = BookingModel(
        id: bookingRef.id,
        studentId: studentId,
        slotId: slotId,
        subject: subject,
        teacherName: teacherName,
        status: 'confirmed',
        bookedAt: DateTime.now(),
        note: note,
      );

      transaction.set(bookingRef, booking.toFirestore());

      // 슬롯 인원 증가
      transaction.update(_slotsRef.doc(slotId), {
        'currentStudents': FieldValue.increment(1),
      });

      return booking;
    });
  }

  // 예약 취소
  Future<void> cancelBooking(String bookingId) async {
    return _db.runTransaction((transaction) async {
      final bookingDoc = await transaction.get(_bookingsRef.doc(bookingId));
      if (!bookingDoc.exists) throw Exception('예약이 존재하지 않습니다.');

      final data = bookingDoc.data() as Map<String, dynamic>;
      final status = data['status'];
      if (status == 'cancelled') throw Exception('이미 취소된 예약입니다.');

      final slotId = data['slotId'];

      transaction.update(_bookingsRef.doc(bookingId), {
        'status': 'cancelled',
      });

      // 슬롯 인원 감소
      transaction.update(_slotsRef.doc(slotId), {
        'currentStudents': FieldValue.increment(-1),
      });
    });
  }

  // 예약 변경 (기존 취소 + 새 예약)
  Future<BookingModel> changeBooking({
    required String bookingId,
    required String newSlotId,
  }) async {
    return _db.runTransaction((transaction) async {
      // 기존 예약 조회
      final oldBookingDoc = await transaction.get(_bookingsRef.doc(bookingId));
      if (!oldBookingDoc.exists) throw Exception('예약이 존재하지 않습니다.');
      final oldBooking = BookingModel.fromFirestore(oldBookingDoc);

      // 새 슬롯 확인
      final newSlotDoc = await transaction.get(_slotsRef.doc(newSlotId));
      if (!newSlotDoc.exists) throw Exception('슬롯이 존재하지 않습니다.');

      final newSlotData = newSlotDoc.data() as Map<String, dynamic>;
      if (!(newSlotData['isAvailable'] ?? false) ||
          (newSlotData['currentStudents'] ?? 0) >= (newSlotData['maxStudents'] ?? 0)) {
        throw Exception('선택한 시간은 예약 불가능합니다.');
      }

      // 기존 예약 취소
      transaction.update(_bookingsRef.doc(bookingId), {'status': 'cancelled'});
      transaction.update(_slotsRef.doc(oldBooking.slotId), {
        'currentStudents': FieldValue.increment(-1),
      });

      // 새 예약 생성
      final newBookingRef = _bookingsRef.doc();
      final newBooking = BookingModel(
        id: newBookingRef.id,
        studentId: oldBooking.studentId,
        slotId: newSlotId,
        subject: oldBooking.subject,
        teacherName: oldBooking.teacherName,
        status: 'confirmed',
        bookedAt: DateTime.now(),
        note: '변경됨 (기존: ${oldBooking.id})',
        lmtUsed: oldBooking.lmtUsed + 1,
      );

      transaction.set(newBookingRef, newBooking.toFirestore());
      transaction.update(_slotsRef.doc(newSlotId), {
        'currentStudents': FieldValue.increment(1),
      });

      return newBooking;
    });
  }

  // 학생의 예약 목록 조회
  Stream<List<BookingModel>> getStudentBookings(String studentId) {
    return _bookingsRef
        .where('studentId', isEqualTo: studentId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .orderBy('bookedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  // 전체 예약 목록 (관리자용)
  Stream<List<BookingModel>> getAllBookings() {
    return _bookingsRef
        .orderBy('bookedAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList());
  }

  // 특정 날짜의 예약 조회
  Future<List<BookingModel>> getBookingsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snap = await _bookingsRef
        .where('bookedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('bookedAt', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snap.docs.map((doc) => BookingModel.fromFirestore(doc)).toList();
  }
}
