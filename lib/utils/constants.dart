class AppConstants {
  AppConstants._();

  static const String appName = 'WeStudy';
  static const String appVersion = '1.0.0';

  // Firestore 컬렉션
  static const String usersCollection = 'users';
  static const String bookingsCollection = 'bookings';
  static const String slotsCollection = 'slots';
  static const String reportsCollection = 'reports';
  static const String notificationsCollection = 'notifications';

  // 사용자 역할
  static const String roleStudent = 'student';
  static const String roleParent = 'parent';
  static const String roleAdmin = 'admin';

  // 라우트 경로
  static const String studentHome = '/student';
  static const String parentHome = '/parent';
  static const String adminHome = '/admin';
  static const String login = '/login';
}
