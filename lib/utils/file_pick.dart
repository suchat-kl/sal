import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// ไฟล์ที่ผู้ใช้เลือกจากเครื่อง
typedef PickedFile = ({String name, Uint8List bytes});

/// เปิดหน้าต่างเลือกไฟล์ของเบราว์เซอร์ — [override] ใช้ในเทสต์แทนการเลือกไฟล์จริง
class FilePick {
  FilePick._();

  static Future<PickedFile?> Function(List<String> extensions)? override;

  static Future<List<PickedFile>> Function(List<String> extensions)?
  overrideMany;

  /// เลือกได้หลายไฟล์พร้อมกัน คืนรายการว่างเมื่อผู้ใช้กดยกเลิก
  static Future<List<PickedFile>> pickMany(List<String> extensions) async {
    if (overrideMany != null) return overrideMany!(extensions);
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    return [
      for (final f in files) (name: f.name, bytes: await f.readAsBytes()),
    ];
  }

  /// คืน null เมื่อผู้ใช้กดยกเลิก
  static Future<PickedFile?> pick(List<String> extensions) async {
    if (override != null) return override!(extensions);
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (file == null) return null;
    return (name: file.name, bytes: await file.readAsBytes());
  }
}
