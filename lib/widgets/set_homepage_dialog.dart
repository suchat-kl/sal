import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../utils/browser_name.dart';
import 'form_helpers.dart';

/// เปิดหน้าต่างบอกวิธีตั้ง [url] เป็นหน้าแรกของเบราว์เซอร์
///
/// เบราว์เซอร์ปัจจุบัน (Chrome, Edge, Firefox, Safari) ไม่ยอมให้หน้าเว็บแก้หน้าแรกเอง
/// จึงทำได้แค่คัดลอกที่อยู่ให้ แล้วบอกขั้นตอนตามเบราว์เซอร์ที่ผู้ใช้เปิดอยู่
Future<void> showSetHomepageDialog(BuildContext context, String url) {
  return showDialog<void>(
    context: context,
    builder: (_) => SetHomepageDialog(url: url, initial: detectBrowser()),
  );
}

class SetHomepageDialog extends StatefulWidget {
  final String url;
  final BrowserKind initial;

  const SetHomepageDialog({
    super.key,
    required this.url,
    required this.initial,
  });

  @override
  State<SetHomepageDialog> createState() => _SetHomepageDialogState();
}

class _SetHomepageDialogState extends State<SetHomepageDialog> {
  late BrowserKind _browser = widget.initial;
  bool _copied = false;

  static const _names = {
    BrowserKind.chrome: 'Chrome',
    BrowserKind.edge: 'Edge',
    BrowserKind.firefox: 'Firefox',
    BrowserKind.safari: 'Safari',
  };

  /// ชื่อเมนูใส่ทั้งไทยและอังกฤษ เพราะผู้ใช้ตั้งภาษาเบราว์เซอร์ต่างกัน
  List<String> _steps(BrowserKind b) => switch (b) {
    BrowserKind.chrome => const [
      'กดปุ่มสามจุดแนวตั้งมุมขวาบน แล้วเลือก "การตั้งค่า" (Settings)',
      'เลือก "เมื่อเริ่มต้นใช้งาน" (On startup)',
      'เลือก "เปิดหน้าเว็บหรือชุดหน้าเว็บที่เฉพาะเจาะจง" แล้วกด "เพิ่มหน้าใหม่"',
      'วางที่อยู่ที่คัดลอกไว้ แล้วกด "เพิ่ม"',
    ],
    BrowserKind.edge => const [
      'กดปุ่มสามจุดมุมขวาบน แล้วเลือก "การตั้งค่า" (Settings)',
      'เลือก "เริ่มต้น หน้าแรก และแท็บใหม่" (Start, home, and new tabs)',
      'ที่ "เมื่อ Edge เริ่มต้น" เลือก "เปิดหน้าเหล่านี้" แล้วกด "เพิ่มหน้าใหม่"',
      'วางที่อยู่ที่คัดลอกไว้ แล้วกด "เพิ่ม"',
    ],
    BrowserKind.firefox => const [
      'กดปุ่มสามขีดมุมขวาบน แล้วเลือก "การตั้งค่า" (Settings)',
      'เลือก "หน้าแรกและการเริ่มต้น" (Home)',
      'ที่ "หน้าต่างใหม่" เลือก "URL กำหนดเอง..." (Custom URLs)',
      'กด "เลือกไซต์ที่ต้องการ" แล้ววางที่อยู่ที่คัดลอกไว้แทนของเดิม',
    ],
    BrowserKind.safari => const [
      'เมนู Safari แล้วเลือก "การตั้งค่า" (Settings)',
      'เลือกแท็บ "ทั่วไป" (General)',
      'ที่ช่อง "หน้าโฮม" (Homepage) วางที่อยู่ที่คัดลอกไว้แทนของเดิม',
    ],
  };

  /// เบราว์เซอร์บางตัวปฏิเสธสิทธิ์คัดลอก ให้บอกผู้ใช้คัดลอกเองแทน
  bool _copyFailed = false;

  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: widget.url));
      if (mounted) {
        setState(() {
          _copied = true;
          _copyFailed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _copyFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    const body = TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 15);
    final steps = _steps(_browser);

    return DialogShell(
      icon: Icons.home_rounded,
      title: 'ตั้งเป็นหน้าแรก',
      subtitle: 'ให้เบราว์เซอร์เปิดมาเจอระบบงานของกรมทุกครั้ง',
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'เบราว์เซอร์ไม่อนุญาตให้เว็บไซต์ตั้งหน้าแรกให้เอง '
            'กรุณาคัดลอกที่อยู่ด้านล่าง แล้วทำตามขั้นตอน',
            style: body.copyWith(color: palette.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 14),
          // ที่อยู่ + ปุ่มคัดลอก
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    widget.url,
                    style: body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _copied
                        ? ActionColors.success
                        : palette.primary,
                  ),
                  onPressed: _copy,
                  icon: Icon(
                    _copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _copied ? 'คัดลอกแล้ว' : 'คัดลอก',
                    style: const TextStyle(fontFamily: AppTheme.bodyFont),
                  ),
                ),
              ],
            ),
          ),
          if (_copyFailed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'คัดลอกให้ไม่ได้ กรุณาลากเลือกที่อยู่ด้านบนแล้วกด Ctrl+C',
                style: body.copyWith(fontSize: 13, color: ActionColors.danger),
              ),
            ),
          const SizedBox(height: 18),
          // เลือกเบราว์เซอร์ได้เอง เผื่อเดาผิด
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in BrowserKind.values)
                ChoiceChip(
                  label: Text(
                    _names[b]!,
                    style: const TextStyle(fontFamily: AppTheme.bodyFont),
                  ),
                  selected: _browser == b,
                  onSelected: (_) => setState(() => _browser = b),
                ),
            ],
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: palette.primary,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[i],
                      style: body.copyWith(
                        color: palette.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'บนมือถือ ใช้เมนู "เพิ่มไปยังหน้าจอหลัก" (Add to Home screen) '
            'เพื่อสร้างไอคอนเปิดระบบแทนได้',
            style: body.copyWith(fontSize: 13, color: palette.textSecondary),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'ปิด',
                style: TextStyle(fontFamily: AppTheme.bodyFont),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
