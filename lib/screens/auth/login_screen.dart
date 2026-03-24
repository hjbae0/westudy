import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:westudy/utils/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 3),
              // 로고 영역
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'WeStudy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.onSurfaceColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '스마트한 학습 관리의 시작',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceColor.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(flex: 2),
              // 카카오 로그인 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: 카카오 로그인 구현
                    context.go('/student');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: const Color(0xFF191919),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '카카오로 시작하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 게스트 로그인
              TextButton(
                onPressed: () {
                  context.go('/student');
                },
                child: Text(
                  '둘러보기',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.onSurfaceColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
