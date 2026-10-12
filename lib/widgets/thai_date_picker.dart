import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../utils/thai_date.dart';
import 'file_widgets.dart' show thaiMonths;
import 'form_helpers.dart';

/// เลือกวันที่จากปฏิทินไทย ปี พ.ศ. คืน null เมื่อปิดโดยไม่เลือก
/// (ตัวเลือกวันที่ของ Flutter แสดงปี ค.ศ. จึงทำปฏิทินเอง)
Future<DateTime?> showThaiDatePicker(
  BuildContext context, {
  DateTime? initial,
  String title = 'เลือกวันที่',
}) => showDialog<DateTime>(
  context: context,
  builder: (_) => _ThaiDatePicker(initial: initial, title: title),
);

class _ThaiDatePicker extends StatefulWidget {
  final DateTime? initial;
  final String title;

  const _ThaiDatePicker({required this.initial, required this.title});

  @override
  State<_ThaiDatePicker> createState() => _ThaiDatePickerState();
}

class _ThaiDatePickerState extends State<_ThaiDatePicker> {
  static const List<String> _weekdays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  late final DateTime _today = DateUtils.dateOnly(DateTime.now());

  /// วันแรกของเดือนที่กำลังแสดง
  late DateTime _month = DateTime(
    (widget.initial ?? _today).year,
    (widget.initial ?? _today).month,
  );

  void _move(int months) =>
      setState(() => _month = DateTime(_month.year, _month.month + months));

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    const font = TextStyle(fontFamily: AppTheme.bodyFont);
    final days = DateUtils.getDaysInMonth(_month.year, _month.month);
    // DateTime.weekday: จันทร์ = 1 ... อาทิตย์ = 7 ปฏิทินเริ่มที่วันอาทิตย์
    final lead = _month.weekday % 7;
    final selected = widget.initial;

    Widget nav(String tip, IconData icon, int months) => IconButton(
      tooltip: tip,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon),
      onPressed: () => _move(months),
    );

    Widget cell(int day) {
      final date = DateTime(_month.year, _month.month, day);
      final isSelected = DateUtils.isSameDay(selected, date);
      final isToday = DateUtils.isSameDay(_today, date);
      return Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: isSelected ? palette.primary : Colors.transparent,
          shape: CircleBorder(
            side: isToday && !isSelected
                ? BorderSide(color: palette.primary)
                : BorderSide.none,
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).pop(date),
            child: Center(
              child: Text(
                '$day',
                semanticsLabel: formatThaiDate(date),
                style: font.copyWith(
                  fontSize: 15,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isSelected ? Colors.white : palette.textPrimary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(widget.title, style: AppTheme.heading(19)),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                nav('ปีก่อนหน้า', Icons.keyboard_double_arrow_left, -12),
                nav('เดือนก่อนหน้า', Icons.chevron_left, -1),
                Expanded(
                  child: Text(
                    '${thaiMonths[_month.month - 1]} ${_month.year + 543}',
                    textAlign: TextAlign.center,
                    style: palette.heading(16, weight: FontWeight.w700),
                  ),
                ),
                nav('เดือนถัดไป', Icons.chevron_right, 1),
                nav('ปีถัดไป', Icons.keyboard_double_arrow_right, 12),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final w in _weekdays)
                  Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: font.copyWith(
                          fontSize: 13,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            // 6 แถวเสมอ ความสูงของหน้าต่างจึงไม่กระโดดตอนเปลี่ยนเดือน
            for (var row = 0; row < 6; row++)
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: _dayOrBlank(
                          row * 7 + col - lead + 1,
                          days,
                          cell,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_today),
          child: const Text('วันนี้', style: font),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: ActionColors.cancel),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก', style: font),
        ),
      ],
    );
  }

  /// ช่องก่อนวันที่ 1 และหลังวันสุดท้ายของเดือนเว้นว่าง
  static Widget _dayOrBlank(int day, int days, Widget Function(int) cell) =>
      day < 1 || day > days ? const SizedBox.shrink() : cell(day);
}
