import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../utils/file_saver.dart';
import '../widgets/file_widgets.dart';
import '../widgets/form_helpers.dart';
import 'user_form_screen.dart' show DivCache;

/// หน้าดาวน์โหลดไฟล์
/// ผู้ใช้ทั่วไป: เห็นเฉพาะไฟล์ของหน่วยงานตัวเอง
/// ADMIN/UPLOAD: เริ่มที่ "ทุกหน่วยงาน" แล้วเลือกดูทีละหน่วยงานได้ ไว้ตรวจและช่วยแก้ปัญหาให้ผู้ใช้
/// บนสุดมีปุ่มดาวน์โหลดรวม ได้ไฟล์ <รหัสหน่วยงาน>.zip = ไฟล์ของหน่วยงาน + ไฟล์ประกอบของเดือนที่เลือก
class DownloadScreen extends StatefulWidget {
  final AuthProvider auth;

  const DownloadScreen({super.key, required this.auth});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  int _year = currentBuddhistYear();
  int _month = DateTime.now().month;

  /// ตัวเลือก "ทุกหน่วยงาน" ในช่องเลือกหน่วยงาน (รหัสว่าง)
  static const Map<String, String> _allOption = {
    'div': '',
    'divname': 'ทุกหน่วยงาน',
  };
  static const String _allLabel = 'ทุกหน่วยงาน';

  /// หน่วยงานที่กำลังดู — ผู้ใช้ทั่วไปคือหน่วยงานตัวเองเสมอ
  /// ADMIN/UPLOAD: null = ทุกหน่วยงาน (ค่าเริ่มต้น)
  late String? _div = widget.auth.canSeeAllDivs ? null : widget.auth.div;

  final _divText = TextEditingController();
  final _divFocus = FocusNode();
  List<Map<String, String>> _divs = const [];

  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  /// ชื่อไฟล์ที่กำลังดาวน์โหลด ('zip' = กำลังทำไฟล์รวม)
  String? _busy;

  bool get _allDivs => widget.auth.canSeeAllDivs;

  /// กำลังดูทุกหน่วยงานพร้อมกัน
  bool get _viewAll => _allDivs && _div == null;

  static String _label(Map<String, String> d) =>
      d['div']!.isEmpty ? _allLabel : DivCache.label(d);

  @override
  void initState() {
    super.initState();
    if (_allDivs) {
      _divText.text = _allLabel;
      _loadDivs();
    }
    _load();
  }

  @override
  void dispose() {
    _divText.dispose();
    _divFocus.dispose();
    super.dispose();
  }

  Future<void> _loadDivs() async {
    try {
      final divs = await DivCache.load(widget.auth.api);
      if (!mounted) return;
      setState(() => _divs = [_allOption, ...divs]);
    } catch (e) {
      if (mounted) showAppMessage(context, e.toString(), error: true);
    }
  }

  /// แนบรหัสหน่วยงาน/ทุกหน่วยงานเฉพาะบทบาทที่ดูหน่วยงานอื่นได้ ผู้ใช้ทั่วไป backend ใช้หน่วยงานของบัญชีเอง
  Map<String, dynamic> get _query => {
    'year': _year,
    'month': _month,
    if (_viewAll) 'all': true else if (_allDivs) 'div': _div,
  };

  Future<void> _load() async {
    if (_div == null && !_allDivs) {
      // ผู้ใช้ทั่วไปที่บัญชีไม่มีหน่วยงาน: ไม่มีอะไรให้ดู
      setState(() {
        _data = null;
        _error = 'บัญชีนี้ยังไม่ได้กำหนดหน่วยงาน กรุณาติดต่อผู้ดูแลระบบ';
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.auth.api.downloadFiles(
        _year,
        _month,
        div: _allDivs ? _div : null,
        all: _viewAll,
      );
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _data = null;
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _download(
    String saveAs,
    String path,
    Map<String, dynamic> query, {
    String? busyKey,
  }) async {
    if (_busy != null) return;
    setState(() => _busy = busyKey ?? saveAs);
    try {
      final bytes = await widget.auth.api.fetchFile(path, query);
      FileSaver.save(saveAs, bytes);
      if (mounted) showAppMessage(context, 'ดาวน์โหลด $saveAs แล้ว');
    } catch (e) {
      if (mounted) showAppMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// ช่องเลือกหน่วยงานแบบ autocomplete (เฉพาะ ADMIN/UPLOAD)
  Widget _divField() {
    final palette = context.appPalette;
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: RawAutocomplete<Map<String, String>>(
        textEditingController: _divText,
        focusNode: _divFocus,
        displayStringForOption: _label,
        optionsBuilder: (value) {
          final q = norm(value.text);
          // ข้อความตรงกับหน่วยงานที่เลือกอยู่ = เพิ่งเลือกเสร็จ แสดงทั้งรายการให้เปลี่ยนได้
          final current = _div == null ? _allLabel : DivCache.nameOf(_div);
          if (q.isEmpty || value.text == current) return _divs;
          return _divs.where((d) => norm(_label(d)).contains(q));
        },
        onSelected: (d) {
          _div = d['div']!.isEmpty ? null : d['div'];
          _divFocus.unfocus();
          _load();
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
            TextField(
              key: const ValueKey('download-div'),
              controller: controller,
              focusNode: focusNode,
              style: fieldText,
              onSubmitted: (_) => onSubmitted(),
              decoration:
                  appInput(
                    context,
                    label: 'หน่วยงานที่ต้องการดู',
                    hint: 'พิมพ์รหัสหรือชื่อหน่วยงาน แล้วเลือกจากรายการ (หรือเลือก ทุกหน่วยงาน)',
                    icon: Icons.apartment_rounded,
                  ).copyWith(
                    fillColor: palette.surface,
                    helperText:
                        'สิทธิ์ผู้ดูแลระบบ/ผู้อัปโหลด: ดูไฟล์ได้ทุกหน่วยงาน',
                    helperStyle: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 13,
                      color: palette.textSecondary,
                    ),
                  ),
            ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            color: palette.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 520),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, i) {
                  final d = options.elementAt(i);
                  final highlighted =
                      AutocompleteHighlightedOption.of(context) == i;
                  return InkWell(
                    onTap: () => onSelected(d),
                    child: Container(
                      color: highlighted ? palette.primaryLight : null,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Text(
                        _label(d),
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 15,
                          fontWeight: d['div']!.isEmpty
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final data = _data;
    final payroll = [
      for (final f in (data?['payroll'] as List? ?? const []))
        Map<String, dynamic>.from(f),
    ];
    final common = [
      for (final f in (data?['common'] as List? ?? const []))
        Map<String, dynamic>.from(f),
    ];
    final zipName = (data?['zipName'] ?? '${_div ?? ''}.zip').toString();
    final hasFiles = payroll.isNotEmpty || common.isNotEmpty;
    final period = '${thaiMonths[_month - 1]} $_year';
    // ชื่อหน่วยงานที่กำลังดู: จากผลล่าสุดของ backend ถ้ายังไม่มีใช้ของบัญชีผู้ใช้
    final divLabel = _viewAll
        ? (data == null
              ? _allLabel
              : '$_allLabel (มีไฟล์ ${data['divCount'] ?? 0} หน่วยงาน)')
        : data != null
        ? '${data['div']} ${data['divName'] ?? ''}'.trim()
        : (_allDivs ? DivCache.nameOf(_div) : widget.auth.divLabel);
    final own = _div != null && _div == widget.auth.div;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Icon(Icons.download_rounded, color: palette.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(child: Text('ดาวน์โหลดไฟล์', style: palette.heading(24))),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'หน่วยงาน ${divLabel ?? '-'}',
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 16,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // ปุ่มดาวน์โหลดรวมอยู่บนสุดของหน้า ให้เห็นชัด
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: palette.heroGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ดาวน์โหลดรวมทุกไฟล์ของเดือน $period',
                    style: AppTheme.heading(18, color: Colors.white),
                  ),
                  const Text(
                    'ไฟล์รายละเอียดการจ่ายเงิน รวมกับไฟล์ประกอบ ในไฟล์เดียว',
                    style: TextStyle(
                      fontFamily: AppTheme.bodyFont,
                      fontSize: 14.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: palette.primaryDark,
                  disabledBackgroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: hasFiles && _busy == null
                    ? () => _download(
                        zipName,
                        '/api/download/zip',
                        _query,
                        busyKey: 'zip',
                      )
                    : null,
                icon: _busy == 'zip'
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_zip_rounded),
                label: Text(
                  'ดาวน์โหลดรวม ($zipName)',
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_allDivs) ...[_divField(), const SizedBox(height: 14)],
        PeriodPicker(
          year: _year,
          month: _month,
          enabled: !_loading,
          onChanged: (y, m) {
            _year = y;
            _month = m;
            _load();
          },
        ),
        const SizedBox(height: 18),
        if (_error != null) ErrorBox(message: _error!),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error == null) ...[
          SectionCard(
            icon: Icons.receipt_long_rounded,
            title: 'รายละเอียดการจ่ายเงินประจำเดือน',
            subtitle: _viewAll
                ? 'ไฟล์ของทุกหน่วยงาน เดือน $period (${payroll.length} ไฟล์)'
                : own || !_allDivs
                ? 'ไฟล์ของหน่วยงานคุณ เดือน $period'
                : 'ไฟล์ของหน่วยงาน $divLabel เดือน $period',
            child: FileTable(
              busyName: _busy,
              emptyText: _viewAll
                  ? 'ยังไม่มีไฟล์ที่เผยแพร่ในเดือน $period'
                  : 'ยังไม่มีไฟล์ของหน่วยงานในเดือน $period',
              rows: [
                for (final f in payroll)
                  FileRow(
                    name: f['name'] as String,
                    size: f['size'] as num?,
                    // ดูทุกหน่วยงาน: บอกด้วยว่าไฟล์นี้ของหน่วยงานไหน และดาวน์โหลดด้วยรหัสของแถวนั้น
                    note: _viewAll
                        ? '${f['div']} ${f['divName'] ?? ''}  ·  ${f['typeName']}'
                        : f['typeName'] as String?,
                    onDownload: () => _download(
                      f['name'] as String,
                      '/api/download/payroll',
                      {
                        'year': _year,
                        'month': _month,
                        'type': f['type'],
                        if (_viewAll)
                          'div': f['div']
                        else if (_allDivs)
                          'div': _div,
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionCard(
            icon: Icons.attach_file_rounded,
            title: 'ไฟล์ประกอบ',
            subtitle:
                'ไฟล์ประกอบการรายงานของเดือน $period (ทุกหน่วยงานเห็นเหมือนกัน)',
            child: FileTable(
              busyName: _busy,
              emptyText: 'ยังไม่มีไฟล์ประกอบในเดือน $period',
              rows: [
                for (final f in common)
                  FileRow(
                    name: f['name'] as String,
                    size: f['size'] as num?,
                    onDownload: () => _download(
                      f['name'] as String,
                      '/api/download/common',
                      {'year': _year, 'month': _month, 'name': f['name']},
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
