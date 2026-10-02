import 'package:flutter/material.dart';

import '../config/menu_data.dart';
import '../config/theme.dart';
import '../utils/link.dart';
import 'app_logo.dart';

/// แถบหัวด้านบน: โลโก้ ชื่อระบบ และปุ่มเข้าสู่ระบบ (ไปหน้าเข้าสู่ระบบของระบบเดิม)
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /// แสดงปุ่มเปิดเมนู (ตอนเมนูไม่ได้ตรึง)
  final bool showMenuButton;

  const AppHeader({super.key, required this.showMenuButton});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 600;
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (showMenuButton)
              IconButton(
                tooltip: 'เมนู',
                icon: const Icon(
                  Icons.menu_rounded,
                  color: AppTheme.textPrimary,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            const SizedBox(width: 4),
            const AppLogo(size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'งานเงินเดือน',
                    style: AppTheme.heading(20, weight: FontWeight.w700),
                  ),
                  if (!narrow)
                    const Text(
                      'ระบบดาวน์โหลดเอกสารงานเงินเดือน กรมทางหลวง',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: narrow ? 12 : 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => openLink(context, MenuData.legacyLoginUrl),
              icon: const Icon(Icons.login_rounded, size: 18),
              label: Text(
                narrow ? 'เข้าสู่ระบบ' : 'เข้าสู่ระบบเจ้าหน้าที่',
                style: const TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
