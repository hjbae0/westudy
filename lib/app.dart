import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:westudy/services/auth_service.dart';
import 'package:westudy/screens/student/student_home_screen.dart';
import 'package:westudy/screens/student/booking_screen.dart';
import 'package:westudy/screens/student/change_screen.dart';
import 'package:westudy/screens/parent/report_screen.dart';
import 'package:westudy/screens/admin/admin_shell.dart';
import 'package:westudy/screens/auth/login_screen.dart';
import 'package:westudy/utils/theme.dart';

// DEV 모드: 라우트 가드 우회 허용
const bool kDevMode = false;

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authService,
    redirect: (context, state) {
      final isLoggedIn = authService.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';

      // DEV 모드에서는 라우트 가드 비활성화
      if (kDevMode) return null;

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return authService.homeRoute;

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/student',
        builder: (context, state) => const StudentHomeScreen(),
      ),
      GoRoute(
        path: '/student/booking',
        builder: (context, state) => const BookingScreen(),
      ),
      GoRoute(
        path: '/student/change',
        builder: (context, state) => const ChangeScreen(),
      ),
      GoRoute(
        path: '/parent',
        builder: (context, state) => const ParentReportScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminShell(),
      ),
    ],
  );
}

class WeStudyApp extends StatefulWidget {
  const WeStudyApp({super.key});

  @override
  State<WeStudyApp> createState() => _WeStudyAppState();
}

class _WeStudyAppState extends State<WeStudyApp> {
  late final AuthService _authService;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _router = createRouter(_authService);
  }

  @override
  void dispose() {
    _authService.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _authService,
      child: MaterialApp.router(
        title: 'WeStudy',
        theme: AppTheme.lightTheme,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
