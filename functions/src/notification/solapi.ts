import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';
import { AlimtalkTemplate, BOOKING_CONFIRMED, CLASS_REMINDER, BOOKING_CANCELLED, PARENT_WEEKLY_REPORT } from './templates';

// 솔라피 API 설정
const SOLAPI_BASE_URL = 'https://api.solapi.com';
const SOLAPI_API_KEY = functions.config().solapi?.api_key ?? '';
const SOLAPI_API_SECRET = functions.config().solapi?.api_secret ?? '';
const SOLAPI_PFID = functions.config().solapi?.pfid ?? ''; // 카카오 채널 ID

interface SendAlimtalkParams {
  to: string; // 수신자 전화번호
  template: AlimtalkTemplate;
  variables: Record<string, string>;
}

// 솔라피 인증 헤더 생성
function getAuthHeader(): string {
  const date = new Date().toISOString();
  const salt = crypto.randomBytes(32).toString('hex');
  const signature = crypto
    .createHmac('sha256', SOLAPI_API_SECRET)
    .update(date + salt)
    .digest('hex');
  return `HMAC-SHA256 apiKey=${SOLAPI_API_KEY}, date=${date}, salt=${salt}, signature=${signature}`;
}

// 템플릿 변수 치환
function replaceVariables(content: string, variables: Record<string, string>): string {
  let result = content;
  for (const [key, value] of Object.entries(variables)) {
    result = result.replace(new RegExp(`#\\{${key}\\}`, 'g'), value);
  }
  return result;
}

// 알림톡 발송
async function sendAlimtalk({ to, template, variables }: SendAlimtalkParams): Promise<void> {
  const body = {
    message: {
      to,
      from: functions.config().solapi?.sender_number ?? '',
      kakaoOptions: {
        pfId: SOLAPI_PFID,
        templateId: template.templateId,
        variables,
        buttons: template.buttons,
      },
    },
  };

  const response = await fetch(`${SOLAPI_BASE_URL}/messages/v4/send`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: getAuthHeader(),
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`솔라피 알림톡 발송 실패: ${response.status} ${error}`);
  }
}

// Firestore 트리거: 예약 생성 시 알림톡 발송
export const onBookingCreated = functions
  .region('asia-northeast3')
  .firestore.document('bookings/{bookingId}')
  .onCreate(async (snap) => {
    const booking = snap.data();
    const db = admin.firestore();

    const studentDoc = await db.collection('users').doc(booking.studentId).get();
    const student = studentDoc.data();
    if (!student?.phone) return;

    const slotDoc = await db.collection('slots').doc(booking.slotId).get();
    const slot = slotDoc.data();
    if (!slot) return;

    const startTime = slot.startTime.toDate();
    const variables: Record<string, string> = {
      '학생명': student.name,
      '과목명': booking.subject ?? '미정',
      '수업일자': `${startTime.getMonth() + 1}월 ${startTime.getDate()}일`,
      '수업시간': `${startTime.getHours()}:${String(startTime.getMinutes()).padStart(2, '0')}`,
      '강사명': booking.teacherName ?? '미정',
    };

    await sendAlimtalk({
      to: student.phone,
      template: BOOKING_CONFIRMED,
      variables,
    });
  });

// Firestore 트리거: 예약 취소 시 알림톡 발송
export const onBookingCancelled = functions
  .region('asia-northeast3')
  .firestore.document('bookings/{bookingId}')
  .onUpdate(async (change) => {
    const before = change.before.data();
    const after = change.after.data();

    if (before.status !== 'cancelled' && after.status === 'cancelled') {
      const db = admin.firestore();
      const studentDoc = await db.collection('users').doc(after.studentId).get();
      const student = studentDoc.data();
      if (!student?.phone) return;

      const slotDoc = await db.collection('slots').doc(after.slotId).get();
      const slot = slotDoc.data();
      if (!slot) return;

      const startTime = slot.startTime.toDate();
      const variables: Record<string, string> = {
        '학생명': student.name,
        '과목명': after.subject ?? '미정',
        '수업일자': `${startTime.getMonth() + 1}월 ${startTime.getDate()}일`,
        '수업시간': `${startTime.getHours()}:${String(startTime.getMinutes()).padStart(2, '0')}`,
      };

      await sendAlimtalk({
        to: student.phone,
        template: BOOKING_CANCELLED,
        variables,
      });
    }
  });

// 스케줄 트리거: 수업 1시간 전 리마인더
export const classReminder = functions
  .region('asia-northeast3')
  .pubsub.schedule('every 30 minutes')
  .timeZone('Asia/Seoul')
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();
    const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);
    const oneHourThirtyLater = new Date(now.getTime() + 90 * 60 * 1000);

    // 1시간~1시간30분 후 시작하는 슬롯 조회
    const slotsSnap = await db
      .collection('slots')
      .where('startTime', '>=', admin.firestore.Timestamp.fromDate(oneHourLater))
      .where('startTime', '<', admin.firestore.Timestamp.fromDate(oneHourThirtyLater))
      .get();

    for (const slotDoc of slotsSnap.docs) {
      const slot = slotDoc.data();
      const bookingsSnap = await db
        .collection('bookings')
        .where('slotId', '==', slotDoc.id)
        .where('status', '==', 'confirmed')
        .get();

      for (const bookingDoc of bookingsSnap.docs) {
        const booking = bookingDoc.data();
        const studentDoc = await db.collection('users').doc(booking.studentId).get();
        const student = studentDoc.data();
        if (!student?.phone) continue;

        const startTime = slot.startTime.toDate();
        const variables: Record<string, string> = {
          '학생명': student.name,
          '과목명': booking.subject ?? '미정',
          '수업시간': `${startTime.getHours()}:${String(startTime.getMinutes()).padStart(2, '0')}`,
          '강사명': booking.teacherName ?? '미정',
        };

        await sendAlimtalk({
          to: student.phone,
          template: CLASS_REMINDER,
          variables,
        });
      }
    }
  });

// HTTP 트리거: 주간 학부모 리포트 알림 (관리자가 수동 호출)
export const sendWeeklyParentReport = functions
  .region('asia-northeast3')
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', '인증 필요');

    const db = admin.firestore();
    const callerDoc = await db.collection('users').doc(context.auth.uid).get();
    if (callerDoc.data()?.role !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', '관리자만 호출 가능');
    }

    const { studentId, parentPhone, reportData } = data as {
      studentId: string;
      parentPhone: string;
      reportData: { parentName: string; studentName: string; attendance: string; studyHours: string; classCount: string };
    };

    const variables: Record<string, string> = {
      '학부모명': reportData.parentName,
      '학생명': reportData.studentName,
      '출석률': reportData.attendance,
      '학습시간': reportData.studyHours,
      '수업횟수': reportData.classCount,
    };

    await sendAlimtalk({
      to: parentPhone,
      template: PARENT_WEEKLY_REPORT,
      variables,
    });

    return { success: true };
  });
