import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * 예약 취소 트리거 (status → cancelled 전환 감지)
 * - 학부모 알림 생성
 * - 슬롯 상태 available로 복원
 * - 취소 로그 기록
 */
export const onBookingCancelled = functions
  .region('asia-northeast3')
  .firestore.document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const bookingId = context.params.bookingId;

    // cancelled 전환만 처리
    if (before.status === 'cancelled' || after.status !== 'cancelled') {
      return;
    }

    const db = admin.firestore();

    // 1. 학생 정보 조회
    const studentDoc = await db.collection('users').doc(after.studentId).get();
    const student = studentDoc.data();

    // 2. 학생에게 취소 확인 알림
    await db.collection('notifications').add({
      userId: after.studentId,
      title: '수업 취소 완료',
      body: `${after.subject ?? '수업'} 예약이 취소되었습니다.`,
      isRead: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      type: 'booking_cancelled',
      bookingId,
    });

    // 3. 학부모에게 취소 알림
    if (student?.parentId) {
      await db.collection('notifications').add({
        userId: student.parentId,
        title: '수업 취소 알림',
        body: `${student.name ?? '학생'}님의 ${after.subject ?? '수업'} 예약이 취소되었습니다.`,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        type: 'booking_cancelled',
        bookingId,
      });
    }

    // 4. 슬롯 상태 복원 (booked → available)
    const slotDoc = await db.collection('slots').doc(after.slotId).get();
    const slot = slotDoc.data();

    if (slot && slot.status === 'booked') {
      await db.collection('slots').doc(after.slotId).update({
        status: 'available',
      });
    }

    // 5. 취소 로그
    await db.collection('booking_logs').add({
      bookingId,
      studentId: after.studentId,
      action: 'cancelled',
      previousStatus: before.status,
      slotId: after.slotId,
      subject: after.subject,
      cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`[예약취소] bookingId=${bookingId}, student=${after.studentId}`);
  });
