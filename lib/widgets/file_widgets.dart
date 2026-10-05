import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'app_pagination.dart';
import 'form_helpers.dart';

/// ชื่อเดือนภาษาไทย (ตำแหน่ง 0 = มกราคม)
const List<String> thaiMonths = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

/// ปี พ.ศ. ปัจจุบัน
int currentBuddhistYear() => DateTime.now().year + 543;

/// ขนาดไฟล์แบบอ่านง่าย เช่น 52.2 KB
String formatSize(num? bytes) {
  final b = (bytes ?? 0).toDouble();
  if (b < 1024) return '${b.toInt()} B';
  if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
  return '${(b / 1024 / 1024).toStringAsFixed(2)} MB';
}

/// ไอคอนและสีตามนามสกุลไฟล์
(IconData, Color) fileIcon(String name) {
  final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
  return switch (ext) {
    'pdf' => (Icons.picture_as_pdf_rounded, const Color(0xFFDC2626)),
    'doc' || 'docx' => (Icons.description_rounded, const Color(0xFF2563EB)),
    'xls' || 'xlsx' => (Icons.table_chart_rounded, const Color(0xFF16A34A)),
    'jpg' || 'jpeg' || 'png' => (Icons.image_rounded, const Color(0xFF9333EA)),
    'zip' => (Icons.folder_zip_rounded, const Color(0xFFD97706)),
    _ => (Icons.insert_drive_file_rounded, const Color(0xFF64748B)),
  };
}

/// เลือกปี พ.ศ. และเดือน — ระบบเก็บไฟล์ปีปัจจุบันกับปีที่ผ่านมา จึงให้เลือกสองปีนี้
class PeriodPicker extends StatelessWidget {
  final int year;
  final int month;
  final void Function(int year, int month) onChanged;
  final bool enabled;

  const PeriodPicker({
    super.key,
    required this.year,
    required this.month,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final now = currentBuddhistYear();
    const text = TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 16);
    return Wrap(
      spacing: 14,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 170,
          child: DropdownButtonFormField<int>(
            key: const ValueKey('period-year'),
            initialValue: year,
            style: text.copyWith(color: context.appPalette.textPrimary),
            decoration: appInput(context, label: 'ปี พ.ศ.', icon: Icons.event),
            items: [
              for (final y in {
                now,
                now - 1,
                year,
              }.toList()..sort((a, b) => b - a))
                DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: enabled ? (v) => onChanged(v ?? year, month) : null,
          ),
        ),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<int>(
            key: const ValueKey('period-month'),
            initialValue: month,
            style: text.copyWith(color: context.appPalette.textPrimary),
            decoration: appInput(
              context,
              label: 'เดือน',
              icon: Icons.calendar_month,
            ),
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(value: m, child: Text(thaiMonths[m - 1])),
            ],
            onChanged: enabled ? (v) => onChanged(year, v ?? month) : null,
          ),
        ),
      ],
    );
  }
}

/// กรอบหัวข้อของแต่ละส่วนในหน้าอัปโหลด/ดาวน์โหลด
class SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  const SectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return Material(
      color: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.primaryLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: palette.primaryDark, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: palette.heading(18)),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 14,
                            color: palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// แถวหนึ่งของตารางไฟล์
class FileRow {
  final String name;
  final num? size;

  /// ข้อความรองใต้ชื่อไฟล์ เช่นประเภทบุคคล
  final String? note;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  const FileRow({
    required this.name,
    this.size,
    this.note,
    this.onDownload,
    this.onDelete,
  });
}

/// ตารางไฟล์: ไอคอนชนิดไฟล์ ชื่อไฟล์ ขนาดไฟล์ และลิงก์ดาวน์โหลดของแต่ละไฟล์
///
/// แบ่งหน้าในตัว: ค่าเริ่มต้นหน้าละ 10 แถว เลือกได้ 5/10/15/20 (ตัวแบ่งหน้าแสดงเมื่อมีมากกว่า 5 แถว)
class FileTable extends StatefulWidget {
  final List<FileRow> rows;
  final String emptyText;

  /// ชื่อไฟล์ที่กำลังดาวน์โหลด/ลบอยู่ (แสดงวงหมุนแทนปุ่ม)
  final String? busyName;

  const FileTable({
    super.key,
    required this.rows,
    required this.emptyText,
    this.busyName,
  });

  @override
  State<FileTable> createState() => _FileTableState();
}

class _FileTableState extends State<FileTable> {
  int _page = 0;
  int _size = AppPagination.defaultSize;

  @override
  Widget build(BuildContext context) {
    final all = widget.rows;
    // รายการเปลี่ยน (เปลี่ยนเดือน/หน่วยงาน หรือลบไฟล์) แล้วหน้าเดิมเกินช่วง ให้ถอยมาหน้าสุดท้ายที่มี
    final pages = AppPagination.pageCount(all.length, _size);
    final page = _page >= pages ? (pages == 0 ? 0 : pages - 1) : _page;
    final visible = all.skip(page * _size).take(_size).toList();
    final table = _FileTableView(
      rows: visible,
      emptyText: widget.emptyText,
      busyName: widget.busyName,
      // ความกว้างคอลัมน์ปุ่มคิดจากทั้งรายการ ไม่งั้นตารางขยับเมื่อเปลี่ยนหน้า
      hasDelete: all.any((r) => r.onDelete != null),
    );
    if (all.length <= AppPagination.sizes.first) return table;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        table,
        const SizedBox(height: 10),
        AppPagination(
          page: page,
          pageSize: _size,
          totalItems: all.length,
          onPage: (p) => setState(() => _page = p),
          onPageSize: (s) => setState(() {
            _size = s;
            _page = 0;
          }),
        ),
      ],
    );
  }
}

/// ตัวตารางของหน้าเดียว
class _FileTableView extends StatelessWidget {
  final List<FileRow> rows;
  final String emptyText;
  final String? busyName;
  final bool hasDelete;

  const _FileTableView({
    required this.rows,
    required this.emptyText,
    required this.hasDelete,
    this.busyName,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final head = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: palette.textSecondary,
    );
    final cell = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 15.5,
      color: palette.textPrimary,
    );
    if (rows.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
          style: cell.copyWith(color: palette.textSecondary),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: palette.background,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const SizedBox(width: 38),
                Expanded(child: Text('ชื่อไฟล์', style: head)),
                SizedBox(
                  width: 96,
                  child: Text(
                    'ขนาดไฟล์',
                    style: head,
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(width: hasDelete ? 190 : 130),
              ],
            ),
          ),
          for (final r in rows) ...[
            Divider(height: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                children: [
                  SizedBox(
                    width: 38,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        fileIcon(r.name).$1,
                        color: fileIcon(r.name).$2,
                        size: 26,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name, style: cell),
                        if (r.note != null)
                          Text(
                            r.note!,
                            style: cell.copyWith(
                              fontSize: 13.5,
                              color: palette.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: Text(
                      formatSize(r.size),
                      style: cell,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  SizedBox(
                    width: hasDelete ? 190 : 130,
                    child: busyName == r.name
                        ? const Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (r.onDownload != null)
                                TextButton.icon(
                                  onPressed: r.onDownload,
                                  icon: const Icon(
                                    Icons.download_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'ดาวน์โหลด',
                                    style: TextStyle(
                                      fontFamily: AppTheme.bodyFont,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              if (r.onDelete != null)
                                IconButton(
                                  tooltip: 'ลบไฟล์ ${r.name}',
                                  onPressed: r.onDelete,
                                  color: ActionColors.danger,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ถามยืนยันก่อนทำสิ่งที่ย้อนไม่ได้ คืน true เมื่อผู้ใช้ยืนยัน
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'ยกเลิก',
  bool danger = false,
}) async {
  const font = TextStyle(fontFamily: AppTheme.bodyFont);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: AppTheme.heading(19)),
      content: Text(message, style: font.copyWith(fontSize: 15.5)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel, style: font),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: danger
                ? ActionColors.danger
                : context.appPalette.primary,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel, style: font),
        ),
      ],
    ),
  );
  return ok == true;
}
