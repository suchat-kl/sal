import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../widgets/form_helpers.dart';

/// คำตอบเมื่อถามว่ามีการแก้ไขที่ยังไม่ได้บันทึก
enum UnsavedChoice { save, discard, stay }

/// ถามก่อนปิดหน้าจอที่มีการแก้ไขค้างอยู่: บันทึก / ไม่บันทึก / กลับไปแก้ไขต่อ
/// [saveLabel] ใช้ชื่อการกระทำของหน้าจอนั้น เช่น "บันทึก" หรือ "สร้างผู้ใช้งาน"
Future<UnsavedChoice> askUnsaved(
  BuildContext context, {
  String saveLabel = 'บันทึก',
}) async {
  const font = TextStyle(fontFamily: AppTheme.bodyFont);
  final choice = await showDialog<UnsavedChoice>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('ยังไม่ได้บันทึกการแก้ไข', style: AppTheme.heading(19)),
      content: Text(
        'มีข้อมูลที่แก้ไขแล้วยังไม่ได้บันทึก ต้องการบันทึกก่อนปิดหน้าจอหรือไม่',
        style: font.copyWith(fontSize: 15.5),
      ),
      actionsAlignment: MainAxisAlignment.end,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(UnsavedChoice.stay),
          child: const Text('กลับไปแก้ไขต่อ', style: font),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: ActionColors.cancel,
            side: const BorderSide(color: ActionColors.cancel),
          ),
          onPressed: () => Navigator.of(context).pop(UnsavedChoice.discard),
          child: const Text('ไม่บันทึก', style: font),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: context.appPalette.primary,
          ),
          onPressed: () => Navigator.of(context).pop(UnsavedChoice.save),
          child: Text(saveLabel, style: font),
        ),
      ],
    ),
  );
  return choice ?? UnsavedChoice.stay;
}

/// ด่านกลางของ "ออกจากหน้าจอนี้ได้ไหม" — หน้าจอที่มีฟอร์มลงทะเบียนตัวตรวจไว้ตอนเปิด
/// ผู้ที่จะพาออกจากหน้าจอ (เมนูข้าง ปุ่มออกจากระบบ) เรียก [canLeave] ก่อนเสมอ
class UnsavedGuard {
  UnsavedGuard._();

  static Future<bool> Function()? _check;

  static void register(Future<bool> Function() check) => _check = check;

  /// ถอนเฉพาะเมื่อยังเป็นตัวของหน้าจอนั้น (หน้าจอใหม่อาจลงทะเบียนทับก่อนหน้าจอเก่าถูกทิ้ง)
  static void unregister(Future<bool> Function() check) {
    // เทียบด้วย == : อ้าง method เดิมของ object เดิมแต่ละครั้งได้ object ใหม่ จึงใช้ identical ไม่ได้
    if (_check == check) _check = null;
  }

  /// true = ออกได้ (ไม่มีอะไรค้าง บันทึกสำเร็จแล้ว หรือผู้ใช้เลือกไม่บันทึก)
  static Future<bool> canLeave() async {
    final check = _check;
    return check == null ? true : check();
  }
}
