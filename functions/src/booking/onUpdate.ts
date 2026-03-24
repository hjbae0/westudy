import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * 예약 변경 트리거
 * - 상태 변경 감지 (confirmed → cancelled 등)
 * - LMT 사용 시 학부모 알림
 * - 슬롯 상태 동기화
 */
export const onBookingUpdated = functions
  .region('asia-northeast3')
  .firestore.document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const bookingId = context.params.bookingId;
    const db = admin.firestore();

    // 상태가 변경되지 않으면 무시
    if (before.status === after.status && before.lmtUsed === after.lmtUsed) {
      return;
    }

    const studentDoc = await db.collection('users').doc(after.studentId).get();
    const student = studentDoc.data();

    // 1. LMT 사용 감지 (lmtUsed 증가)
    if ((after.lmtUsed ?? 0) > (before.lmtUsed ?? 0)) {
      // 학생에게 LMT 사용 알림
      await db.collection('notifications').add({
        userId: after.studentId,
        title: '긴급변경권 사용',
        body: `긴급변경권 1회를 사용했습니다. (${after.lmtUsed}/3)`,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        type: 'lmt_used',
        bookingId,
      });

      // 학부모에게도 알림
      if (student?.parentId) {
        await db.collection('notifications').add({
          userId: student.parentId,
          title: '수업 변경 알림',
          body: `${student.name ?? '학생'}님이 긴급변경권을 사용하여 수업을 변경했습니다.`,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          type: 'lmt_used',
          bookingId,
        });
      }

      console.log(`[LMT사용] bookingId=${bookingId}, lmtUsed=${after.lmtUsed}`);
    }

    // 2. 완료 처리 감지
    if (before.status !== 'completed' && after.status === 'completed') {
      // 슬롯 인원 감소 (완료된 수업은 슬롯에서 해제)
      await db.collection('slots').doc(after.slotId).update({
        currentStudents: admin.firestore.FieldValue.increment(-1),
      });

      // 슬롯이 booked → available로 복원 가능한지 확인
      const slotDoc = await db.collection('slots').doc(after.slotId).get();
      const slot = slotDoc.data();
      if (slot && slot.status === 'booked' && slot.currentStudents < slot.maxStudents) {
        await db.collection('slots').doc(after.slotId).update({
          status: 'available',
        });
      }

      console.log(`[수업완료] bookingId=${bookingId}`);
    }
  });
