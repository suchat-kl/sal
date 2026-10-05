import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.id,
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.navy,
    required this.navySoft,
    required this.accent,
    required this.accentSoft,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.sidebarGradient,
    required this.heroGradient,
  });

  final String id;
  final String name;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color navy;
  final Color navySoft;
  final Color accent;
  final Color accentSoft;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final LinearGradient sidebarGradient;
  final LinearGradient heroGradient;

  TextStyle heading(
    double size, {
    Color? color,
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: AppTheme.headingFont,
    fontSize: size,
    fontWeight: weight,
    color: color ?? textPrimary,
    height: 1.3,
  );

  @override
  AppPalette copyWith({
    String? id,
    String? name,
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? navy,
    Color? navySoft,
    Color? accent,
    Color? accentSoft,
    Color? background,
    Color? surface,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    LinearGradient? sidebarGradient,
    LinearGradient? heroGradient,
  }) => AppPalette(
    id: id ?? this.id,
    name: name ?? this.name,
    primary: primary ?? this.primary,
    primaryDark: primaryDark ?? this.primaryDark,
    primaryLight: primaryLight ?? this.primaryLight,
    navy: navy ?? this.navy,
    navySoft: navySoft ?? this.navySoft,
    accent: accent ?? this.accent,
    accentSoft: accentSoft ?? this.accentSoft,
    background: background ?? this.background,
    surface: surface ?? this.surface,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    border: border ?? this.border,
    sidebarGradient: sidebarGradient ?? this.sidebarGradient,
    heroGradient: heroGradient ?? this.heroGradient,
  );

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      id: t < 0.5 ? id : other.id,
      name: t < 0.5 ? name : other.name,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      navy: Color.lerp(navy, other.navy, t)!,
      navySoft: Color.lerp(navySoft, other.navySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      sidebarGradient: LinearGradient.lerp(
        sidebarGradient,
        other.sidebarGradient,
        t,
      )!,
      heroGradient: LinearGradient.lerp(heroGradient, other.heroGradient, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get appPalette => Theme.of(this).extension<AppPalette>()!;
}

/// ชุดสีของหน้าจอระบบงานเงินเดือน
class AppTheme {
  AppTheme._();

  static const List<AppPalette> palettes = [
    AppPalette(
      id: 'highway',
      name: 'ทางหลวง',
      primary: Color(0xFF0D9488),
      primaryDark: Color(0xFF115E59),
      primaryLight: Color(0xFFCCFBF1),
      navy: Color(0xFF0F172A),
      navySoft: Color(0xFF1E293B),
      accent: Color(0xFFF59E0B),
      accentSoft: Color(0xFFFEF3C7),
      background: Color(0xFFF1F5F9),
      surface: Colors.white,
      textPrimary: Color(0xFF0F172A),
      textSecondary: Color(0xFF64748B),
      border: Color(0xFFE2E8F0),
      sidebarGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0F172A), Color(0xFF0B3B3A)],
      ),
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F766E), Color(0xFF0D9488), Color(0xFF14B8A6)],
      ),
    ),
    AppPalette(
      id: 'กรมท่า',
      name: 'กรมท่า',
      primary: Color(0xFF2563EB),
      primaryDark: Color(0xFF1D4ED8),
      primaryLight: Color(0xFFDBEAFE),
      navy: Color(0xFF14213D),
      navySoft: Color(0xFF1E3158),
      accent: Color(0xFFF59E0B),
      accentSoft: Color(0xFFFEF3C7),
      background: Color(0xFFF1F5F9),
      surface: Colors.white,
      textPrimary: Color(0xFF14213D),
      textSecondary: Color(0xFF64748B),
      border: Color(0xFFDBE3EF),
      sidebarGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF14213D), Color(0xFF1E3A6D)],
      ),
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF60A5FA)],
      ),
    ),
    AppPalette(
      id: 'ผืนป่า',
      name: 'ผืนป่า',
      primary: Color(0xFF15803D),
      primaryDark: Color(0xFF166534),
      primaryLight: Color(0xFFDCFCE7),
      navy: Color(0xFF18392B),
      navySoft: Color(0xFF20523A),
      accent: Color(0xFFE11D48),
      accentSoft: Color(0xFFFFE4E6),
      background: Color(0xFFF1F7F2),
      surface: Colors.white,
      textPrimary: Color(0xFF18392B),
      textSecondary: Color(0xFF5D7264),
      border: Color(0xFFDCE9DE),
      sidebarGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF18392B), Color(0xFF245A3D)],
      ),
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF166534), Color(0xFF15803D), Color(0xFF4DAB68)],
      ),
    ),
    AppPalette(
      id: 'อำพัน',
      name: 'อำพัน',
      primary: Color(0xFFB45309),
      primaryDark: Color(0xFF92400E),
      primaryLight: Color(0xFFFEF3C7),
      navy: Color(0xFF3E2C1C),
      navySoft: Color(0xFF513A25),
      accent: Color(0xFF0F766E),
      accentSoft: Color(0xFFCCFBF1),
      background: Color(0xFFFBF6ED),
      surface: Colors.white,
      textPrimary: Color(0xFF3E2C1C),
      textSecondary: Color(0xFF75634F),
      border: Color(0xFFEDE1CE),
      sidebarGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3E2C1C), Color(0xFF62401F)],
      ),
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF92400E), Color(0xFFB45309), Color(0xFFE79A32)],
      ),
    ),
    AppPalette(
      id: 'กุหลาบ',
      name: 'กุหลาบ',
      primary: Color(0xFFBE123C),
      primaryDark: Color(0xFF9F1239),
      primaryLight: Color(0xFFFFE4E6),
      navy: Color(0xFF3F1725),
      navySoft: Color(0xFF5A2133),
      accent: Color(0xFF047857),
      accentSoft: Color(0xFFD1FAE5),
      background: Color(0xFFFFF5F6),
      surface: Colors.white,
      textPrimary: Color(0xFF3F1725),
      textSecondary: Color(0xFF765A63),
      border: Color(0xFFF0DDE2),
      sidebarGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF3F1725), Color(0xFF752540)],
      ),
      heroGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF9F1239), Color(0xFFBE123C), Color(0xFFE45A78)],
      ),
    ),
  ];

  static AppPalette paletteFor(String? id) => palettes.firstWhere(
    (palette) => palette.id == id,
    orElse: () => palettes.first,
  );

  static ThemeData themeFor(String? id) {
    final palette = paletteFor(id);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.primary,
        primary: palette.primary,
        secondary: palette.accent,
        surface: palette.surface,
      ),
      scaffoldBackgroundColor: palette.background,
      fontFamily: bodyFont,
      extensions: [palette],
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: bodyFont,
        bodyColor: palette.textPrimary,
        displayColor: palette.textPrimary,
      ),
      tooltipTheme: const TooltipThemeData(
        textStyle: TextStyle(
          fontFamily: bodyFont,
          color: Colors.white,
          fontSize: 13,
        ),
        decoration: BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
    );
  }

  /// ฟอนต์เนื้อหา
  static const String bodyFont = 'Sarabun';

  /// ฟอนต์หัวข้อ
  static const String headingFont = 'Kanit';

  /// ข้อความหัวข้อ
  static TextStyle heading(
    double size, {
    Color color = const Color(0xFF0F172A),
    FontWeight weight = FontWeight.w500,
  }) => TextStyle(
    fontFamily: headingFont,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.3,
  );
}
