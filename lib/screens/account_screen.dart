import 'package:flutter/material.dart';

import '../config/menu_data.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';

/// หน้าแรกหลังเข้าสู่ระบบ: ข้อมูลผู้ใช้ + การ์ดเมนูตามบทบาท
/// การ์ดชุดเดียวกับเมนูข้าง ([MenuData.userItems]) กดแล้วทำงานเดียวกัน
class AccountScreen extends StatelessWidget {
  final AuthProvider auth;
  final ValueChanged<String> onAction;

  const AccountScreen({super.key, required this.auth, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final items = [
      for (final m in auth.menuItems)
        if (m.id != MenuData.accountId) m,
    ];
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: palette.heroGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยินดีต้อนรับ คุณ${auth.displayName}',
                      style: AppTheme.heading(22, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        'ชื่อผู้ใช้ ${auth.username}',
                        'บทบาท ${auth.roleLabel}',
                        if (auth.divLabel != null) 'หน่วยงาน ${auth.divLabel}',
                      ].join('   ·   '),
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: palette.accentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.devices_other_rounded,
                color: palette.accent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  AuthProvider.singleDeviceNotice,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 14.5,
                    color: palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('เมนูผู้ใช้งาน', style: palette.heading(20)),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) {
            final columns = box.maxWidth >= 900
                ? 3
                : box.maxWidth >= 560
                ? 2
                : 1;
            const gap = 16.0;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final m in items)
                  SizedBox(
                    width: width,
                    child: _MenuCard(node: m, onTap: () => onAction(m.id)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MenuCard extends StatefulWidget {
  final MenuNode node;
  final VoidCallback onTap;

  const _MenuCard({required this.node, required this.onTap});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover ? palette.primary : palette.border,
            ),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: _hover ? 0.18 : 0.05),
                blurRadius: _hover ? 22 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedRotation(
                turns: _hover ? 1 : 0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: palette.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.node.icon,
                    color: palette.primaryDark,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.node.title, style: palette.heading(17)),
                    if (widget.node.description != null)
                      Text(
                        widget.node.description!,
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          color: palette.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
