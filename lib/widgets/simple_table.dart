import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'file_widgets.dart';

/// วันเวลาแบบไทย เช่น "5 ตุลาคม 2569 14:30" — รับทั้งเวลาที่มีเขตเวลา (แปลงเป็นเวลาเครื่อง) และไม่มี
String thaiDateTime(dynamic value) {
  var d = DateTime.tryParse('${value ?? ''}');
  if (d == null) return '-';
  if (d.isUtc) d = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.day} ${thaiMonths[d.month - 1]} ${d.year + 543} ${two(d.hour)}:${two(d.minute)}';
}

/// ตารางข้อความอย่างง่าย: หัวคอลัมน์ + แถว (ไม่แบ่งหน้าเอง ผู้เรียกวาง AppPagination ต่อท้าย)
class SimpleTable extends StatelessWidget {
  final List<String> headers;

  /// สัดส่วนความกว้างของแต่ละคอลัมน์
  final List<int> flex;
  final List<List<Widget>> rows;
  final String emptyText;

  const SimpleTable({
    super.key,
    required this.headers,
    required this.flex,
    required this.rows,
    required this.emptyText,
  });

  /// ข้อความในช่องตาราง
  static Widget cell(
    BuildContext context,
    String text, {
    Color? color,
    bool bold = false,
  }) => Text(
    text,
    style: TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 15,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color ?? context.appPalette.textPrimary,
    ),
  );

  /// ป้ายสถานะสีพื้นจาง
  static Widget chip(String text, Color color) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
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
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 15.5,
            color: palette.textSecondary,
          ),
        ),
      );
    }
    Widget line(List<Widget> cells) => Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: flex[i],
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: cells[i],
            ),
          ),
      ],
    );
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
            child: line([
              for (final h in headers)
                Text(
                  h,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
            ]),
          ),
          for (final r in rows) ...[
            Divider(height: 1, color: palette.border),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: line(r),
            ),
          ],
        ],
      ),
    );
  }
}
