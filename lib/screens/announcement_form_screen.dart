import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../models/announcement.dart';
import '../services/api_service.dart';
import '../utils/thai_date.dart';
import '../utils/unsaved_guard.dart';
import '../widgets/form_helpers.dart';
import '../widgets/thai_date_picker.dart';

/// หน้าเพิ่ม/แก้ไขประกาศ (ADMIN) — [item] = null คือเพิ่มใหม่
/// แสดงในพื้นที่เนื้อหาข้างเมนู (ไม่ใช่ dialog) แบบเดียวกับหน้าสร้าง/แก้ไขผู้ใช้งาน
class AnnouncementFormScreen extends StatefulWidget {
  static const int titleMax = 200;
  static const int messageMax = 2000;

  final ApiService api;
  final Announcement? item;

  /// บันทึกสำเร็จ
  final VoidCallback onSaved;

  /// กดยกเลิก/ปิด
  final VoidCallback onCancel;

  const AnnouncementFormScreen({
    super.key,
    required this.api,
    required this.onSaved,
    required this.onCancel,
    this.item,
  });

  @override
  State<AnnouncementFormScreen> createState() => _AnnouncementFormScreenState();
}

class _AnnouncementFormScreenState extends State<AnnouncementFormScreen> {
  static const String _dateOrderProblem =
      'วันที่สิ้นสุดต้องไม่ก่อนวันที่เริ่มประกาศ';

  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.item?.title ?? '');
  late final _message = TextEditingController(text: widget.item?.message ?? '');
  late final _sequence = TextEditingController(
    text: '${widget.item?.sequence ?? 0}',
  );
  late DateTime? _start = widget.item?.startDate;
  late DateTime? _stop = widget.item?.stopDate;
  late bool _active = widget.item?.isActive ?? true;

  bool _saving = false;
  String? _error;

  /// ข้อผิดพลาดของช่วงวันที่ แสดงใต้ช่องวันที่สิ้นสุด
  String? _dateError;

  /// ค่าทุกช่องตอนเปิดหน้าจอ ใช้เทียบว่ามีการแก้ไขหรือยัง
  late final String _initial;

  bool get _isNew => widget.item == null;

  @override
  void initState() {
    super.initState();
    _initial = _snapshot();
    UnsavedGuard.register(_confirmLeave);
  }

  @override
  void dispose() {
    UnsavedGuard.unregister(_confirmLeave);
    _title.dispose();
    _message.dispose();
    _sequence.dispose();
    super.dispose();
  }

  String _snapshot() => [
    _title.text,
    _message.text,
    _sequence.text,
    toIsoDate(_start) ?? '',
    toIsoDate(_stop) ?? '',
    _active,
  ].join('\u0001');

  bool get _dirty => _snapshot() != _initial;

  /// ออกจากหน้าจอนี้ได้ไหม: มีการแก้ไขค้างให้ถามก่อน เลือกบันทึกแล้วบันทึกไม่ผ่าน = ยังออกไม่ได้
  Future<bool> _confirmLeave() async {
    if (_saving) return false;
    if (!_dirty) return true;
    final choice = await askUnsaved(context);
    if (!mounted) return false;
    return switch (choice) {
      UnsavedChoice.stay => false,
      UnsavedChoice.discard => true,
      UnsavedChoice.save => await _submit(notify: false),
    };
  }

  /// กดปิด (X) / ยกเลิก
  Future<void> _close() async {
    if (await _confirmLeave() && mounted) widget.onCancel();
  }

  /// บันทึก คืน true เมื่อสำเร็จ — [notify] = แจ้งหน้าจอแม่ให้กลับไปหน้ารายการ
  Future<bool> _submit({bool notify = true}) async {
    if (_saving) return false;
    final valid = _formKey.currentState!.validate();
    final dateError =
        _start != null && _stop != null && _stop!.isBefore(_start!)
        ? _dateOrderProblem
        : null;
    if (!valid || dateError != null) {
      setState(() {
        _dateError = dateError;
        _error = null;
      });
      return false;
    }
    setState(() {
      _saving = true;
      _error = null;
      _dateError = null;
    });
    final body = Announcement(
      title: _title.text.trim(),
      message: _message.text.trim(),
      startDate: _start,
      stopDate: _stop,
      sequence: int.parse(_sequence.text.trim()),
      status: _active ? Announcement.statusActive : Announcement.statusInactive,
    ).toBody();
    try {
      final message = await widget.api.saveAnnouncement(widget.item?.id, body);
      if (!mounted) return true;
      showAppMessage(context, message);
      if (notify) {
        widget.onSaved();
      } else {
        setState(() => _saving = false);
      }
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
      return false;
    }
  }

  Future<void> _pick(bool start) async {
    final picked = await showThaiDatePicker(
      context,
      // ยังไม่เคยเลือก: เปิดปฏิทินที่เดือนของอีกช่อง จะได้ไม่ต้องเลื่อนหาไกล
      initial: start ? _start ?? _stop : _stop ?? _start,
      title: start ? 'เลือกวันที่เริ่มประกาศ' : 'เลือกวันที่สิ้นสุด',
    );
    if (picked == null || !mounted) return;
    setState(() {
      start ? _start = picked : _stop = picked;
      _dateError = null;
    });
  }

  /// ช่องวันที่: กดแล้วเปิดปฏิทินไทย พ.ศ. มีปุ่มล้างค่า (ว่าง = ไม่กำหนด)
  Widget _dateField({
    required bool start,
    required String label,
    required String emptyText,
  }) {
    final palette = context.appPalette;
    final value = start ? _start : _stop;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: _saving ? null : () => _pick(start),
      child: InputDecorator(
        isEmpty: false,
        decoration: appInput(
          context,
          label: label,
          icon: Icons.event_rounded,
          suffix: value == null
              ? null
              : IconButton(
                  tooltip: 'ล้าง$label',
                  icon: const Icon(Icons.close),
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          start ? _start = null : _stop = null;
                          _dateError = null;
                        }),
                ),
        ).copyWith(errorText: start ? null : _dateError, errorMaxLines: 2),
        child: Text(
          value == null ? emptyText : formatThaiDate(value),
          style: fieldText.copyWith(
            color: value == null ? palette.textSecondary : palette.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    const gap = SizedBox(height: 14);
    final startField = _dateField(
      start: true,
      label: 'วันที่เริ่มประกาศ',
      emptyText: 'ไม่กำหนด (แสดงทันที)',
    );
    final stopField = _dateField(
      start: false,
      label: 'วันที่สิ้นสุด',
      emptyText: 'ไม่กำหนด (ไม่หมดอายุ)',
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // หัวหน้าจอกว้างเท่าการ์ดฟอร์ม ปุ่มปิด (X) จึงอยู่มุมขวาบนของฟอร์มพอดี
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Row(
              children: [
                Icon(Icons.campaign_rounded, color: palette.primary, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isNew ? 'เพิ่มประกาศ' : 'แก้ไขประกาศ',
                    style: palette.heading(24),
                  ),
                ),
                IconButton(
                  tooltip: 'ปิด',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: _saving ? null : _close,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ประกาศที่ใช้งานและอยู่ในช่วงวันที่ จะแสดงบนหน้าแรกให้ทุกคนเห็นโดยไม่ต้องเข้าสู่ระบบ',
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 15,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Material(
              color: palette.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: palette.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null)
                        ErrorBox(
                          message: _error!,
                          onClose: () => setState(() => _error = null),
                        ),
                      TextFormField(
                        controller: _title,
                        enabled: !_saving,
                        style: fieldText,
                        inputFormatters: [
                          _LengthLimit(AnnouncementFormScreen.titleMax),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration:
                            appInput(
                              context,
                              label: 'หัวเรื่อง',
                              hint: 'เช่น กำหนดส่งเอกสารลดหย่อนภาษีประจำปี',
                              icon: Icons.title_rounded,
                            ).copyWith(
                              counterText:
                                  '${_title.text.length}/${AnnouncementFormScreen.titleMax}',
                            ),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'กรุณากรอกหัวเรื่อง'
                            : null,
                      ),
                      gap,
                      TextFormField(
                        controller: _message,
                        enabled: !_saving,
                        style: fieldText,
                        minLines: 5,
                        maxLines: 12,
                        inputFormatters: [
                          _LengthLimit(AnnouncementFormScreen.messageMax),
                        ],
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.multiline,
                        decoration:
                            appInput(
                              context,
                              label: 'เนื้อความ',
                              hint:
                                  'รายละเอียดที่ต้องการประกาศ ขึ้นบรรทัดใหม่ได้ '
                                  'ลิงก์ที่ขึ้นต้นด้วย http:// หรือ https:// จะกดได้บนหน้าแรก',
                            ).copyWith(
                              alignLabelWithHint: true,
                              hintMaxLines: 3,
                              counterText:
                                  '${_message.text.length}/${AnnouncementFormScreen.messageMax}',
                            ),
                      ),
                      gap,
                      LayoutBuilder(
                        builder: (context, box) => box.maxWidth >= 460
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: startField),
                                  const SizedBox(width: 14),
                                  Expanded(child: stopField),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [startField, gap, stopField],
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'เว้นวันที่เริ่มว่าง = แสดงทันที  ·  เว้นวันที่สิ้นสุดว่าง = แสดงต่อไปจนกว่าจะปิดหรือลบประกาศ',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 13.5,
                          color: palette.textSecondary,
                        ),
                      ),
                      gap,
                      TextFormField(
                        controller: _sequence,
                        enabled: !_saving,
                        style: fieldText,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: appInput(
                          context,
                          label: 'ลำดับการแสดง',
                          hint: 'เลขน้อยแสดงก่อน',
                          icon: Icons.format_list_numbered_rounded,
                        ),
                        validator: (v) => int.tryParse((v ?? '').trim()) == null
                            ? 'กรุณากรอกลำดับเป็นจำนวนเต็มตั้งแต่ 0 ขึ้นไป'
                            : null,
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _active,
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _active = v),
                        title: Text(
                          _active ? 'สถานะ: ใช้งาน' : 'สถานะ: ไม่ใช้งาน',
                          style: const TextStyle(fontFamily: AppTheme.bodyFont),
                        ),
                        subtitle: const Text(
                          'ปิดแล้วประกาศจะไม่แสดงบนหน้าแรก แม้ยังอยู่ในช่วงวันที่',
                          style: TextStyle(
                            fontFamily: AppTheme.bodyFont,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      DialogButtons(
                        label: 'บันทึก',
                        icon: Icons.save_rounded,
                        loading: _saving,
                        onSubmit: _submit,
                        onCancel: _close,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// จำกัดความยาวแบบเดียวกับที่ backend นับ (String.length ของ Java = หน่วย UTF-16)
/// ตัวจำกัดของ Flutter (maxLength) นับเป็น "ตัวอักษรที่เห็น" สระ/วรรณยุกต์ไทยที่ซ้อนบนพยัญชนะไม่ถูกนับ
/// ข้อความไทยที่ตัวนับบอกว่าไม่เกินจึงอาจยาวเกินที่ backend รับ
class _LengthLimit extends TextInputFormatter {
  final int max;

  const _LengthLimit(this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length <= max) return newValue;
    // พิมพ์เพิ่มทีละตัวจนเกิน = ไม่รับ, วางข้อความยาวเกิน = ตัดส่วนเกินทิ้ง
    if (oldValue.text.length == max) return oldValue;
    var cut = max;
    // ไม่ตัดกลางคู่ surrogate (เช่น อีโมจิ)
    final last = newValue.text.codeUnitAt(cut - 1);
    if (last >= 0xD800 && last <= 0xDBFF) cut--;
    return TextEditingValue(
      text: newValue.text.substring(0, cut),
      selection: TextSelection.collapsed(offset: cut),
    );
  }
}
