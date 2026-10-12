import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/announcement.dart';
import '../services/api_service.dart';
import '../utils/link.dart';
import 'linked_text.dart';

/// ส่วน "ประกาศ" ของหน้าแรก อยู่ใต้ภาพหัว (ยกแบบมาจากหน้าแรกของ HTC)
///
/// โหลดประกาศที่ยังมีผลเองตอนเปิดหน้าแรก (backend กรองสถานะและช่วงวันที่ให้แล้ว)
/// ไม่มีประกาศหรือโหลดไม่สำเร็จ = ไม่แสดงอะไรเลย หน้าแรกไม่มีช่องว่างและไม่ขึ้นข้อผิดพลาดให้คนนอกเห็น
class HomeAnnouncements extends StatefulWidget {
  final ApiService api;

  /// ตัวเปิดลิงก์ในเนื้อความ ปกติเปิดแท็บใหม่ด้วย [openLink] (เทสต์ใส่ตัวจำลองได้)
  final Future<void> Function(BuildContext context, String url) onOpenLink;

  const HomeAnnouncements({
    super.key,
    required this.api,
    this.onOpenLink = openLink,
  });

  @override
  State<HomeAnnouncements> createState() => _HomeAnnouncementsState();
}

class _HomeAnnouncementsState extends State<HomeAnnouncements> {
  List<Announcement> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.api.activeAnnouncements();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // โหลดไม่ได้ก็ซ่อนส่วนนี้ไป
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();
    final palette = context.appPalette;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      // ครอบด้วย SelectionArea ให้เลือก/คัดลอกข้อความประกาศได้
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.campaign_rounded, color: palette.primary, size: 26),
                const SizedBox(width: 8),
                Text(
                  'ประกาศ',
                  style: palette.heading(20, weight: FontWeight.w700),
                ),
              ],
            ),
            for (final a in _items) ...[
              const SizedBox(height: 12),
              _AnnouncementCard(
                item: a,
                onOpenLink: (url) => widget.onOpenLink(context, url),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// การ์ดประกาศหนึ่งใบ: แถบสีด้านซ้าย + ไอคอนลำโพง + หัวเรื่อง + เนื้อความ + ช่วงวันที่ประกาศ
class _AnnouncementCard extends StatelessWidget {
  final Announcement item;
  final ValueChanged<String> onOpenLink;

  const _AnnouncementCard({required this.item, required this.onOpenLink});

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final wide = MediaQuery.of(context).size.width >= 600;
    final period = item.periodLabel;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.accent.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      // แถบสีต้องสูงเท่าเนื้อหา แต่การ์ดอยู่ในหน้าที่เลื่อนได้ จึงต้องให้ Row รู้ความสูงก่อน
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 6, color: palette.accent),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(wide ? 20 : 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.campaign_rounded,
                        color: palette.primaryDark,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: palette.heading(
                              wide ? 19 : 17,
                              weight: FontWeight.w700,
                            ),
                          ),
                          if (item.message.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            LinkedText(
                              text: item.message,
                              linkColor: palette.primaryDark,
                              onOpen: onOpenLink,
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: wide ? 16 : 15,
                                height: 1.65,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                          if (period.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.event_rounded,
                                  size: 16,
                                  color: palette.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'ประกาศ $period',
                                    style: TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      fontSize: 13.5,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
