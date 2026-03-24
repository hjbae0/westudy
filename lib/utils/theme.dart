import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  // 배경색 R248 G246 F243
  static const Color backgroundColor = Color(0xFFF8F6F3);
  static const Color primaryColor = Color(0xFF4A6FA5);
  static const Color secondaryColor = Color(0xFF6B9080);
  static const Color errorColor = Color(0xFFE63946);
  static const Color surfaceColor = Colors.white;
  static const Color onSurfaceColor = Color(0xFF2D3436);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: secondaryColor,
        error: errorColor,
        surface: surfaceColor,
        onSurface: onSurfaceColor,
      ),
      textTheme: GoogleFonts.notoSansKrTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundColor,
        foregroundColor: onSurfaceColor,
        elevation: 0,
      ),
    );
  }
}
