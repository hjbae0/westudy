import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:westudy/models/user_model.dart';
import 'package:westudy/utils/constants.dart';
import 'package:westudy/services/web_auth_helper.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-northeast3');

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);

    // 웹 환경에서 OAuth 콜백 처리
    _handleOAuthCallback();
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      await _loadUserProfile(user.uid);
    } else {
      _userModel = null;
    }
    notifyListeners();
  }

  // Firestore에서 사용자 프로필 로드
  Future<void> _loadUserProfile(String uid) async {
    final doc =
        await _db.collection(AppConstants.usersCollection).doc(uid).get();
    if (doc.exists) {
      _userModel = UserModel.fromFirestore(doc);
    }
  }

  // 이메일 회원가입 + Firestore 프로필 생성
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    String role = 'student',
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);

    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      role: role,
      createdAt: DateTime.now(),
    );

    await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestore());

    _userModel = user;
    notifyListeners();
    return user;
  }

  // 이메일 로그인
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _loadUserProfile(credential.user!.uid);
    notifyListeners();
    return _userModel;
  }

  // Google 로그인 + Firestore 프로필 자동 생성
  Future<UserModel?> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    final credential = await _auth.signInWithPopup(provider);
    final user = credential.user;
    if (user == null) return null;

    // Firestore에 프로필 없으면 생성
    final doc = await _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      final newUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        role: 'student',
        createdAt: DateTime.now(),
      );
      await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newUser.toFirestore());
      _userModel = newUser;
    } else {
      _userModel = UserModel.fromFirestore(doc);
    }

    notifyListeners();
    return _userModel;
  }

  // ─── 카카오 로그인 (웹 REST API OAuth) ───────────────────────

  /// 카카오 OAuth 인증 시작 (redirect 방식)
  /// 빌드 시 --dart-define=KAKAO_CLIENT_ID=xxx 로 전달
  Future<void> signInWithKakao() async {
    _setLoading(true);

    try {
      const clientId = String.fromEnvironment('KAKAO_CLIENT_ID');
      if (clientId.isEmpty) {
        throw Exception('KAKAO_CLIENT_ID 환경변수가 설정되지 않았습니다. '
            '--dart-define=KAKAO_CLIENT_ID=xxx 로 빌드하세요.');
      }

      final currentUrl = WebAuthHelper.getOrigin();
      final redirectUri = '$currentUrl/login';

      // state에 provider 정보를 담아 콜백에서 구분
      final state = base64Url.encode(utf8.encode(json.encode({
        'provider': 'kakao',
      })));

      final authUrl = Uri.https('kauth.kakao.com', '/oauth/authorize', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'state': state,
      });

      // 카카오 OAuth 페이지로 redirect
      WebAuthHelper.navigateTo(authUrl.toString());
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// 카카오 authorization code를 Cloud Function에 전달하여 Firebase 로그인 완료
  /// Cloud Function이 토큰 교환 + 사용자 조회 + Custom Token 발급까지 처리
  Future<UserModel?> _completeKakaoSignIn(String code) async {
    _setLoading(true);

    try {
      final redirectUri = '${WebAuthHelper.getOrigin()}/login';

      // Cloud Function에 code를 보내서 서버에서 토큰 교환 + Custom Token 발급
      // (kauth.kakao.com CORS 이슈 방지)
      final callable = _functions.httpsCallable('kakaoCustomToken');
      final result = await callable.call({
        'code': code,
        'redirectUri': redirectUri,
      });
      final customToken = result.data['customToken'] as String;

      // Firebase signInWithCustomToken
      await _auth.signInWithCustomToken(customToken);
      await _loadUserProfile(_auth.currentUser!.uid);

      _setLoading(false);
      notifyListeners();
      return _userModel;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // ─── 네이버 로그인 (웹 REST API OAuth) ───────────────────────

  /// 네이버 OAuth 인증 시작 (redirect 방식)
  /// 빌드 시 --dart-define=NAVER_CLIENT_ID=xxx 로 전달
  Future<void> signInWithNaver() async {
    _setLoading(true);

    try {
      const clientId = String.fromEnvironment('NAVER_CLIENT_ID');
      if (clientId.isEmpty) {
        throw Exception('NAVER_CLIENT_ID 환경변수가 설정되지 않았습니다. '
            '--dart-define=NAVER_CLIENT_ID=xxx 로 빌드하세요.');
      }

      final currentUrl = WebAuthHelper.getOrigin();
      final redirectUri = '$currentUrl/login';

      // state에 provider 정보를 담아 콜백에서 구분
      final state = base64Url.encode(utf8.encode(json.encode({
        'provider': 'naver',
      })));

      final authUrl = Uri.https('nid.naver.com', '/oauth2.0/authorize', {
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'response_type': 'code',
        'state': state,
      });

      // 네이버 OAuth 페이지로 redirect
      WebAuthHelper.navigateTo(authUrl.toString());
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  /// 네이버 authorization code를 Cloud Function에 전달하여 Firebase 로그인 완료
  /// Cloud Function이 토큰 교환 + 사용자 조회 + Custom Token 발급까지 처리
  Future<UserModel?> _completeNaverSignIn(String code, String state) async {
    _setLoading(true);

    try {
      // Cloud Function에 code를 보내서 서버에서 토큰 교환 + Custom Token 발급
      // (nid.naver.com CORS 이슈 방지, client_secret은 서버에만 보관)
      final callable = _functions.httpsCallable('naverCustomToken');
      final result = await callable.call({
        'code': code,
        'state': state,
        'redirectUri': '${WebAuthHelper.getOrigin()}/login',
      });
      final customToken = result.data['customToken'] as String;

      // Firebase signInWithCustomToken
      await _auth.signInWithCustomToken(customToken);
      await _loadUserProfile(_auth.currentUser!.uid);

      _setLoading(false);
      notifyListeners();
      return _userModel;
    } catch (e) {
      _setLoading(false);
      rethrow;
    }
  }

  // ─── OAuth 콜백 처리 ─────────────────────────────────────────

  /// 웹 환경에서 페이지 로드 시 URL의 OAuth 콜백 파라미터를 감지하여 처리
  void _handleOAuthCallback() {
    final params = WebAuthHelper.getUrlParams();
    if (params == null) return;

    final code = params['code'];
    final state = params['state'];

    if (code == null || state == null) return;

    // URL에서 OAuth 파라미터 제거 (히스토리 정리)
    WebAuthHelper.cleanUrl();

    // state에서 provider 정보 추출
    try {
      final stateJson =
          json.decode(utf8.decode(base64Url.decode(base64Url.normalize(state))))
              as Map<String, dynamic>;
      final provider = stateJson['provider'] as String?;

      if (provider == 'kakao') {
        _completeKakaoSignIn(code);
      } else if (provider == 'naver') {
        _completeNaverSignIn(code, state);
      }
    } catch (e) {
      debugPrint('OAuth 콜백 state 파싱 실패: $e');
    }
  }

  // ─── 공통 ────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  // 현재 사용자 역할
  String get userRole => _userModel?.role ?? 'student';

  // 역할별 홈 경로
  String get homeRoute {
    switch (userRole) {
      case 'admin':
        return AppConstants.adminHome;
      case 'parent':
        return AppConstants.parentHome;
      default:
        return AppConstants.studentHome;
    }
  }
}
