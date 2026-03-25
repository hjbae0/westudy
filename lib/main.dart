import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:westudy/app.dart';
import 'package:westudy/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Android: google-services.json으로 이미 초기화된 경우 무시
  }
  await initializeDateFormatting('ko_KR');
  runApp(const WeStudyApp());
}
