import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/api_service.dart';
import '../utils/file_pick.dart';
import '../utils/file_saver.dart';
import '../widgets/file_widgets.dart';
import '../widgets/form_helpers.dart';

/// หน้าอัปโหลดไฟล์ (UPLOAD/ADMIN) มีสองส่วนใต้ปี/เดือนเดียวกัน
/// 1. รายละเอียดการจ่ายเงินประจำเดือน: PDF รวมทุกหน่วยงาน → ระบบตัดเป็นไฟล์รายหน่วยงาน → เผยแพร่ → เลือกลบ PDF รวม
/// 2. ไฟล์ประกอบการรายงาน: ทุกหน่วยงานดาวน์โหลดได้
class UploadScreen extends StatefulWidget {
  final ApiService api;

  const UploadScreen({super.key, required this.api});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  /// ประเภทบุคคล รหัสใช้ในชื่อไฟล์ (ต้องตรงกับ StorageService.TYPES ฝั่ง backend)
  static const Map<String, String> _types = {
    'G1': 'ข้าราชการส่วนกลาง',
    'G2': 'ข้าราชการส่วนภูมิภาค',
    'E': 'ลูกจ้างประจำ',
  };

  static const List<String> _commonExt = [
    'txt',
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx',
    'xls',
    'xlsx',
  ];

  static const int _commonMaxBytes = 20 * 1024 * 1024;

  int _year = currentBuddhistYear();
  int _month = DateTime.now().month;
  String _type = 'G1';

  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _common = [];
  bool _loading = true;
  String? _error;

  /// ข้อความงานที่กำลังทำ (ไม่ว่าง = ปุ่มทั้งหน้ากดไม่ได้)
  String? _working;
  double? _progress;
  String? _payrollError;
  String? _commonBusy;

  ApiService get _api => widget.api;

  String get _expectedName =>
      '$_year${_month.toString().padLeft(2, '0')}$_type.pdf';

  String get _period => '${thaiMonths[_month - 1]} $_year';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.payrollUploads(_year, _month),
        _api.commonFiles(_year, _month),
      ]);
      if (!mounted) return;
      setState(() {
        _batches = results[0];
        _common = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// ทำงานหนึ่งอย่างโดยล็อกหน้าจอไว้ คืน true เมื่อสำเร็จ
  Future<bool> _run(
    String label,
    Future<void> Function() job, {
    String? done,
  }) async {
    if (_working != null) return false;
    setState(() {
      _working = label;
      _progress = null;
    });
    try {
      await job();
      if (mounted && done != null) showAppMessage(context, done);
      return true;
    } catch (e) {
      if (mounted) showAppMessage(context, e.toString(), error: true);
      return false;
    } finally {
      if (mounted) {
        setState(() => _working = null);
        await _load();
      }
    }
  }

  // ---------------- ส่วนที่ 1: รายละเอียดการจ่ายเงินประจำเดือน ----------------

  Future<void> _uploadPayroll() async {
    final file = await FilePick.pick(const ['pdf']);
    if (file == null || !mounted) return;
    // ตรวจชื่อไฟล์ก่อนส่ง จะได้ไม่ต้องรออัปโหลดไฟล์ใหญ่แล้วค่อยรู้ว่าเลือกผิด
    if (file.name.toLowerCase() != _expectedName.toLowerCase()) {
      setState(
        () => _payrollError =
            'ชื่อไฟล์ต้องเป็น $_expectedName ตามปี เดือน และประเภทที่เลือก (ไฟล์ที่เลือกชื่อ ${file.name})',
      );
      return;
    }
    setState(() => _payrollError = null);
    if (_working != null) return;
    setState(() {
      _working = 'กำลังอัปโหลดและตัดไฟล์ ${file.name}';
      _progress = 0;
    });
    try {
      final result = await _api.uploadPayroll(
        name: file.name,
        bytes: file.bytes,
        year: _year,
        month: _month,
        type: _type,
        onProgress: (sent, total) {
          if (!mounted || total <= 0) return;
          // ส่งครบแล้ว backend ยังต้องตัดไฟล์อีกครู่ จึงเปลี่ยนเป็นวงหมุนไม่มีเปอร์เซ็นต์
          setState(() => _progress = sent >= total ? null : sent / total);
        },
      );
      if (!mounted) return;
      showAppMessage(
        context,
        'ตัดไฟล์สำเร็จ ${(result['units'] as List).length} หน่วยงาน ${result['totalPages']} หน้า — ตรวจแล้วกดเผยแพร่',
      );
    } catch (e) {
      if (mounted) setState(() => _payrollError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _working = null);
        await _load();
      }
    }
  }

  Future<void> _publish(Map<String, dynamic> batch) async {
    final typeName = _types[batch['type']] ?? batch['type'];
    final replacing = _batches.any(
      (b) => b['type'] == batch['type'] && b['status'] == 'PUBLISHED',
    );
    final ok = await confirmDialog(
      context,
      title: 'เผยแพร่ไฟล์',
      message:
          'เผยแพร่รายละเอียดการจ่ายเงิน $typeName เดือน $_period '
          '(${(batch['units'] as List).length} หน่วยงาน) ให้ผู้ใช้ดาวน์โหลด'
          '${replacing ? '\n\nชุดที่เผยแพร่อยู่ของประเภทนี้จะถูกแทนด้วยชุดใหม่' : ''}',
      confirmLabel: 'เผยแพร่',
    );
    if (!ok || !mounted) return;
    final id = batch['id'] as String;
    final published = await _run(
      'กำลังเผยแพร่',
      () => _api.publishPayroll(id),
      done: 'เผยแพร่แล้ว ผู้ใช้ดาวน์โหลดได้ทันที',
    );
    if (!published || !mounted) return;
    // หลังเผยแพร่ให้เลือกว่าจะลบ PDF รวมทุกหน่วยงานที่อัปโหลดหรือไม่
    final delete = await confirmDialog(
      context,
      title: 'ลบไฟล์ PDF รวมหรือไม่',
      message:
          'ไฟล์ ${batch['fileName']} (PDF รวมทุกหน่วยงานที่อัปโหลด) ไม่จำเป็นต้องใช้แล้ว '
          'ไฟล์ของแต่ละหน่วยงานที่เผยแพร่ไปไม่ได้รับผลกระทบ\n\n'
          'เก็บไว้ก็ได้ ผู้อัปโหลดดาวน์โหลดกลับหรือลบทีหลังได้จากหน้านี้',
      confirmLabel: 'ลบไฟล์ PDF รวม',
      cancelLabel: 'เก็บไว้',
      danger: true,
    );
    if (delete && mounted) {
      await _run(
        'กำลังลบ PDF รวม',
        () => _api.deletePayrollSource(id),
        done: 'ลบไฟล์ PDF รวมแล้ว',
      );
    }
  }

  Future<void> _cancel(Map<String, dynamic> batch) async {
    final ok = await confirmDialog(
      context,
      title: 'ยกเลิกชุดที่รอเผยแพร่',
      message:
          'ลบไฟล์ที่ตัดไว้และ PDF รวม ${batch['fileName']} ของชุดนี้ '
          'ชุดที่เผยแพร่อยู่แล้ว (ถ้ามี) ไม่ถูกแตะ',
      confirmLabel: 'ยกเลิกชุดนี้',
      cancelLabel: 'ไม่ยกเลิก',
      danger: true,
    );
    if (ok && mounted) {
      await _run(
        'กำลังยกเลิก',
        () => _api.cancelPayroll(batch['id'] as String),
        done: 'ยกเลิกชุดที่รอเผยแพร่แล้ว',
      );
    }
  }

  Future<void> _deleteSource(Map<String, dynamic> batch) async {
    final ok = await confirmDialog(
      context,
      title: 'ลบไฟล์ PDF รวม',
      message:
          'ลบ ${batch['fileName']} ออกจากระบบ ไฟล์ของแต่ละหน่วยงานที่เผยแพร่แล้วยังอยู่',
      confirmLabel: 'ลบไฟล์ PDF รวม',
      danger: true,
    );
    if (ok && mounted) {
      await _run(
        'กำลังลบ PDF รวม',
        () => _api.deletePayrollSource(batch['id'] as String),
        done: 'ลบไฟล์ PDF รวมแล้ว',
      );
    }
  }

  Future<void> _save(String name, String path, [Map<String, dynamic>? q]) =>
      _run('กำลังดาวน์โหลด $name', () async {
        FileSaver.save(name, await _api.fetchFile(path, q));
      });

  void _showUnits(Map<String, dynamic> batch) {
    final units = [
      for (final u in batch['units'] as List) Map<String, dynamic>.from(u),
    ];
    final id = batch['id'] as String;
    final prefix =
        '_${batch['year']}${(batch['month'] as int).toString().padLeft(2, '0')}${batch['type']}.pdf';
    showDialog<void>(
      context: context,
      builder: (context) => DialogShell(
        icon: Icons.content_cut_rounded,
        title: 'สรุปการตัดไฟล์ ${batch['fileName']}',
        subtitle:
            '${units.length} หน่วยงาน รวม ${batch['totalPages']} หน้า (เท่ากับไฟล์ต้นฉบับ)',
        maxWidth: 760,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FileTable(
              emptyText: 'ไม่มีหน่วยงาน',
              rows: [
                for (final u in units)
                  FileRow(
                    name: '${u['div']}  ${u['divname']}',
                    size: u['size'] as num?,
                    note:
                        'หน้า ${u['fromPage']}-${u['toPage']} (${u['pages']} หน้า)',
                    onDownload: () {
                      Navigator.of(context).pop();
                      _save(
                        '${u['div']}$prefix',
                        '/api/upload/payroll/$id/units/${u['div']}',
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ปิด'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ส่วนที่ 2: ไฟล์ประกอบการรายงาน ----------------

  /// อัปโหลดไฟล์ประกอบ เลือกได้หลายไฟล์พร้อมกัน
  /// ไฟล์ที่ไม่ผ่าน (ใหญ่เกิน/นามสกุลไม่รับ) ข้ามไปและแจ้งท้ายสุด ไฟล์ชื่อซ้ำรวมถามครั้งเดียวว่าจะแทนที่ไหม
  Future<void> _uploadCommon() async {
    final files = await FilePick.pickMany(_commonExt);
    if (files.isEmpty || !mounted || _working != null) return;

    final failed = <String>[]; // "ชื่อไฟล์: เหตุผล"
    final duplicates = <PickedFile>[];
    var done = 0;

    Future<void> send(PickedFile f, {required bool overwrite}) async {
      setState(
        () => _working =
            'กำลังอัปโหลด ${f.name} (${done + failed.length + 1}/${files.length})',
      );
      await _api.uploadCommon(
        name: f.name,
        bytes: f.bytes,
        year: _year,
        month: _month,
        overwrite: overwrite,
      );
      done++;
    }

    try {
      for (final f in files) {
        if (f.bytes.length > _commonMaxBytes) {
          failed.add('${f.name}: ขนาดเกิน 20 MB');
          continue;
        }
        try {
          await send(f, overwrite: false);
        } on ApiException catch (e) {
          if (e.statusCode == 409) {
            duplicates.add(f);
          } else {
            failed.add('${f.name}: ${e.message}');
          }
        }
        if (!mounted) return;
      }
      if (duplicates.isNotEmpty) {
        // ระหว่างรอคำตอบยังไม่ได้ทำงานอะไร ไม่ต้องแสดงแถบกำลังทำงาน
        setState(() => _working = null);
        final replace = await confirmDialog(
          context,
          title: duplicates.length == 1
              ? 'มีไฟล์ชื่อนี้อยู่แล้ว'
              : 'มีไฟล์ชื่อซ้ำ ${duplicates.length} ไฟล์',
          message:
              '${duplicates.map((f) => '• ${f.name}').join('\n')}\n\n'
              'มีอยู่แล้วในเดือน $_period ต้องการแทนที่ไฟล์เดิมด้วยไฟล์ใหม่หรือไม่',
          confirmLabel: duplicates.length == 1 ? 'แทนที่' : 'แทนที่ทั้งหมด',
          cancelLabel: 'ข้ามไฟล์ที่ซ้ำ',
          danger: true,
        );
        if (!mounted) return;
        if (replace) {
          for (final f in duplicates) {
            try {
              await send(f, overwrite: true);
            } on ApiException catch (e) {
              failed.add('${f.name}: ${e.message}');
            }
            if (!mounted) return;
          }
        }
      }
    } catch (e) {
      failed.add(e.toString());
    } finally {
      if (mounted) {
        setState(() => _working = null);
        await _load();
      }
    }
    if (!mounted) return;
    if (failed.isEmpty) {
      if (done > 0) {
        showAppMessage(
          context,
          done == 1 ? 'อัปโหลดแล้ว 1 ไฟล์' : 'อัปโหลดแล้ว $done ไฟล์',
        );
      }
    } else {
      // ไฟล์ที่ไม่ผ่านต้องเห็นชัดและค้างไว้ให้อ่าน ไม่ใช่ข้อความที่หายเอง
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'อัปโหลดได้ $done จาก ${files.length} ไฟล์',
            style: AppTheme.heading(19),
          ),
          content: Text(
            'ไฟล์ที่อัปโหลดไม่ได้\n${failed.map((f) => '• $f').join('\n')}',
            style: const TextStyle(fontFamily: AppTheme.bodyFont, fontSize: 15),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('รับทราบ'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _deleteCommon(String name) async {
    final ok = await confirmDialog(
      context,
      title: 'ลบไฟล์ประกอบ',
      message: 'ลบ $name ของเดือน $_period ผู้ใช้จะดาวน์โหลดไฟล์นี้ไม่ได้อีก',
      confirmLabel: 'ลบไฟล์',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _commonBusy = name);
    await _run(
      'กำลังลบ $name',
      () => _api.deleteCommon(_year, _month, name),
      done: 'ลบ $name แล้ว',
    );
    if (mounted) setState(() => _commonBusy = null);
  }

  // ---------------- หน้าจอ ----------------

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final busy = _working != null;
    final body = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 15,
      color: palette.textSecondary,
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Icon(Icons.upload_file_rounded, color: palette.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Text('อัปโหลดไฟล์', style: palette.heading(24))),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'เลือกปีและเดือนก่อน ทั้งสองส่วนด้านล่างใช้ปี/เดือนนี้',
          style: body,
        ),
        const SizedBox(height: 16),
        PeriodPicker(
          year: _year,
          month: _month,
          enabled: !busy && !_loading,
          onChanged: (y, m) {
            _year = y;
            _month = m;
            _payrollError = null;
            _load();
          },
        ),
        const SizedBox(height: 16),
        if (busy)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _progress == null
                      ? '$_working ...'
                      : '$_working ${(_progress! * 100).round()}%',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: palette.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: _progress),
              ],
            ),
          ),
        if (_error != null) ErrorBox(message: _error!),
        SectionCard(
          icon: Icons.receipt_long_rounded,
          title: 'รายละเอียดการจ่ายเงินประจำเดือน',
          subtitle: 'PDF รวมทุกหน่วยงาน ระบบตัดเป็นไฟล์รายหน่วยงานให้ แล้วรอกดเผยแพร่',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('ประเภทบุคคล', style: body),
              RadioGroup<String>(
                groupValue: _type,
                onChanged: (v) {
                  if (busy || v == null) return;
                  setState(() {
                    _type = v;
                    _payrollError = null;
                  });
                },
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final t in _types.entries)
                      IntrinsicWidth(
                        child: RadioListTile<String>(
                          value: t.key,
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${t.value} (${t.key})',
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 15.5,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  text: 'ชื่อไฟล์ต้องเป็น ',
                  children: [
                    TextSpan(
                      text: _expectedName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: palette.primaryDark,
                      ),
                    ),
                    const TextSpan(
                      text: '  และหัวรายงานในไฟล์ต้องเป็นเดือน/ปีเดียวกับที่เลือก',
                    ),
                  ],
                ),
                style: body,
              ),
              const SizedBox(height: 12),
              if (_payrollError != null)
                ErrorBox(
                  message: _payrollError!,
                  onClose: () => setState(() => _payrollError = null),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onPressed: busy || _loading ? null : _uploadPayroll,
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text(
                    'เลือกไฟล์ PDF และอัปโหลด',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'สถานะของเดือน $_period',
                style: body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_batches.isEmpty)
                Text('ยังไม่มีการอัปโหลดของเดือนนี้', style: body)
              else
                for (final b in _batches) _batchCard(b, busy),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          icon: Icons.attach_file_rounded,
          title: 'ไฟล์ประกอบการรายงาน',
          subtitle:
              'ไฟล์ของเดือน $_period ที่ทุกหน่วยงานดาวน์โหลดได้ (เห็นทันทีหลังอัปโหลด)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'เลือกได้หลายไฟล์พร้อมกัน  รับไฟล์ .${_commonExt.join(' .')}  ขนาดไม่เกิน 20 MB ต่อไฟล์',
                style: body,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  onPressed: busy || _loading ? null : _uploadCommon,
                  icon: const Icon(Icons.upload_rounded),
                  label: const Text(
                    'เลือกไฟล์ประกอบและอัปโหลด',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_loading)
                FileTable(
                  busyName: _commonBusy,
                  emptyText: 'ยังไม่มีไฟล์ประกอบในเดือน $_period',
                  rows: [
                    for (final f in _common)
                      FileRow(
                        name: f['name'] as String,
                        size: f['size'] as num?,
                        onDownload: busy
                            ? null
                            : () => _save(
                                f['name'] as String,
                                '/api/upload/common/file',
                                {
                                  'year': _year,
                                  'month': _month,
                                  'name': f['name'],
                                },
                              ),
                        onDelete: busy
                            ? null
                            : () => _deleteCommon(f['name'] as String),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// การ์ดของชุดอัปโหลดหนึ่งชุด: สถานะ ผลการตัด และปุ่มตามสถานะ
  Widget _batchCard(Map<String, dynamic> b, bool busy) {
    final palette = context.appPalette;
    final pending = b['status'] == 'PENDING';
    final color = pending ? ActionColors.warning : ActionColors.success;
    final sourceKept = b['sourceKept'] == true;
    final text = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 14.5,
      color: palette.textSecondary,
    );
    String when(dynamic v) {
      final d = DateTime.tryParse('${v ?? ''}');
      if (d == null) return '';
      String two(int n) => n.toString().padLeft(2, '0');
      return '${d.day} ${thaiMonths[d.month - 1]} ${d.year + 543} ${two(d.hour)}:${two(d.minute)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${_types[b['type']] ?? b['type']} (${b['type']})',
                style: palette.heading(16.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  pending ? 'รอเผยแพร่' : 'เผยแพร่แล้ว',
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${b['fileName']}  ·  ตัดได้ ${(b['units'] as List).length} หน่วยงาน รวม ${b['totalPages']} หน้า',
            style: text.copyWith(color: palette.textPrimary),
          ),
          Text(
            'อัปโหลดโดย ${b['uploadedBy']} เมื่อ ${when(b['uploadedAt'])}'
            '${pending ? '' : '  ·  เผยแพร่โดย ${b['publishedBy']} เมื่อ ${when(b['publishedAt'])}'}',
            style: text,
          ),
          Text(
            pending
                ? 'ผู้ใช้ยังไม่เห็นชุดนี้ จนกว่าจะกดเผยแพร่'
                : sourceKept
                ? 'PDF รวมยังเก็บอยู่ในระบบ'
                : 'PDF รวมถูกลบแล้ว',
            style: text,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : () => _showUnits(b),
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: const Text('ดูสรุปการตัดไฟล์'),
              ),
              if (pending) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ActionColors.success,
                  ),
                  onPressed: busy ? null : () => _publish(b),
                  icon: const Icon(Icons.campaign_rounded, size: 18),
                  label: const Text('เผยแพร่'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ActionColors.cancel,
                    side: const BorderSide(color: ActionColors.cancel),
                  ),
                  onPressed: busy ? null : () => _cancel(b),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('ยกเลิกชุดนี้'),
                ),
              ],
              if (sourceKept)
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () => _save(
                          b['fileName'] as String,
                          '/api/upload/payroll/${b['id']}/source',
                        ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('ดาวน์โหลด PDF รวม'),
                ),
              if (!pending && sourceKept)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ActionColors.danger,
                    side: const BorderSide(color: ActionColors.danger),
                  ),
                  onPressed: busy ? null : () => _deleteSource(b),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('ลบ PDF รวม'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
