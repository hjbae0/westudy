import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * 예약 생성 트리거
 * - 학부모에게 알림 생성
 * - 슬롯 만석 시 자동 blocked 처리
 */
export const onBookingCreated = functions
  .region('asia-northeast3')
  .firestore.document('bookings/{bookingId}')
  .onCreate(async (snap, context) => {
    const booking = snap.data();
    const db = admin.firestore();
    const bookingId = context.params.bookingId;

    // 1. 학생 정보 조회
    const studentDoc = await db.collection('users').doc(booking.studentId).get();
    const student = studentDoc.data();

    // 2. 학부모에게 알림 생성 (parentId가 있는 경우)
    if (student?.parentId) {
      await db.collection('notifications').add({
        userId: student.parentId,
        title: '수업 예약 알림',
        body: `${student.name ?? '학생'}님이 ${booking.subject ?? '수업'}을 예약했습니다.`,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        type: 'booking_created',
        bookingId,
      });
    }

    // 3. 슬롯 만석 확인 → blocked 처리
    const slotDoc = await db.collection('slots').doc(booking.slotId).get();
    const slot = slotDoc.data();

    if (slot && slot.currentStudents >= slot.maxStudents) {
      await db.collection('slots').doc(booking.slotId).update({
        status: 'booked',
      });
    }

    console.log(`[예약생성] bookingId=${bookingId}, student=${booking.studentId}, slot=${booking.slotId}`);
  });
