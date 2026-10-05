import 'package:flutter/material.dart';

import '../config/menu_data.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import 'app_logo.dart';

/// แถบหัวด้านบน: โลโก้ ชื่อระบบ ตัวเลือกธีม และปุ่มเข้าสู่ระบบ
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  /// แสดงปุ่มเปิดเมนู (ตอนเมนูไม่ได้ตรึง)
  final bool showMenuButton;
  final String selectedThemeId;
  final ValueChanged<String> onThemeChanged;
  final AuthProvider auth;
  final VoidCallback onLogin;
  final VoidCallback onLogout;

  /// เลือกเมนูผู้ใช้จากปุ่มชื่อผู้ใช้ (ส่งรหัสเมนูใน [MenuData])
  final ValueChanged<String> onUserAction;

  const AppHeader({
    super.key,
    required this.showMenuButton,
    required this.selectedThemeId,
    required this.onThemeChanged,
    required this.auth,
    required this.onLogin,
    required this.onLogout,
    required this.onUserAction,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.of(context).size.width < 600;
    final palette = context.appPalette;
    return Container(
      height: preferredSize.height,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
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
                icon: Icon(Icons.menu_rounded, color: palette.textPrimary),
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
                    style: context.appPalette.heading(
                      20,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (!narrow)
                    Text(
                      'ระบบดาวน์โหลดเอกสารงานเงินเดือน กรมทางหลวง',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'เปลี่ยนธีม',
              initialValue: selectedThemeId,
              onSelected: onThemeChanged,
              itemBuilder: (context) => [
                for (final theme in AppTheme.palettes)
                  PopupMenuItem<String>(
                    value: theme.id,
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: theme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(theme.name)),
                        if (theme.id == selectedThemeId)
                          const Icon(Icons.check_rounded, size: 18),
                      ],
                    ),
                  ),
              ],
              icon: const Icon(Icons.palette_outlined),
            ),
            if (auth.isLoggedIn)
              _userMenu(context, narrow)
            else
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? 12 : 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onLogin,
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

  /// ปุ่มชื่อผู้ใช้ที่เข้าสู่ระบบอยู่ กดแล้วเลือกหน้าผู้ใช้งาน เปลี่ยนรหัสผ่าน หรือออกจากระบบ
  Widget _userMenu(BuildContext context, bool narrow) {
    final palette = context.appPalette;
    PopupMenuItem<String> item(String value, IconData icon, String text) =>
        PopupMenuItem<String>(
          value: value,
          child: Row(
            children: [
              Icon(icon, size: 20, color: palette.textSecondary),
              const SizedBox(width: 12),
              Text(text, style: const TextStyle(fontFamily: AppTheme.bodyFont)),
            ],
          ),
        );
    return PopupMenuButton<String>(
      tooltip: 'บัญชีผู้ใช้',
      position: PopupMenuPosition.under,
      onSelected: (v) => v == 'logout' ? onLogout() : onUserAction(v),
      itemBuilder: (context) => [
        item(MenuData.accountId, Icons.account_circle_rounded, 'หน้าผู้ใช้งาน'),
        item(MenuData.changePasswordId, Icons.key_rounded, 'เปลี่ยนรหัสผ่าน'),
        const PopupMenuDivider(),
        item('logout', Icons.logout_rounded, 'ออกจากระบบ'),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: narrow ? 8 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: palette.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded, color: palette.primaryDark, size: 22),
            if (!narrow) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(
                  auth.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontWeight: FontWeight.w500,
                    color: palette.primaryDark,
                  ),
                ),
              ),
            ],
            Icon(Icons.arrow_drop_down, color: palette.primaryDark),
          ],
        ),
      ),
    );
  }
}
