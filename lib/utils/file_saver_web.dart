import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// สร้างลิงก์ชั่วคราวชี้ข้อมูลในหน่วยความจำ แล้วกดให้เบราว์เซอร์บันทึกเป็นไฟล์
void saveFile(String name, Uint8List bytes) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  final a = web.HTMLAnchorElement()
    ..href = url
    ..download = name
    ..style.display = 'none';
  web.document.body!.appendChild(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
}
