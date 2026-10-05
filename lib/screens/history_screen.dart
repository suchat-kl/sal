import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/api_service.dart';
import '../widgets/app_pagination.dart';
import '../widgets/file_widgets.dart';
import '../widgets/form_helpers.dart';
import '../widgets/simple_table.dart';

/// ประวัติการใช้งาน (ADMIN): ใครดาวน์โหลด/อัปโหลด/เผยแพร่/ลบอะไร เมื่อไร ใหม่สุดก่อน
class HistoryScreen extends StatefulWidget {
  final ApiService api;

  const HistoryScreen({super.key, required this.api});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  /// ชนิดประวัติ → ชื่อแท็บ (รหัสตรงกับ /api/admin/history/{kind})
  static const Map<String, String> _kinds = {
    'downloads': 'การดาวน์โหลด',
    'payroll': 'อัปโหลดรายละเอียดการจ่ายเงิน',
    'common': 'ไฟล์ประกอบ',
  };

  static const Map<String, (String, Color)> _status = {
    'PENDING': ('รอเผยแพร่', ActionColors.warning),
    'PUBLISHED': ('เผยแพร่อยู่', ActionColors.success),
    'REPLACED': ('ถูกแทนด้วยชุดใหม่', Color(0xFF64748B)),
    'CANCELLED': ('ยกเลิก', ActionColors.danger),
  };

  static const Map<String, (String, Color)> _actions = {
    'UPLOAD': ('อัปโหลด', ActionColors.success),
    'REPLACE': ('แทนที่ไฟล์เดิม', ActionColors.warning),
    'DELETE': ('ลบ', ActionColors.danger),
  };

  String _kind = 'downloads';
  final _keyword = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _items = [];
  int _page = 0;
  int _size = AppPagination.defaultSize;
  int _total = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _keyword.dispose();
    super.dispose();
  }

  Future<void> _load({int? page}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (page != null) _page = page;
    });
    final kind = _kind;
    try {
      final res = await widget.api.history(
        kind,
        keyword: _keyword.text,
        page: _page,
        size: _size,
      );
      // เปลี่ยนแท็บระหว่างรอ: ผลของแท็บเก่าไม่ต้องแสดง
      if (!mounted || kind != _kind) return;
      setState(() {
        _items = [
          for (final i in res['items'] as List) Map<String, dynamic>.from(i),
        ];
        _total = (res['totalItems'] ?? 0) as int;
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

  String _period(Map<String, dynamic> i) {
    final m = i['month'];
    return m is int && m >= 1 && m <= 12
        ? '${thaiMonths[m - 1]} ${i['year']}'
        : '-';
  }

  Widget _table() {
    Widget c(String t, {bool bold = false}) =>
        SimpleTable.cell(context, t, bold: bold);
    switch (_kind) {
      case 'payroll':
        return SimpleTable(
          emptyText: 'ยังไม่มีประวัติการอัปโหลด',
          headers: const [
            'อัปโหลดเมื่อ',
            'ไฟล์',
            'เดือน',
            'ผลการตัด',
            'สถานะ',
            'ผู้อัปโหลด / ผู้เผยแพร่',
          ],
          flex: const [4, 3, 3, 3, 3, 4],
          rows: [
            for (final i in _items)
              [
                c(thaiDateTime(i['uploadedAt'])),
                c('${i['fileName']}', bold: true),
                c(_period(i)),
                c('${i['totalPages']} หน้า'),
                SimpleTable.chip(
                  (_status[i['status']] ?? ('${i['status']}', Colors.grey)).$1,
                  (_status[i['status']] ?? ('', Colors.grey)).$2,
                ),
                c(
                  '${i['uploadedBy']}'
                  '${i['publishedBy'] == null ? '' : ' / ${i['publishedBy']} (${thaiDateTime(i['publishedAt'])})'}',
                ),
              ],
          ],
        );
      case 'common':
        return SimpleTable(
          emptyText: 'ยังไม่มีประวัติไฟล์ประกอบ',
          headers: const ['เมื่อ', 'ผู้ใช้', 'การกระทำ', 'ไฟล์', 'เดือน'],
          flex: const [4, 2, 3, 5, 3],
          rows: [
            for (final i in _items)
              [
                c(thaiDateTime(i['at'])),
                c('${i['username']}', bold: true),
                SimpleTable.chip(
                  (_actions[i['action']] ?? ('${i['action']}', Colors.grey)).$1,
                  (_actions[i['action']] ?? ('', Colors.grey)).$2,
                ),
                c('${i['file']}'),
                c(_period(i)),
              ],
          ],
        );
      default:
        return SimpleTable(
          emptyText: 'ยังไม่มีประวัติการดาวน์โหลด',
          headers: const [
            'เมื่อ',
            'ผู้ใช้',
            'ไฟล์ของหน่วยงาน',
            'ไฟล์',
            'เดือน',
          ],
          flex: const [4, 2, 3, 5, 3],
          rows: [
            for (final i in _items)
              [
                c(thaiDateTime(i['at'])),
                c('${i['username']}', bold: true),
                c('${i['div'] ?? '-'}'),
                c('${i['file']}'),
                c(_period(i)),
              ],
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Icon(Icons.history_rounded, color: palette.primary, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text('ประวัติการใช้งาน', style: palette.heading(24)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ใครดาวน์โหลด อัปโหลด เผยแพร่ หรือลบไฟล์ เมื่อไร (ใหม่สุดก่อน)',
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 15,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in _kinds.entries)
              ChoiceChip(
                label: Text(
                  k.value,
                  style: const TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 15,
                  ),
                ),
                selected: _kind == k.key,
                onSelected: (_) {
                  if (_kind == k.key) return;
                  _kind = k.key;
                  _items = [];
                  _load(page: 0);
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: TextField(
            controller: _keyword,
            style: fieldText,
            onChanged: (_) {
              _debounce?.cancel();
              _debounce = Timer(
                const Duration(milliseconds: 400),
                () => _load(page: 0),
              );
            },
            decoration: appInput(
              context,
              label: 'ค้นหา',
              hint: 'ชื่อผู้ใช้ รหัสหน่วยงาน หรือชื่อไฟล์',
              icon: Icons.search,
            ).copyWith(fillColor: palette.surface),
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null) ErrorBox(message: _error!),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          Material(
            color: palette.surface,
            borderRadius: BorderRadius.circular(12),
            child: _table(),
          ),
          const SizedBox(height: 12),
          AppPagination(
            page: _page,
            pageSize: _size,
            totalItems: _total,
            onPage: (p) => _load(page: p),
            onPageSize: (s) {
              _size = s;
              _load(page: 0);
            },
          ),
        ],
      ],
    );
  }
}
