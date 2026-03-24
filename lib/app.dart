import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:westudy/screens/student/student_home_screen.dart';
import 'package:westudy/screens/parent/parent_home_screen.dart';
import 'package:westudy/screens/admin/admin_home_screen.dart';
import 'package:westudy/utils/theme.dart';

final GoRouter router = GoRouter(
  initialLocation: '/student',
  routes: [
    GoRoute(
      path: '/student',
      builder: (context, state) => const StudentHomeScreen(),
    ),
    GoRoute(
      path: '/parent',
      builder: (context, state) => const ParentHomeScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHomeScreen(),
    ),
  ],
);

class WeStudyApp extends StatelessWidget {
  const WeStudyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'WeStudy',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
