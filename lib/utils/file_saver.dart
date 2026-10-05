import 'dart:typed_data';

import 'file_saver_stub.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    as impl;

/// ให้เบราว์เซอร์บันทึก [bytes] เป็นไฟล์ชื่อ [name]
/// ดาวน์โหลดผ่านโค้ด (ไม่ใช่ลิงก์ตรง) เพราะ API ต้องแนบ token ใน header
///
/// [override] ใช้ในเทสต์เพื่อดูว่าไฟล์ไหนถูกบันทึก
class FileSaver {
  FileSaver._();

  static void Function(String name, Uint8List bytes)? override;

  static void save(String name, Uint8List bytes) =>
      (override ?? impl.saveFile)(name, bytes);
}
