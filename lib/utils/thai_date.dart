import '../widgets/file_widgets.dart' show thaiMonths;

/// วันที่แบบไทย ปี พ.ศ. เช่น "12 ตุลาคม 2569"
String formatThaiDate(DateTime d) =>
    '${d.day} ${thaiMonths[d.month - 1]} ${d.year + 543}';

/// ช่วงวันที่แบบไทย ย่อส่วนที่ซ้ำกัน
///   เดือนเดียวกัน  "12 - 16 ตุลาคม 2569"
///   ปีเดียวกัน     "28 ตุลาคม - 3 พฤศจิกายน 2569"
///   ข้ามปี         "28 ธันวาคม 2569 - 3 มกราคม 2570"
///   มีแต่วันเริ่ม   "ตั้งแต่ 12 ตุลาคม 2569"
///   มีแต่วันสิ้นสุด "ถึง 16 ตุลาคม 2569"
///   ไม่กำหนดทั้งคู่ = ข้อความว่าง
String formatThaiDateRange(DateTime? start, DateTime? stop) {
  if (start == null && stop == null) return '';
  if (stop == null) return 'ตั้งแต่ ${formatThaiDate(start!)}';
  if (start == null) return 'ถึง ${formatThaiDate(stop)}';
  if (start.year != stop.year) {
    return '${formatThaiDate(start)} - ${formatThaiDate(stop)}';
  }
  if (start.month != stop.month) {
    return '${start.day} ${thaiMonths[start.month - 1]} - ${formatThaiDate(stop)}';
  }
  if (start.day == stop.day) return formatThaiDate(start);
  return '${start.day} - ${formatThaiDate(stop)}';
}

/// วันที่ที่ส่งให้ backend: yyyy-MM-dd ปี ค.ศ. (ไม่กำหนด = null)
String? toIsoDate(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';

/// อ่านวันที่ yyyy-MM-dd จาก backend เหลือแต่ส่วนวัน อ่านไม่ได้ = null
DateTime? parseIsoDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  final d = DateTime.tryParse(value);
  return d == null ? null : DateTime(d.year, d.month, d.day);
}
