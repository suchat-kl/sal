import 'package:flutter/material.dart';

import '../config/theme.dart';

/// สีปุ่มตามหน้าที่ (ไม่เปลี่ยนตามธีม) — ชุดเดียวกับ HTC
class ActionColors {
  ActionColors._();
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color cancel = Color(0xFFEA580C);
  static const Color warning = Color(0xFFD97706);
}

/// กรอบ dialog แบบเดียวกับหน้าเข้าสู่ระบบของ HTC: หัวไล่สีตามธีม + ไอคอน + ชื่อ แล้วตามด้วยเนื้อหา
class DialogShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final double maxWidth;

  const DialogShell({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final wide = MediaQuery.of(context).size.width > 600;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(wide ? 40 : 16),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: palette.primary.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(wide ? 24 : 18),
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: palette.primary, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTheme.heading(
                            wide ? 20 : 18,
                            color: Colors.white,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              // ต้องมี Material ของตัวเอง ไม่งั้น ListTile/Switch ในฟอร์มวาด ink ไม่ขึ้นบนพื้นสีของ dialog
              child: Material(
                type: MaterialType.transparency,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(wide ? 24 : 18),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// หน้าตาช่องกรอกที่ใช้ทุกฟอร์ม
InputDecoration appInput(
  BuildContext context, {
  required String label,
  String? hint,
  IconData? icon,
  Widget? suffix,
}) {
  final palette = context.appPalette;
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c, width: w),
  );
  const font = TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 15);
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: font,
    hintStyle: font.copyWith(color: palette.textSecondary),
    errorStyle: const TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 12.5),
    prefixIcon: icon == null ? null : Icon(icon),
    suffixIcon: suffix,
    border: border(palette.border),
    enabledBorder: border(palette.border),
    focusedBorder: border(palette.primary, 2),
    filled: true,
    fillColor: palette.background,
    isDense: true,
  );
}

const TextStyle fieldText = TextStyle(
  fontFamily: AppTheme.bodyFont,
  fontSize: 16,
);

/// กล่องข้อความผิดพลาดสีแดง ปิดได้
class ErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;

  const ErrorBox({super.key, required this.message, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: AppTheme.bodyFont,
                color: Color(0xFFB91C1C),
                fontSize: 14,
              ),
            ),
          ),
          if (onClose != null)
            InkWell(
              onTap: onClose,
              child: const Icon(
                Icons.close,
                color: Color(0xFFB91C1C),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}

/// กติการหัสผ่าน — ต้องตรงกับ PasswordService.validateStrength ฝั่ง backend
class PasswordRule {
  final String label;
  final bool Function(String) test;
  const PasswordRule(this.label, this.test);

  static final List<PasswordRule> all = [
    PasswordRule('ยาวอย่างน้อย 8 ตัวอักษร', (p) => p.length >= 8),
    PasswordRule('มีตัวพิมพ์ใหญ่ (A-Z)', (p) => RegExp(r'[A-Z]').hasMatch(p)),
    PasswordRule('มีตัวพิมพ์เล็ก (a-z)', (p) => RegExp(r'[a-z]').hasMatch(p)),
    PasswordRule('มีตัวเลข (0-9)', (p) => RegExp(r'\d').hasMatch(p)),
    PasswordRule(
      'มีอักขระพิเศษ เช่น @ # ! _',
      (p) => RegExp(r'[^A-Za-z0-9]').hasMatch(p),
    ),
  ];

  /// null = ผ่านทุกข้อ
  static String? problem(String? password) {
    final p = password ?? '';
    if (p.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    for (final r in all) {
      if (!r.test(p)) return 'รหัสผ่านต้อง${r.label}';
    }
    return null;
  }
}

/// รายการกติการหัสผ่าน ติ๊กเขียวเมื่อผ่านแต่ละข้อ
class PasswordChecklist extends StatelessWidget {
  final String password;

  const PasswordChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in PasswordRule.all)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    r.test(password)
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: r.test(password)
                        ? ActionColors.success
                        : palette.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.label,
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13.5,
                        color: r.test(password)
                            ? ActionColors.success
                            : palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ปุ่มหลัก (สีธีม) กับปุ่มยกเลิก (ส้ม) เรียงซ้อนกันแบบหน้าเข้าสู่ระบบ
class DialogButtons extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback? onCancel;
  final String cancelLabel;

  const DialogButtons({
    super.key,
    required this.label,
    required this.icon,
    required this.loading,
    required this.onSubmit,
    required this.onCancel,
    this.cancelLabel = 'ยกเลิก',
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const text = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: loading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: palette.primary,
              shape: shape,
            ),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, size: 20),
            label: Text(label, style: text),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton(
            onPressed: loading ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: ActionColors.cancel,
              side: const BorderSide(color: ActionColors.cancel),
              shape: shape,
            ),
            child: Text(cancelLabel, style: text),
          ),
        ),
      ],
    );
  }
}

/// แจ้งผลสำเร็จ/ผิดพลาดด้านล่างจอ
void showAppMessage(
  BuildContext context,
  String message, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? ActionColors.danger : ActionColors.success,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
