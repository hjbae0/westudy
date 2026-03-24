import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:westudy/services/auth_service.dart';
import 'package:westudy/screens/student/home_screen.dart';
import 'package:westudy/screens/student/booking_screen.dart';
import 'package:westudy/screens/student/change_screen.dart';
import 'package:westudy/screens/parent/report_screen.dart';
import 'package:westudy/screens/admin/dashboard_screen.dart';
import 'package:westudy/screens/auth/login_screen.dart';
import 'package:westudy/utils/theme.dart';

GoRouter createRouter(AuthService authService) {
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authService,
    redirect: (context, state) {
      final isLoggedIn = authService.isLoggedIn;
      final isLoginRoute = state.matchedLocation == '/login';

      // 미인증 → 로그인 페이지로
      if (!isLoggedIn && !isLoginRoute) return '/login';

      // 인증됨 + 로그인 페이지 → 역할별 홈으로
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
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
}

class WeStudyApp extends StatelessWidget {
  const WeStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: Consumer<AuthService>(
        builder: (context, authService, _) {
          final router = createRouter(authService);
          return MaterialApp.router(
            title: 'WeStudy',
            theme: AppTheme.lightTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
