import * as admin from 'firebase-admin';

// Firebase Admin 초기화 (한 번만)
admin.initializeApp();

// 예약 트리거
export { onBookingCreated, onBookingUpdated, onBookingCancelled } from './booking';

// 알림톡 (솔라피)
export {
  onBookingCreated as solapiBookingCreated,
  onBookingCancelled as solapiBookingCancelled,
  classReminder,
  sendWeeklyParentReport,
} from './notification/solapi';

// 소셜 로그인 (카카오, 네이버)
export { kakaoCustomToken, naverCustomToken } from './auth';
