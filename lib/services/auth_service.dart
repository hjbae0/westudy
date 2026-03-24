import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:westudy/models/user_model.dart';
import 'package:westudy/utils/constants.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
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
    final doc = await _db.collection(AppConstants.usersCollection).doc(uid).get();
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
