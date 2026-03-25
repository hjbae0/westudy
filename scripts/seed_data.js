#!/usr/bin/env node
/**
 * WeStudy Firestore 테스트 데이터 시딩 스크립트
 *
 * 사용법: node scripts/seed_data.js
 * 전제: firebase CLI로 로그인 되어있어야 함
 */

const { initializeApp, cert, applicationDefault } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// Firebase Admin SDK 초기화 (gcloud 기본 인증 사용)
const app = initializeApp({ projectId: 'westudy-bfcb4' });
const db = getFirestore(app);
const auth = getAuth(app);

// 이번 주 월요일 기준 날짜 계산
function getMonday() {
  const now = new Date();
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(now.setDate(diff));
  monday.setHours(0, 0, 0, 0);
  return monday;
}

function addDays(date, days) {
  const result = new Date(date);
  result.setDate(result.getDate() + days);
  return result;
}

// ==================== 학생 데이터 ====================
const students = [
  { name: '김예술', email: 'kimyesul@test.com', grade: '예고1', major: '피아노' },
  { name: '박민지', email: 'parkminji@test.com', grade: '예고2', major: '바이올린' },
  { name: '이유나', email: 'leeyuna@test.com', grade: '예중3', major: '성악' },
  { name: '최시우', email: 'choisiwoo@test.com', grade: '예고1', major: '첼로' },
  { name: '정하나', email: 'jeonghana@test.com', grade: '예중2', major: '플루트' },
];

// ==================== 선생님 데이터 ====================
const teachers = [
  { name: '김선생', email: 'kim.teacher@westudy.kr', subjects: ['국어'] },
  { name: '박선생', email: 'park.teacher@westudy.kr', subjects: ['영어'] },
  { name: '이선생', email: 'lee.teacher@westudy.kr', subjects: ['수학'] },
];

// ==================== 관리자 ====================
const admin = {
  name: '관리자',
  email: 'admin@westudy.kr',
  password: 'westudy2026!',
};

async function createAuthUser(email, password, displayName) {
  try {
    const user = await auth.getUserByEmail(email);
    console.log(`  이미 존재: ${email} (${user.uid})`);
    return user.uid;
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      const user = await auth.createUser({
        email,
        password: password || 'test1234!',
        displayName,
        emailVerified: true,
      });
      console.log(`  생성 완료: ${email} (${user.uid})`);
      return user.uid;
    }
    throw e;
  }
}

async function seedUsers() {
  console.log('\n📌 사용자 생성 중...');
  const studentIds = [];
  const teacherIds = [];

  // 관리자
  const adminUid = await createAuthUser(admin.email, admin.password, admin.name);
  await db.collection('users').doc(adminUid).set({
    name: admin.name,
    email: admin.email,
    role: 'admin',
    phone: '010-0000-0000',
    createdAt: Timestamp.now(),
  }, { merge: true });
  console.log(`  관리자 Firestore 프로필 저장: ${adminUid}`);

  // 학생
  for (const s of students) {
    const uid = await createAuthUser(s.email, 'test1234!', s.name);
    await db.collection('users').doc(uid).set({
      name: s.name,
      email: s.email,
      role: 'student',
      phone: '',
      grade: s.grade,
      major: s.major,
      parentId: '',
      childrenIds: [],
      createdAt: Timestamp.now(),
    }, { merge: true });
    studentIds.push({ uid, ...s });
  }
  console.log(`  학생 ${studentIds.length}명 완료`);

  // 선생님
  for (const t of teachers) {
    const uid = await createAuthUser(t.email, 'test1234!', t.name);
    await db.collection('users').doc(uid).set({
      name: t.name,
      email: t.email,
      role: 'teacher',
      phone: '',
      subjects: t.subjects,
      createdAt: Timestamp.now(),
    }, { merge: true });
    teacherIds.push({ uid, ...t });
  }
  console.log(`  선생님 ${teacherIds.length}명 완료`);

  return { studentIds, teacherIds, adminUid };
}

async function seedSlots(teacherIds) {
  console.log('\n📌 이번 주 슬롯 생성 중...');
  const monday = getMonday();
  let slotCount = 0;

  for (let dayOffset = 0; dayOffset < 5; dayOffset++) {
    const date = addDays(monday, dayOffset);
    const dateStr = date.toISOString().split('T')[0]; // YYYY-MM-DD

    for (const teacher of teacherIds) {
      // 15:00 ~ 21:00 (6시간, 12개 슬롯)
      for (let hour = 15; hour <= 20; hour++) {
        for (const min of [0, 30]) {
          const startTime = new Date(date);
          startTime.setHours(hour, min, 0, 0);
          const endTime = new Date(startTime);
          endTime.setMinutes(endTime.getMinutes() + 30);

          const slotId = `${dateStr}_${String(hour).padStart(2, '0')}${String(min).padStart(2, '0')}_${teacher.uid}`;

          await db.collection('slots').doc(slotId).set({
            teacherId: teacher.uid,
            teacherName: teacher.name,
            subject: teacher.subjects[0],
            date: dateStr,
            startTime: Timestamp.fromDate(startTime),
            endTime: Timestamp.fromDate(endTime),
            maxStudents: 5,
            currentStudents: 0,
            status: 'available',
          }, { merge: true });
          slotCount++;
        }
      }
    }
  }
  console.log(`  슬롯 ${slotCount}개 생성 (월~금, 15:00~21:00, 선생님 3명)`);
  return slotCount;
}

async function seedBookings(studentIds, teacherIds) {
  console.log('\n📌 이번 주 수업 10개 생성 중...');
  const monday = getMonday();

  const bookings = [
    { studentIdx: 0, teacherIdx: 0, day: 0, hour: 16, min: 0 },   // 김예술 - 국어 월 16:00
    { studentIdx: 0, teacherIdx: 2, day: 2, hour: 17, min: 0 },   // 김예술 - 수학 수 17:00
    { studentIdx: 1, teacherIdx: 1, day: 0, hour: 15, min: 30 },  // 박민지 - 영어 월 15:30
    { studentIdx: 1, teacherIdx: 0, day: 3, hour: 18, min: 0 },   // 박민지 - 국어 목 18:00
    { studentIdx: 2, teacherIdx: 2, day: 1, hour: 16, min: 30 },  // 이유나 - 수학 화 16:30
    { studentIdx: 2, teacherIdx: 1, day: 4, hour: 15, min: 0 },   // 이유나 - 영어 금 15:00
    { studentIdx: 3, teacherIdx: 0, day: 1, hour: 19, min: 0 },   // 최시우 - 국어 화 19:00
    { studentIdx: 3, teacherIdx: 2, day: 3, hour: 16, min: 0 },   // 최시우 - 수학 목 16:00
    { studentIdx: 4, teacherIdx: 1, day: 2, hour: 18, min: 30 },  // 정하나 - 영어 수 18:30
    { studentIdx: 4, teacherIdx: 0, day: 4, hour: 17, min: 30 },  // 정하나 - 국어 금 17:30
  ];

  for (let i = 0; i < bookings.length; i++) {
    const b = bookings[i];
    const student = studentIds[b.studentIdx];
    const teacher = teacherIds[b.teacherIdx];
    const date = addDays(monday, b.day);
    const dateStr = date.toISOString().split('T')[0];

    const startTime = new Date(date);
    startTime.setHours(b.hour, b.min, 0, 0);

    const slotId = `${dateStr}_${String(b.hour).padStart(2, '0')}${String(b.min).padStart(2, '0')}_${teacher.uid}`;

    // 예약 생성
    const bookingRef = db.collection('bookings').doc();
    await bookingRef.set({
      studentId: student.uid,
      studentName: student.name,
      slotId: slotId,
      subject: teacher.subjects[0],
      teacherName: teacher.name,
      status: i < 7 ? 'confirmed' : 'pending',
      bookedAt: Timestamp.now(),
      date: dateStr,
      startTime: Timestamp.fromDate(startTime),
      note: '',
      lmtUsed: false,
    });

    // 슬롯 상태 업데이트
    await db.collection('slots').doc(slotId).update({
      currentStudents: 1,
      status: 'booked',
    });

    const dayNames = ['월', '화', '수', '목', '금'];
    console.log(`  ${i + 1}. ${student.name} - ${teacher.subjects[0]} (${teacher.name}) ${dayNames[b.day]} ${b.hour}:${String(b.min).padStart(2, '0')}`);
  }
  console.log(`  수업 ${bookings.length}개 완료`);
}

async function main() {
  console.log('🚀 WeStudy 테스트 데이터 시딩 시작');
  console.log(`   프로젝트: westudy-bfcb4`);
  console.log(`   시작 시간: ${new Date().toLocaleString('ko-KR')}`);

  try {
    const { studentIds, teacherIds, adminUid } = await seedUsers();
    await seedSlots(teacherIds);
    await seedBookings(studentIds, teacherIds);

    console.log('\n✅ 시딩 완료!');
    console.log(`   관리자: ${admin.email} / ${admin.password}`);
    console.log(`   학생 로그인: kimyesul@test.com ~ jeonghana@test.com / test1234!`);
    console.log(`   선생님 로그인: kim.teacher@westudy.kr 등 / test1234!`);
  } catch (err) {
    console.error('❌ 에러:', err.message);
    if (err.message.includes('UNAUTHENTICATED') || err.message.includes('credential')) {
      console.error('\n💡 해결: 아래 명령어로 인증 후 다시 실행하세요:');
      console.error('   export GOOGLE_APPLICATION_CREDENTIALS="path/to/service-account.json"');
      console.error('   또는: gcloud auth application-default login');
    }
    process.exit(1);
  }

  process.exit(0);
}

main();
