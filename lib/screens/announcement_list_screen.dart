import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/announcement.dart';
import '../services/api_service.dart';
import '../widgets/app_pagination.dart';
import '../widgets/file_widgets.dart' show confirmDialog;
import '../widgets/form_helpers.dart';
import 'announcement_form_screen.dart';

/// จัดการประกาศ (ADMIN): ค้นด้วยหัวเรื่อง กรองสถานะ แบ่งหน้า เพิ่ม/แก้ไข/ลบ
/// ฟอร์มเพิ่ม/แก้ไขเปิดแทนรายการในพื้นที่เนื้อหา (ไม่ใช่ dialog)
class AnnouncementListScreen extends StatefulWidget {
  final ApiService api;

  const AnnouncementListScreen({super.key, required this.api});

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  /// ตัวกรองสถานะ: ค่า null = ทั้งหมด
  static const List<(String?, String)> _statusFilters = [
    (null, 'ทั้งหมด'),
    (Announcement.statusActive, 'ใช้งาน'),
    (Announcement.statusInactive, 'ไม่ใช้งาน'),
  ];

  final _keyword = TextEditingController();
  Timer? _debounce;
  List<Announcement> _items = [];
  String? _status;
  int _page = 0;
  int _size = AppPagination.defaultSize;
  int _totalItems = 0;
  bool _loading = true;
  String? _error;

  /// กำลังเปิดฟอร์มอยู่ไหม — [_editing] ว่าง = เพิ่มใหม่
  bool _formOpen = false;
  Announcement? _editing;

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
    try {
      var res = await widget.api.searchAnnouncements(
        title: _keyword.text,
        status: _status,
        page: _page,
        size: _size,
      );
      // ลบรายการสุดท้ายของหน้าท้ายสุด: หน้านี้ว่างแล้ว ถอยไปหน้าสุดท้ายที่ยังมีข้อมูล
      if (res.items.isEmpty && res.total > 0 && _page > 0) {
        _page = AppPagination.pageCount(res.total, _size) - 1;
        res = await widget.api.searchAnnouncements(
          title: _keyword.text,
          status: _status,
          page: _page,
          size: _size,
        );
      }
      if (!mounted) return;
      setState(() {
        _items = res.items;
        _totalItems = res.total;
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

  void _onKeywordChanged(String _) {
    setState(() {}); // ปุ่มล้างคำค้นโผล่/หายตามข้อความ
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(page: 0));
  }

  void _openForm(Announcement? item) => setState(() {
    _formOpen = true;
    _editing = item;
  });

  void _closeForm({bool reload = false}) {
    setState(() {
      _formOpen = false;
      _editing = null;
    });
    if (reload) _load();
  }

  Future<void> _delete(Announcement a) async {
    final ok = await confirmDialog(
      context,
      title: 'ลบประกาศ',
      message: 'ต้องการลบประกาศ "${a.title}" ใช่หรือไม่ ลบแล้วกู้คืนไม่ได้',
      confirmLabel: 'ลบประกาศ',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      final message = await widget.api.deleteAnnouncement(a.id!);
      if (!mounted) return;
      showAppMessage(context, message);
      _load();
    } catch (e) {
      if (!mounted) return;
      showAppMessage(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    if (_formOpen) {
      return AnnouncementFormScreen(
        key: ValueKey('announcement-${_editing?.id ?? 'new'}'),
        api: widget.api,
        item: _editing,
        onCancel: _closeForm,
        onSaved: () => _closeForm(reload: true),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_rounded, color: palette.primary, size: 30),
                const SizedBox(width: 12),
                Text('ประกาศ', style: palette.heading(24)),
              ],
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: palette.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'เพิ่มประกาศ',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'ประกาศที่ใช้งานและอยู่ในช่วงวันที่ จะแสดงบนหน้าแรกใต้ภาพหัว เรียงตามลำดับจากน้อยไปมาก',
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 15,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: TextField(
                controller: _keyword,
                style: fieldText,
                onChanged: _onKeywordChanged,
                decoration:
                    appInput(
                      context,
                      label: 'ค้นหา',
                      hint: 'หัวเรื่องประกาศ',
                      icon: Icons.search,
                    ).copyWith(
                      fillColor: palette.surface,
                      suffixIcon: _keyword.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'ล้างคำค้น',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _debounce?.cancel();
                                _keyword.clear();
                                _load(page: 0);
                              },
                            ),
                    ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'สถานะ',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 14,
                    color: palette.textSecondary,
                  ),
                ),
                for (final (value, label) in _statusFilters)
                  ChoiceChip(
                    label: Text(
                      label,
                      style: const TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 14,
                      ),
                    ),
                    selected: _status == value,
                    onSelected: (_) {
                      if (_status == value) return;
                      _debounce?.cancel();
                      _status = value;
                      _load(page: 0);
                    },
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_error != null) ErrorBox(message: _error!),
        Container(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'ไม่พบประกาศ',
                      style: TextStyle(
                        fontFamily: AppTheme.bodyFont,
                        fontSize: 16,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: palette.border),
                      _row(_items[i]),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 14),
        AppPagination(
          page: _page,
          pageSize: _size,
          totalItems: _totalItems,
          enabled: !_loading,
          onPage: (p) => _load(page: p),
          onPageSize: (s) {
            _size = s;
            _load(page: 0);
          },
        ),
      ],
    );
  }

  Widget _row(Announcement a) {
    final palette = context.appPalette;
    final period = a.periodLabel;
    Widget chip(String text, Color color, {IconData? icon}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontFamily: AppTheme.bodyFont,
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: palette.primaryLight,
            child: Icon(Icons.campaign_rounded, color: palette.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.title,
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ช่วงวันที่: ${period.isEmpty ? 'ไม่กำหนด' : period}   ·   ลำดับ ${a.sequence}',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 13.5,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    a.isActive
                        ? chip('ใช้งาน', palette.primaryDark)
                        : chip('ไม่ใช้งาน', ActionColors.danger),
                    if (a.isShowing())
                      chip(
                        'กำลังแสดง',
                        ActionColors.success,
                        icon: Icons.visibility_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'แก้ไข',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _openForm(a),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'ลบ',
            color: ActionColors.danger,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: a.id == null ? null : () => _delete(a),
          ),
        ],
      ),
    );
  }
}
