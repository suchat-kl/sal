import 'package:flutter/material.dart';

import '../config/theme.dart';

/// ตัวแบ่งหน้ามาตรฐานของระบบ (แบบเดียวกับ AppPagination ของ HTC)
/// เลือกแถวต่อหน้า 5/10/15/20 (ค่าเริ่มต้น 10) + ปุ่มเลขหน้า 5 ปุ่ม + หน้าแรก/ก่อนหน้า/ถัดไป/สุดท้าย
class AppPagination extends StatelessWidget {
  static const List<int> sizes = [5, 10, 15, 20];
  static const int defaultSize = 10;

  /// หน้าปัจจุบัน เริ่มที่ 0
  final int page;
  final int pageSize;
  final int totalItems;
  final ValueChanged<int> onPage;
  final ValueChanged<int> onPageSize;
  final bool enabled;

  const AppPagination({
    super.key,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.onPage,
    required this.onPageSize,
    this.enabled = true,
  });

  static int pageCount(int totalItems, int pageSize) =>
      totalItems <= 0 ? 0 : ((totalItems - 1) ~/ pageSize) + 1;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final pages = pageCount(totalItems, pageSize);
    final last = pages - 1;
    final text = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 14,
      color: palette.textSecondary,
    );
    // ปุ่มเลขหน้า 5 ปุ่ม ให้หน้าปัจจุบันอยู่กลางเมื่อทำได้
    var from = page - 2;
    if (from > last - 4) from = last - 4;
    if (from < 0) from = 0;
    final to = from + 4 > last ? last : from + 4;
    final first = totalItems == 0 ? 0 : page * pageSize + 1;
    final end = (page + 1) * pageSize > totalItems
        ? totalItems
        : (page + 1) * pageSize;

    Widget nav(String tip, IconData icon, int target, bool on) => IconButton(
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon),
      onPressed: enabled && on ? () => onPage(target) : null,
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'แสดง $first-$end จาก $totalItems รายการ   แถวต่อหน้า',
              style: text,
            ),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: pageSize,
              underline: const SizedBox.shrink(),
              style: text.copyWith(color: palette.textPrimary),
              items: [
                for (final s in {...sizes, pageSize}.toList()..sort())
                  DropdownMenuItem(value: s, child: Text('$s')),
              ],
              onChanged: enabled
                  ? (v) {
                      if (v != null && v != pageSize) onPageSize(v);
                    }
                  : null,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            nav('หน้าแรก', Icons.first_page, 0, page > 0),
            nav('ก่อนหน้า', Icons.chevron_left, page - 1, page > 0),
            for (var p = from; p <= to; p++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: p == page
                    ? Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p + 1}',
                          style: const TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : SizedBox(
                        width: 34,
                        height: 34,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(34, 34),
                            foregroundColor: palette.textPrimary,
                          ),
                          onPressed: enabled ? () => onPage(p) : null,
                          child: Text(
                            '${p + 1}',
                            style: const TextStyle(
                              fontFamily: AppTheme.bodyFont,
                            ),
                          ),
                        ),
                      ),
              ),
            nav('ถัดไป', Icons.chevron_right, page + 1, page < last),
            nav('หน้าสุดท้าย', Icons.last_page, last, page < last),
          ],
        ),
      ],
    );
  }
}
