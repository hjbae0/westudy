# WeStudy 프로젝트

## 프로젝트 개요
- **이름**: WeStudy (위스터디) - 예중/예고 전문 온라인 교과 스터디룸
- **스택**: Flutter 3.41 (Web/Android/iOS) + Firebase (Auth, Firestore, Hosting, Cloud Functions)
- **라이브 URL**: https://westudy-bfcb4.web.app
- **GitHub**: https://github.com/hjbae0/westudy
- **Firebase 프로젝트**: westudy-bfcb4
- **진행률**: ~95% (프로덕션 전환 완료, 앱스토어 등록 전)

## 프로젝트 구조
```
lib/
  main.dart                          # Firebase 초기화 + ko_KR 로케일 + 앱 실행
  app.dart                           # GoRouter + Provider + 라우트 가드 (kDevMode=false)
  firebase_options.dart              # Firebase 설정
  models/                            # 데이터 모델 (fromFirestore/toFirestore)
    user_model.dart                  # 사용자 (role, parentId, childrenIds)
    booking_model.dart               # 예약 (subject, teacherName, lmtUsed)
    slot_model.dart                  # 30분 슬롯 (available/booked/blocked)
    report_model.dart                # 학습 리포트
    notification_model.dart          # 알림
  services/                          # 비즈니스 로직 (6개 서비스 전부 구현 완료)
    auth_service.dart                # Firebase Auth (Google+이메일) + Firestore 프로필
    booking_service.dart             # 예약 CRUD (Firestore 트랜잭션, 동시성 안전)
    slot_service.dart                # 슬롯 생성/조회/차단 (30분 단위)
    lmt_service.dart                 # 긴급변경권 (주 3회, LmtExhaustedException)
    parent_service.dart              # 학부모-학생 양방향 연결
    ai_service.dart                  # 규칙 기반 자연어 스케줄링 (의도파싱+슬롯추천)
  screens/
    auth/login_screen.dart           # Google/이메일 (작동) + 카카오/네이버 (UI만)
    student/
      student_home_screen.dart       # 홈 (5탭: 홈/AI/일정/리포트/프로필)
      home_screen.dart               # 레거시 (student_home_screen으로 대체됨)
      booking_screen.dart            # Calendly 스타일 예약 (Firestore 실시간)
      change_screen.dart             # LMT 긴급변경 (잔여 표시, 대체 슬롯)
      ai_chat_screen.dart            # AI 채팅 (버블UI, 퀵커맨드, 슬롯카드)
    parent/
      parent_home_screen.dart        # 학부모 홈
      report_screen.dart             # 학습 리포트 (자녀선택, 주간통계, 진도바)
    admin/                           # 관리자 (8개 페이지 + 사이드바 쉘)
      admin_shell.dart               # 반응형 사이드바 네비게이션
      admin_home_screen.dart         # 관리자 진입점
      dashboard_page.dart            # 실시간 대시보드 (지표카드+차트+테이블)
      students_page.dart             # 학생 관리 (검색/추가/수정/삭제)
      teachers_page.dart             # 선생님 관리
      parents_page.dart              # 학부모 관리 (학생 연결)
      classes_page.dart              # 수업 관리 (드래그앤드롭 시간변경)
      classes_import_page.dart       # Google Sheets/Calendar 가져오기
      teacher_schedule_page.dart     # 선생님 주간 스케줄 관리
      reports_page.dart              # 리포트 관리
      billing_page.dart              # 정산 관리 (5개 하위 탭)
  utils/
    theme.dart                       # 배경색 #F8F6F3, 프라이머리 #4A6FA5
    constants.dart                   # Firestore 컬렉션명, 역할, 라우트
functions/
  src/notification/                  # 솔라피 알림톡 (HMAC-SHA256 인증, 4개 트리거)
  src/booking/                       # 예약 트리거 (onCreate/onUpdate/onCancel)
firestore.rules                      # 역할 기반 보안 규칙 (isParentOf 포함)
firebase.json                        # Hosting (no-cache) + Firestore + Functions
test/                                # 유닛 테스트 (13/13 passed)
```

## 완료된 기능 (95%)
- **인증**: Google + 이메일/비밀번호 완전 작동 + 카카오/네이버 OAuth Cloud Function 구현
- **예약 시스템**: Firestore 트랜잭션, 슬롯 잔여석 검증, 중복 방지, Calendly 스타일 UI
- **LMT 긴급변경권**: 주 3회 제한, 소진 시 경고/거부, UI + 서비스 + 커스텀 예외
- **AI 스케줄러**: 규칙 기반 NLP (의도파싱/슬롯검색/시간추천/실기제외), 채팅 UI
- **라우트 가드**: 인증 상태 + 역할별 자동 리디렉트 (현재 kDevMode=true로 비활성)
- **학부모**: 양방향 연결, 자녀 예약/리포트 조회, Firestore rules 접근 허용
- **관리자 대시보드**: 실시간 지표 + 차트 + 테이블 + 8개 관리 페이지
- **수업 관리**: 드래그앤드롭 시간변경, Google Sheets/Calendar 가져오기
- **정산 관리**: 5개 하위 탭 (학생별/월별/결제추적)
- **선생님 스케줄**: 주간 가용시간 그리드 관리
- **Cloud Functions**: 예약 생성/수정/취소 트리거 + 솔라피 알림톡 4개
- **보안 규칙**: 역할 기반 + 학부모 관계 기반 접근 제어
- **빌드**: Web 배포 완료, Android APK 빌드 완료, iOS 설정 완료
- **테스트**: BookingModel + SlotModel + LMT 로직 (13/13 passed)

## 완료된 프로덕션 전환 (2026-03-25)
- [x] kDevMode=false 전환 (인증 가드 활성화)
- [x] firebase_options.dart 실제 값 (Web + Android)
- [x] Android 앱 Firebase 등록 + google-services.json
- [x] 카카오/네이버 Custom Token Cloud Function 구현
- [x] 학생 홈 일정 탭 구현 (주간 캘린더 + 수업 목록)
- [x] 학생 홈 리포트 탭 구현 (주간 통계 + 과목별 진도)
- [x] 학생 프로필 탭 구현 (LMT 상태 + 설정 + 로그아웃)
- [x] 레거시 파일 정리 (home_screen.dart, dashboard_screen.dart 삭제)
- [x] 한국어 날짜 포맷 초기화 (initializeDateFormatting)
- [x] Firestore 데이터베이스 생성 (서울 리전) + 테스트 데이터 시딩
- [x] Android 에뮬레이터 실행 확인

## 미완성 기능 (5%)

### Boss 작업 필요
- [ ] 카카오 개발자 앱 등록 + API 키 설정
- [ ] 네이버 개발자 앱 등록 + API 키 설정
- [ ] 솔라피 API 키 설정 (firebase functions:config:set solapi.api_key=...)

### 기능 확장
- [ ] 음성 입력 연동 (speech_to_text)
- [ ] 푸시 알림 FCM (firebase_messaging)
- [ ] AI 엔진 Gemini API 연동 (현재 규칙 기반)
- [ ] CI/CD 파이프라인 (GitHub Actions)

### 앱 출시
- [ ] Google Play 스토어 등록 ($25)
- [ ] Apple App Store 등록 (연 $99)
- [ ] 베타 테스트 (학생 3명)

## 테스트 계정
- **관리자**: admin@westudy.kr / westudy2026!
- **학생**: kimyesul@test.com ~ jeonghana@test.com / test1234!
- **선생님**: kim.teacher@westudy.kr 등 / test1234!

## 빌드/배포 명령
```bash
flutter pub get                          # 의존성 설치
flutter build web --release              # 웹 빌드
flutter run -d chrome                    # 로컬 실행
flutter build apk --debug               # Android APK
flutter build ios --no-codesign          # iOS (Xcode 필요)
firebase deploy --only hosting           # Hosting 배포
firebase deploy --only firestore:rules   # 보안 규칙 배포
firebase deploy --only functions         # Cloud Functions 배포
```

## 코드 컨벤션
- UI/주석: 한국어
- Firestore 컬렉션명: 영어 (users, bookings, slots, reports, notifications)
- 커밋 메시지: 한국어 OK (feat:/fix:/refactor: 접두사)
- 상태 관리: Provider (ChangeNotifierProvider)
- 라우팅: GoRouter (/student/, /parent/, /admin/)

## 옵시디언 상세 문서
- 마스터플랜: `1_Projects_성과목표/위스터디_개발_마스터플랜.md`
- 에이전트팀: `1_Projects_성과목표/위스터디_에이전트팀_구성.md`
- 기술스택: `1_Projects_성과목표/위스터디_기술스택_아키텍처.md`
- AI 설계: `1_Projects_성과목표/위스터디_AI스케줄링_설계.md`
