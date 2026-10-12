import '../utils/thai_date.dart';

/// ประกาศหนึ่งรายการ (ยกแบบมาจากประกาศประชาสัมพันธ์ของ HTC)
class Announcement {
  static const String statusActive = '1';
  static const String statusInactive = '2';

  final String? id;
  final String title;
  final String message;

  /// ช่วงวันที่ประกาศ ว่าง = ไม่กำหนด (เริ่มว่าง = แสดงทันที, สิ้นสุดว่าง = ไม่หมดอายุ)
  final DateTime? startDate;
  final DateTime? stopDate;

  /// ลำดับการแสดง น้อยมาก่อน
  final int sequence;

  /// '1' = ใช้งาน, '2' = ไม่ใช้งาน
  final String status;

  const Announcement({
    this.id,
    required this.title,
    this.message = '',
    this.startDate,
    this.stopDate,
    this.sequence = 0,
    this.status = statusActive,
  });

  factory Announcement.fromJson(Map<String, dynamic> j) => Announcement(
    id: j['id']?.toString(),
    title: (j['title'] ?? '').toString(),
    message: (j['message'] ?? '').toString(),
    startDate: parseIsoDate(j['startDate']),
    stopDate: parseIsoDate(j['stopDate']),
    sequence: switch (j['sequence']) {
      final num n => n.toInt(),
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    },
    // เส้นสาธารณะไม่ส่ง status มา (ส่งมาเฉพาะที่ใช้งานอยู่) จึงถือว่าใช้งาน
    status: (j['status'] ?? statusActive).toString(),
  );

  /// เนื้อคำขอของ POST/PUT — วันที่เป็น yyyy-MM-dd ค.ศ. หรือ null
  Map<String, dynamic> toBody() => {
    'title': title,
    'message': message,
    'startDate': toIsoDate(startDate),
    'stopDate': toIsoDate(stopDate),
    'sequence': sequence,
    'status': status,
  };

  bool get isActive => status == statusActive;

  /// วันนี้ประกาศนี้แสดงบนหน้าแรกอยู่ไหม: สถานะใช้งาน และวันนี้อยู่ในช่วงวันที่
  bool isShowing([DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    return isActive &&
        (startDate == null || !today.isBefore(startDate!)) &&
        (stopDate == null || !today.isAfter(stopDate!));
  }

  /// ช่วงวันที่ประกาศแบบไทย พ.ศ. ไม่กำหนดทั้งคู่ = ข้อความว่าง
  String get periodLabel => formatThaiDateRange(startDate, stopDate);
}
