import 'dart:async';

import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/form_helpers.dart';
import '../widgets/reset_password_dialog.dart';
import 'user_form_screen.dart';

/// หน้าที่ของรายการผู้ใช้: เลือกผู้ใช้เพื่อแก้ไข หรือเพื่อกำหนดรหัสผ่านใหม่
enum UserListMode { edit, resetPassword }

/// รายการผู้ใช้งาน (ADMIN) ค้นหาได้ แบ่งหน้า กดปุ่มท้ายแถวเพื่อทำงานตาม [mode]
class UserListScreen extends StatefulWidget {
  final ApiService api;
  final UserListMode mode;

  const UserListScreen({super.key, required this.api, required this.mode});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  static const List<int> _sizes = [5, 10, 15, 20];

  final _keyword = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _users = [];
  int _page = 0;
  int _size = 10;
  int _totalPages = 0;
  int _totalItems = 0;
  bool _loading = true;
  String? _error;

  /// ผู้ใช้ที่กำลังแก้ไข — ไม่ว่าง = แสดงหน้าแก้ไขแทนรายการ
  Map<String, dynamic>? _editing;

  bool get _edit => widget.mode == UserListMode.edit;

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
      // โหลดชื่อหน่วยงานไว้แสดงในตาราง พลาดก็ยังแสดงรหัสได้
      await DivCache.load(widget.api)
          .catchError((_) => <Map<String, String>>[]);
      final res = await widget.api.searchUsers(
        keyword: _keyword.text,
        page: _page,
        size: _size,
      );
      if (!mounted) return;
      setState(() {
        _users = [
          for (final u in res['users'] as List) Map<String, dynamic>.from(u),
        ];
        _totalPages = (res['totalPages'] ?? 0) as int;
        _totalItems = (res['totalItems'] ?? 0) as int;
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
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(page: 0));
  }

  Future<void> _act(Map<String, dynamic> user) async {
    if (_edit) {
      setState(() => _editing = user);
      return;
    }
    final ok =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ResetPasswordDialog(api: widget.api, user: user),
        ) ==
        true;
    if (ok && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final editing = _editing;
    if (editing != null) {
      return UserFormScreen(
        key: ValueKey(editing['id']),
        api: widget.api,
        user: editing,
        onCancel: () => setState(() => _editing = null),
        onSaved: () {
          setState(() => _editing = null);
          _load();
        },
      );
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Icon(
              _edit ? Icons.manage_accounts : Icons.lock_reset_rounded,
              color: palette.primary,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _edit ? 'แก้ไขผู้ใช้งาน' : 'กำหนดรหัสผ่านใหม่',
                style: palette.heading(24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _edit
              ? 'ค้นหาผู้ใช้แล้วกดปุ่มแก้ไขท้ายแถว'
              : 'ค้นหาผู้ใช้แล้วกดปุ่มกำหนดรหัสผ่านท้ายแถว',
          style: TextStyle(
            fontFamily: AppTheme.bodyFont,
            fontSize: 15,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 18),
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
                  hint: 'ชื่อผู้ใช้ ชื่อ-นามสกุล หรือรหัสหน่วยงาน',
                  icon: Icons.search,
                ).copyWith(
                  fillColor: palette.surface,
                  suffixIcon: _keyword.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'ล้างคำค้น',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _keyword.clear();
                            _load(page: 0);
                          },
                        ),
                ),
          ),
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
              : _users.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      'ไม่พบผู้ใช้งาน',
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
                    for (var i = 0; i < _users.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: palette.border),
                      _row(_users[i]),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _pagination(),
      ],
    );
  }

  Widget _row(Map<String, dynamic> u) {
    final palette = context.appPalette;
    final active = u['active'] != false;
    final locked = u['locked'] == true;
    final roles = [for (final r in u['roles'] as List? ?? const []) '$r'];
    Widget chip(String text, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.bodyFont,
          fontSize: 12.5,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: palette.primaryLight,
            child: Icon(Icons.person, color: palette.primaryDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${u['username']}  ·  ${u['fullName'] ?? ''}',
                  style: TextStyle(
                    fontFamily: AppTheme.bodyFont,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'หน่วยงาน: ${DivCache.nameOf(u['div'] as String?)}',
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
                    for (final r in roles)
                      chip(AuthProvider.roleName(r), palette.primaryDark),
                    if (!active) chip('ระงับการใช้งาน', ActionColors.danger),
                    if (locked) chip('ถูกล็อก', ActionColors.warning),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: () => _act(u),
            icon: Icon(_edit ? Icons.edit_rounded : Icons.lock_reset_rounded),
            label: Text(
              _edit ? 'แก้ไข' : 'กำหนดรหัสผ่าน',
              style: const TextStyle(fontFamily: AppTheme.bodyFont),
            ),
          ),
        ],
      ),
    );
  }

  /// ตัวแบ่งหน้าแบบเดียวกับ HTC: เลือกแถวต่อหน้า + หน้าแรก/ก่อนหน้า/ถัดไป/สุดท้าย
  Widget _pagination() {
    final palette = context.appPalette;
    final last = _totalPages - 1;
    final text = TextStyle(
      fontFamily: AppTheme.bodyFont,
      fontSize: 14,
      color: palette.textSecondary,
    );
    Widget nav(String tip, IconData icon, int target, bool enabled) =>
        IconButton(
          tooltip: tip,
          icon: Icon(icon),
          onPressed: enabled && !_loading ? () => _load(page: target) : null,
        );
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ทั้งหมด $_totalItems รายการ   แถวต่อหน้า', style: text),
            const SizedBox(width: 8),
            DropdownButton<int>(
              value: _size,
              underline: const SizedBox.shrink(),
              items: [
                for (final s in _sizes)
                  DropdownMenuItem(value: s, child: Text('$s')),
              ],
              onChanged: (v) {
                if (v == null) return;
                _size = v;
                _load(page: 0);
              },
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            nav('หน้าแรก', Icons.first_page, 0, _page > 0),
            nav('ก่อนหน้า', Icons.chevron_left, _page - 1, _page > 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'หน้า ${_totalPages == 0 ? 0 : _page + 1} / $_totalPages',
                style: text,
              ),
            ),
            nav('ถัดไป', Icons.chevron_right, _page + 1, _page < last),
            nav('หน้าสุดท้าย', Icons.last_page, last, _page < last),
          ],
        ),
      ],
    );
  }
}
