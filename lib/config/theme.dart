import 'package:flutter/material.dart';

/// สีและธีมของระบบงานเงินเดือน
/// โทนหลักเขียวน้ำทะเล (teal) คู่กับกรมท่า ใช้สีเหลืองอำพันแทนเหรียญ/เงิน
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF115E59);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color navy = Color(0xFF0F172A);
  static const Color navySoft = Color(0xFF1E293B);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentSoft = Color(0xFFFEF3C7);
  static const Color background = Color(0xFFF1F5F9);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);

  /// ฟอนต์เนื้อหา
  static const String bodyFont = 'Sarabun';

  /// ฟอนต์หัวข้อ
  static const String headingFont = 'Kanit';

  /// พื้นหลังของแถบเมนูข้าง
  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [navy, Color(0xFF0B3B3A)],
  );

  /// พื้นหลังของภาพหัวหน้าแรก
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
  );

  static ThemeData get theme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: bodyFont,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: bodyFont,
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      tooltipTheme: const TooltipThemeData(
        textStyle: TextStyle(fontFamily: bodyFont, color: Colors.white, fontSize: 13),
        decoration: BoxDecoration(
          color: navySoft,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  /// ข้อความหัวข้อ
  static TextStyle heading(double size, {Color color = textPrimary, FontWeight weight = FontWeight.w500}) =>
      TextStyle(fontFamily: headingFont, fontSize: size, fontWeight: weight, color: color, height: 1.3);
}
