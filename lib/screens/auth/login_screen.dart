import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:westudy/services/auth_service.dart';
import 'package:westudy/utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSocialLoading = false;
  String? _socialLoadingProvider;

  @override
  Widget build(BuildContext context) {
    // AuthService의 isLoading 상태도 감시
    final authService = context.watch<AuthService>();
    final isLoading = _isSocialLoading || authService.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    // 로고
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
                    const SizedBox(height: 48),

                    // 1. 카카오 로그인
                    _SocialLoginButton(
                      label: _socialLoadingProvider == 'kakao'
                          ? '카카오 로그인 중...'
                          : '카카오로 시작하기',
                      icon: Icons.chat_bubble,
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: const Color(0xFF191919),
                      isLoading: _socialLoadingProvider == 'kakao',
                      onPressed: isLoading
                          ? null
                          : () => _signInWithKakao(context),
                    ),
                    const SizedBox(height: 10),

                    // 2. 네이버 로그인
                    _SocialLoginButton(
                      label: _socialLoadingProvider == 'naver'
                          ? '네이버 로그인 중...'
                          : '네이버로 시작하기',
                      icon: Icons.north_east_rounded,
                      backgroundColor: const Color(0xFF03C75A),
                      foregroundColor: Colors.white,
                      isLoading: _socialLoadingProvider == 'naver',
                      onPressed: isLoading
                          ? null
                          : () => _signInWithNaver(context),
                    ),
                    const SizedBox(height: 10),

                    // 3. 구글 로그인
                    _SocialLoginButton(
                      label: _socialLoadingProvider == 'google'
                          ? 'Google 로그인 중...'
                          : 'Google로 시작하기',
                      iconWidget: _socialLoadingProvider == 'google'
                          ? null
                          : Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              width: 20,
                              height: 20,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.g_mobiledata, size: 24, color: Color(0xFF4285F4)),
                            ),
                      icon: _socialLoadingProvider == 'google' ? Icons.g_mobiledata : null,
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.onSurfaceColor,
                      borderColor: Colors.grey.shade300,
                      isLoading: _socialLoadingProvider == 'google',
                      onPressed: isLoading
                          ? null
                          : () => _signInWithGoogle(context),
                    ),
                    const SizedBox(height: 10),

                    // 4. 이메일 로그인
                    _SocialLoginButton(
                      label: '이메일로 로그인',
                      icon: Icons.email_outlined,
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      onPressed: isLoading
                          ? null
                          : () => _showEmailLoginSheet(context),
                    ),
                    const SizedBox(height: 20),

                    // 이메일 회원가입 링크
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => _showEmailSignUpSheet(context),
                      child: Text(
                        '이메일로 가입하기',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DEV 바로가기
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'DEV 바로가기',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _DevButton(
                                  label: '학생',
                                  icon: Icons.school,
                                  color: AppTheme.primaryColor,
                                  onTap: () => context.go('/student'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DevButton(
                                  label: '학부모',
                                  icon: Icons.family_restroom,
                                  color: AppTheme.secondaryColor,
                                  onTap: () => context.go('/parent'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _DevButton(
                                  label: '관리자',
                                  icon: Icons.admin_panel_settings,
                                  color: const Color(0xFFE17055),
                                  onTap: () => context.go('/admin'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // 전체 로딩 오버레이 (OAuth 콜백 처리 중)
            if (authService.isLoading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryColor),
                      SizedBox(height: 16),
                      Text(
                        '로그인 처리 중...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithKakao(BuildContext context) async {
    setState(() {
      _isSocialLoading = true;
      _socialLoadingProvider = 'kakao';
    });

    try {
      final authService = context.read<AuthService>();
      await authService.signInWithKakao();
      // redirect 방식이므로 페이지가 이동됨. 콜백 후 라우트 가드가 자동 리디렉트
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
          _socialLoadingProvider = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('카카오 로그인 실패: $e')),
        );
      }
    }
  }

  Future<void> _signInWithNaver(BuildContext context) async {
    setState(() {
      _isSocialLoading = true;
      _socialLoadingProvider = 'naver';
    });

    try {
      final authService = context.read<AuthService>();
      await authService.signInWithNaver();
      // redirect 방식이므로 페이지가 이동됨. 콜백 후 라우트 가드가 자동 리디렉트
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
          _socialLoadingProvider = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('네이버 로그인 실패: $e')),
        );
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() {
      _isSocialLoading = true;
      _socialLoadingProvider = 'google';
    });

    try {
      final authService = context.read<AuthService>();
      await authService.signInWithGoogle();
      // 라우트 가드가 자동 리디렉트
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google 로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSocialLoading = false;
          _socialLoadingProvider = null;
        });
      }
    }
  }

  void _showEmailLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmailAuthSheet(isSignUp: false),
    );
  }

  void _showEmailSignUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EmailAuthSheet(isSignUp: true),
    );
  }
}

// 소셜 로그인 버튼
class _SocialLoginButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? iconWidget;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _SocialLoginButton({
    required this.label,
    this.icon,
    this.iconWidget,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: borderColor != null
                ? BorderSide(color: borderColor!)
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: foregroundColor,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconWidget != null) iconWidget!
                  else if (icon != null) Icon(icon, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

// 이메일 로그인 / 회원가입 바텀시트
class _EmailAuthSheet extends StatefulWidget {
  final bool isSignUp;
  const _EmailAuthSheet({required this.isSignUp});

  @override
  State<_EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<_EmailAuthSheet> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 핸들
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.isSignUp ? '이메일로 가입하기' : '이메일로 로그인',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // 이름 (회원가입만)
            if (widget.isSignUp) ...[
              TextField(
                controller: _nameController,
                decoration: _inputDecoration('이름'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
            ],

            // 이메일
            TextField(
              controller: _emailController,
              decoration: _inputDecoration('이메일'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // 비밀번호
            TextField(
              controller: _passwordController,
              decoration: _inputDecoration('비밀번호 (6자 이상)'),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),

            // 에러 메시지
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: AppTheme.errorColor),
              ),
            ],
            const SizedBox(height: 20),

            // 제출 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        widget.isSignUp ? '가입하기' : '로그인',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      filled: true,
      fillColor: AppTheme.backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = '이메일과 비밀번호를 입력하세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = context.read<AuthService>();
      if (widget.isSignUp) {
        final name = _nameController.text.trim();
        await authService.signUpWithEmail(
          email: email,
          password: password,
          name: name.isNotEmpty ? name : email.split('@').first,
        );
      } else {
        await authService.signInWithEmail(email: email, password: password);
      }
      if (mounted) {
        Navigator.pop(context);
        // 라우트 가드가 자동 리디렉트
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _mapAuthError(e.code));
    } catch (e) {
      setState(() => _error = '오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '올바른 이메일 형식이 아닙니다.';
      case 'weak-password':
        return '비밀번호가 너무 짧습니다. (6자 이상)';
      case 'user-not-found':
        return '등록되지 않은 이메일입니다.';
      case 'wrong-password':
        return '비밀번호가 틀렸습니다.';
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      default:
        return '로그인 실패 ($code)';
    }
  }
}

// DEV 바로가기 버튼
class _DevButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DevButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
