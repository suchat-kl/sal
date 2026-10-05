import 'dart:math';

import 'package:flutter/material.dart';

import '../config/menu_data.dart';
import '../config/theme.dart';
import '../utils/link.dart';
import '../widgets/payroll_illustration.dart';

/// หน้าแรก: ภาพหัว + ทางลัดไปแต่ละระบบ + ข้อความอธิบายสองส่วน (ข้อความเดียวกับระบบเดิม)
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final pad = c.maxWidth < 600 ? 16.0 : 28.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(wide: wide),
                  const SizedBox(height: 28),
                  Text(
                    'บริการทั้งหมด',
                    style: context.appPalette.heading(
                      20,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'เลือกระบบที่ต้องการ ระบบจะเปิดในแท็บใหม่',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      color: context.appPalette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ShortcutGrid(width: c.maxWidth - pad * 2),
                  const SizedBox(height: 28),
                  _InfoSections(wide: wide),
                  const SizedBox(height: 32),
                  const _Footer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  final bool wide;

  const _Hero({required this.wide});

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_rounded,
                color: Colors.white,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'กรมทางหลวง',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'งานเงินเดือน',
          style: context.appPalette.heading(
            wide ? 40 : 32,
            color: Colors.white,
            weight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ดาวน์โหลดใบรับรองภาษี สลิปเงินเดือน รายการหักหนี้ และเอกสารฌาปนกิจ ได้ในที่เดียว',
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: wide ? 18 : 16,
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: context.appPalette.accent,
                foregroundColor: context.appPalette.navy,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => openLink(context, 'https://dbdoh.doh.go.th/yt/'),
              icon: const Icon(Icons.receipt_long_rounded),
              label: const Text(
                'ใบรับรองภาษี/สลิป กรมทางหลวง',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => openLink(context, MenuData.helpdeskUrl),
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text(
                'สอบถามปัญหา',
                style: TextStyle(fontFamily: AppTheme.bodyFont),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: context.appPalette.heroGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330D9488),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ลายวงกลมจาง ๆ มุมขวาบน
          Positioned(
            right: -80,
            top: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            // ลดความสูงการ์ดหัว: ขอบบน-ล่างเหลือ 24 และภาพประกอบเตี้ยลง
            padding: wide
                ? const EdgeInsets.symmetric(horizontal: 40, vertical: 24)
                : const EdgeInsets.all(20),
            child: wide
                ? Row(
                    children: [
                      Expanded(flex: 6, child: text),
                      const SizedBox(width: 24),
                      const Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 210,
                          child: PayrollIllustration(),
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      text,
                      const SizedBox(height: 16),
                      const SizedBox(height: 170, child: PayrollIllustration()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  final double width;

  const _ShortcutGrid({required this.width});

  @override
  Widget build(BuildContext context) {
    final cols = width >= 1000
        ? 4
        : width >= 700
        ? 3
        : width >= 460
        ? 2
        : 1;
    const gap = 16.0;
    final items = MenuData.shortcuts;
    // จัดเป็นแถว แถวละ cols ใบ การ์ดในแถวเดียวกันสูงเท่าใบที่ข้อความยาวที่สุด
    // ข้อความจึงแสดงครบทุกขนาดจอ ไม่ถูกตัดด้วย "…"
    return Column(
      children: [
        for (var i = 0; i < items.length; i += cols) ...[
          if (i > 0) const SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < cols; j++) ...[
                  if (j > 0) const SizedBox(width: gap),
                  Expanded(
                    child: i + j < items.length
                        ? _ShortcutCard(node: items[i + j])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ShortcutCard extends StatefulWidget {
  final MenuNode node;

  const _ShortcutCard({required this.node});

  @override
  State<_ShortcutCard> createState() => _ShortcutCardState();
}

class _ShortcutCardState extends State<_ShortcutCard> {
  final _random = Random();
  bool _hover = false;
  Offset _hoverOffset = Offset.zero;

  void _startHover() {
    final distance = _random.nextBool() ? -8.0 : 8.0;
    setState(() {
      _hover = true;
      _hoverOffset = _random.nextBool()
          ? Offset(distance, 0)
          : Offset(0, distance);
    });
  }

  void _endHover() {
    setState(() {
      _hover = false;
      _hoverOffset = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.node;
    return MouseRegion(
      onEnter: (_) => _startHover(),
      onExit: (_) => _endHover(),
      // ชี้เมาส์: การ์ดขยับแบบสุ่มและขยายเล็กน้อย
      child: AnimatedScale(
        scale: _hover ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            _hoverOffset.dx,
            _hoverOffset.dy,
            0,
          ),
          decoration: BoxDecoration(
            color: context.appPalette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hover
                  ? context.appPalette.primary.withValues(alpha: 0.5)
                  : context.appPalette.border,
            ),
            boxShadow: [
              BoxShadow(
                color: _hover
                    ? context.appPalette.primary.withValues(alpha: 0.13)
                    : const Color(0x0A0F172A),
                blurRadius: _hover ? 24 : 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => openLink(context, m.url!),
              // ไม่จำกัดความสูง: ความสูงของแถวมาจากการ์ดที่ข้อความยาวที่สุด (_ShortcutGrid)
              child: Container(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // ชี้เมาส์: ไอคอนหมุนหนึ่งรอบ (เลยไปนิดแล้วเด้งกลับ) เอาเมาส์ออกหมุนกลับ
                        AnimatedRotation(
                          turns: _hover ? 1 : 0,
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: _hover
                                  ? context.appPalette.heroGradient
                                  : null,
                              color: _hover
                                  ? null
                                  : context.appPalette.primaryLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              m.icon,
                              color: _hover
                                  ? Colors.white
                                  : context.appPalette.primaryDark,
                              size: 26,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: _hover
                              ? context.appPalette.primary
                              : context.appPalette.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      m.title,
                      style: context.appPalette.heading(
                        16,
                        weight: FontWeight.w500,
                      ),
                    ),
                    if (m.statusLabel != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: context.appPalette.accentSoft,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.science_outlined,
                              size: 15,
                              color: Color(0xFFB45309),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                m.statusLabel!,
                                style: const TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 12,
                                  color: Color(0xFF92400E),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      m.description ?? '',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13.5,
                        color: context.appPalette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ข้อความอธิบายสองส่วน — ข้อความเดียวกับหน้าแรกของระบบเดิม
class _InfoSections extends StatelessWidget {
  final bool wide;

  const _InfoSections({required this.wide});

  @override
  Widget build(BuildContext context) {
    final users = _InfoCard(
      icon: Icons.groups_2_rounded,
      iconColor: context.appPalette.primary,
      iconBg: context.appPalette.primaryLight,
      title: 'ผู้ใช้งานระบบประกอบด้วย',
      body:
          'เจ้าหน้าที่ฝ่ายบัญชีของแต่ละหน่วยงาน ใช้ดาวน์โหลดรายละเอียดการจ่ายเงิน และภาษีประจำปี '
          'ชื่อผู้ใช้งานใช้ค่าเดิม หลังจากเข้าระบบแล้วควรเปลี่ยนรหัสผ่านด้วย',
    );
    final help = _InfoCard(
      icon: Icons.support_agent_rounded,
      iconColor: const Color(0xFFB45309),
      iconBg: context.appPalette.accentSoft,
      title: 'สอบถามปัญหาเพิ่มเติม',
      body: 'สอบถามผ่านระบบ Smart Helpdesk ศูนย์เทคโนโลยีสารสนเทศ กรมทางหลวง',
      contacts: const [
        ('ศูนย์เทคโนโลยีสารสนเทศ', 'โทร. 26727 , 26728'),
        ('ฝ่ายบัญชี', 'โทร. 25035, 25036'),
      ],
      action: TextButton.icon(
        onPressed: () => openLink(context, MenuData.helpdeskUrl),
        icon: const Icon(Icons.open_in_new_rounded, size: 18),
        label: const Text(
          'สอบถามผ่านระบบ Smart Helpdesk',
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
    if (!wide) {
      return Column(children: [users, const SizedBox(height: 16), help]);
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: users),
          const SizedBox(width: 16),
          Expanded(child: help),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final List<(String, String)> contacts;
  final Widget? action;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    this.action,
    this.contacts = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.appPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.appPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: context.appPalette.heading(
                    19,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            body,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 15.5,
              height: 1.7,
              color: context.appPalette.textSecondary,
            ),
          ),
          for (final (who, tel) in contacts)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.call_rounded,
                    size: 18,
                    color: context.appPalette.primary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$who  ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(
                            text: tel,
                            style: TextStyle(
                              color: context.appPalette.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontFamily: AppTheme.bodyFont),
                    ),
                  ),
                ],
              ),
            ),
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year + 543;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        '© ศูนย์เทคโนโลยีสารสนเทศ กรมทางหลวง $year',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: AppTheme.bodyFont,
          color: context.appPalette.textSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}
