import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/form_helpers.dart';

/// รายชื่อหน่วยงานจาก collection div_dept โหลดครั้งเดียวต่อการเข้าสู่ระบบ (163 รายการ ไม่เปลี่ยนบ่อย)
class DivCache {
  DivCache._();
  static List<Map<String, String>>? _divs;

  static Future<List<Map<String, String>>> load(ApiService api) async =>
      _divs ??= await api.divs();

  static void clear() => _divs = null;

  static String label(Map<String, String> d) => '${d['div']} ${d['divname']}';

  static String nameOf(String? div) {
    if (div == null) return '-';
    for (final d in _divs ?? const <Map<String, String>>[]) {
      if (d['div'] == div) return label(d);
    }
    return div;
  }
}

/// หน้าสร้าง/แก้ไขผู้ใช้งาน (ADMIN) — [user] = null คือสร้างใหม่
/// แสดงในพื้นที่เนื้อหาข้างเมนู (ไม่ใช่ dialog) เมนูข้างยังตรึงและใช้ธีมเดียวกับหน้าแรก
class UserFormScreen extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic>? user;

  /// บันทึกสำเร็จ
  final VoidCallback onSaved;

  /// กดยกเลิก/กลับ
  final VoidCallback onCancel;

  const UserFormScreen({
    super.key,
    required this.api,
    required this.onSaved,
    required this.onCancel,
    this.user,
  });

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  static const List<String> _allRoles = ['USER', 'UPLOAD', 'ADMIN'];

  final _formKey = GlobalKey<FormState>();
  late final _username = TextEditingController(text: _text('username'));
  late final _fullName = TextEditingController(text: _text('fullName'));
  late final _email = TextEditingController(text: _text('email'));
  late final _phone = TextEditingController(text: _text('phone'));
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _divText = TextEditingController();
  final _divFocus = FocusNode();

  late final Set<String> _roles = {
    for (final r in (widget.user?['roles'] as List? ?? const ['USER']))
      r.toString(),
  };
  late String? _div = widget.user?['div'] as String?;
  late bool _active = widget.user?['active'] != false;
  late bool _locked = widget.user?['locked'] == true;

  List<Map<String, String>> _divs = const [];
  bool _loadingDivs = true;
  bool _saving = false;
  bool _obscure = true;
  String? _error;

  bool get _isNew => widget.user == null;

  String _text(String key) => (widget.user?[key] ?? '').toString();

  @override
  void initState() {
    super.initState();
    _loadDivs();
  }

  Future<void> _loadDivs() async {
    try {
      final divs = await DivCache.load(widget.api);
      if (!mounted) return;
      setState(() {
        _divs = divs;
        _loadingDivs = false;
        if (_div != null) _divText.text = DivCache.nameOf(_div);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingDivs = false;
        _error = 'โหลดรายชื่อหน่วยงานไม่ได้: $e';
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _username,
      _fullName,
      _email,
      _phone,
      _password,
      _confirm,
      _divText,
    ]) {
      c.dispose();
    }
    _divFocus.dispose();
    super.dispose();
  }

  /// หน่วยงานที่ตรงกับข้อความที่พิมพ์ ค้นได้ทั้งรหัสและชื่อ ไม่สนช่องว่าง
  Iterable<Map<String, String>> _matchDivs(String text) {
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final q = norm(text);
    if (q.isEmpty) return _divs.take(30);
    return _divs.where((d) => norm(DivCache.label(d)).contains(q)).take(30);
  }

  Future<void> _submit() async {
    if (_saving) return;
    final valid = _formKey.currentState!.validate();
    final problem = _roles.isEmpty ? 'กรุณาเลือกบทบาทอย่างน้อย 1 บทบาท' : null;
    if (!valid || problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = <String, dynamic>{
      'username': _username.text.trim(),
      'fullName': _fullName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'div': _div,
      'roles': _roles.toList(),
      'active': _active,
      'locked': _locked,
      if (_isNew) 'password': _password.text,
    };
    try {
      if (_isNew) {
        await widget.api.createUser(body);
      } else {
        await widget.api.updateUser(widget.user!['id'] as String, body);
      }
      if (!mounted) return;
      showAppMessage(
        context,
        _isNew
            ? 'สร้างผู้ใช้ ${body['username']} สำเร็จ'
            : 'บันทึกข้อมูลผู้ใช้ ${body['username']} สำเร็จ',
      );
      widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  /// ช่องหน่วยงานแบบ autocomplete: พิมพ์รหัสหรือชื่อแล้วเลือกจากรายการที่ดึงจาก div_dept
  Widget _divField() {
    final palette = context.appPalette;
    return RawAutocomplete<Map<String, String>>(
      textEditingController: _divText,
      focusNode: _divFocus,
      displayStringForOption: DivCache.label,
      optionsBuilder: (value) => _matchDivs(value.text),
      onSelected: (d) => setState(() => _div = d['div']),
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: !_saving && !_loadingDivs,
            style: fieldText,
            onFieldSubmitted: (_) => onSubmitted(),
            // แก้ข้อความหลังเลือกแล้ว = ยังไม่ได้เลือกหน่วยงาน ต้องเลือกจากรายการใหม่
            onChanged: (v) {
              if (_div != null && v != DivCache.nameOf(_div)) {
                setState(() => _div = null);
              }
            },
            decoration: appInput(
              context,
              label: 'หน่วยงาน',
              hint: _loadingDivs
                  ? 'กำลังโหลดรายชื่อหน่วยงาน...'
                  : 'พิมพ์รหัสหรือชื่อหน่วยงาน แล้วเลือกจากรายการ',
              icon: Icons.apartment_rounded,
              suffix: controller.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'ล้างหน่วยงาน',
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() {
                        controller.clear();
                        _div = null;
                      }),
                    ),
            ),
            validator: (v) {
              final typed = (v ?? '').trim().isNotEmpty;
              if (typed && _div == null) {
                return 'กรุณาเลือกหน่วยงานจากรายการ';
              }
              if (_div == null && _roles.contains('USER')) {
                return 'ผู้ใช้งานทั่วไปต้องระบุหน่วยงาน';
              }
              return null;
            },
          ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(12),
          color: palette.surface,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280, maxWidth: 560),
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
                    child: Row(
                      children: [
                        SizedBox(
                          width: 52,
                          child: Text(
                            d['div']!,
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: palette.primaryDark,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            d['divname']!,
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 15,
                              color: palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    const gap = SizedBox(height: 14);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            if (!_isNew)
              IconButton(
                tooltip: 'กลับไปรายการผู้ใช้',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _saving ? null : widget.onCancel,
              ),
            Icon(
              _isNew ? Icons.person_add_alt_1_rounded : Icons.manage_accounts,
              color: palette.primary,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _isNew ? 'สร้างผู้ใช้งาน' : 'แก้ไขผู้ใช้งาน',
                style: palette.heading(24),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _isNew
              ? 'ผู้ใช้ต้องเปลี่ยนรหัสผ่านเองตอนเข้าสู่ระบบครั้งแรก'
              : 'ผู้ใช้ ${_username.text}',
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
                        controller: _username,
                        enabled: _isNew && !_saving,
                        style: fieldText,
                        decoration: appInput(
                          context,
                          label: 'ชื่อผู้ใช้',
                          hint: 'a-z A-Z 0-9 . _ - ยาว 3-50 ตัว',
                          icon: Icons.person_outline,
                        ),
                        validator: (v) =>
                            !_isNew ||
                                RegExp(r'^[A-Za-z0-9._-]{3,50}$')
                                    .hasMatch(v?.trim() ?? '')
                            ? null
                            : 'ชื่อผู้ใช้ต้องยาว 3-50 ตัว ใช้ได้เฉพาะ a-z A-Z 0-9 . _ -',
                      ),
                      gap,
                      TextFormField(
                        controller: _fullName,
                        enabled: !_saving,
                        style: fieldText,
                        decoration: appInput(
                          context,
                          label: 'ชื่อ-นามสกุล',
                          icon: Icons.badge_outlined,
                        ),
                        validator: (v) => (v?.trim().length ?? 0) < 3
                            ? 'กรุณากรอกชื่อ-นามสกุล อย่างน้อย 3 ตัวอักษร'
                            : null,
                      ),
                      gap,
                      _divField(),
                      gap,
                      Text(
                        'บทบาท',
                        style: TextStyle(
                          fontFamily: AppTheme.bodyFont,
                          fontSize: 14,
                          color: palette.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final r in _allRoles)
                            FilterChip(
                              label: Text(
                                AuthProvider.roleName(r),
                                style: const TextStyle(
                                  fontFamily: AppTheme.bodyFont,
                                  fontSize: 14,
                                ),
                              ),
                              selected: _roles.contains(r),
                              onSelected: _saving
                                  ? null
                                  : (on) => setState(
                                      () =>
                                          on ? _roles.add(r) : _roles.remove(r),
                                    ),
                            ),
                        ],
                      ),
                      gap,
                      TextFormField(
                        controller: _email,
                        enabled: !_saving,
                        style: fieldText,
                        decoration: appInput(
                          context,
                          label: 'อีเมล (ไม่บังคับ)',
                          icon: Icons.mail_outline,
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          return t.isEmpty ||
                                  RegExp(r'^\S+@\S+\.\S+$').hasMatch(t)
                              ? null
                              : 'รูปแบบอีเมลไม่ถูกต้อง';
                        },
                      ),
                      gap,
                      TextFormField(
                        controller: _phone,
                        enabled: !_saving,
                        style: fieldText,
                        decoration: appInput(
                          context,
                          label: 'โทรศัพท์ (ไม่บังคับ)',
                          icon: Icons.phone_outlined,
                        ),
                      ),
                      if (_isNew) ...[
                        gap,
                        TextFormField(
                          controller: _password,
                          enabled: !_saving,
                          obscureText: _obscure,
                          style: fieldText,
                          onChanged: (_) => setState(() {}),
                          decoration: appInput(
                            context,
                            label: 'รหัสผ่านตั้งต้น',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              tooltip: _obscure
                                  ? 'แสดงรหัสผ่าน'
                                  : 'ซ่อนรหัสผ่าน',
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: PasswordRule.problem,
                        ),
                        gap,
                        TextFormField(
                          controller: _confirm,
                          enabled: !_saving,
                          obscureText: _obscure,
                          style: fieldText,
                          decoration: appInput(
                            context,
                            label: 'ยืนยันรหัสผ่านตั้งต้น',
                            icon: Icons.lock_outline,
                          ),
                          validator: (v) => v != _password.text
                              ? 'รหัสผ่านสองช่องไม่ตรงกัน'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        PasswordChecklist(password: _password.text),
                      ] else ...[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _active,
                          onChanged: _saving
                              ? null
                              : (v) => setState(() => _active = v),
                          title: const Text(
                            'เปิดใช้งานบัญชี',
                            style: TextStyle(fontFamily: AppTheme.bodyFont),
                          ),
                          subtitle: const Text(
                            'ปิดแล้วผู้ใช้เข้าสู่ระบบไม่ได้ และถูกออกจากระบบทันที',
                            style: TextStyle(
                              fontFamily: AppTheme.bodyFont,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (widget.user?['locked'] == true)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            value: !_locked,
                            onChanged: _saving
                                ? null
                                : (v) => setState(() => _locked = !v),
                            title: const Text(
                              'ปลดล็อกบัญชี',
                              style: TextStyle(fontFamily: AppTheme.bodyFont),
                            ),
                            subtitle: const Text(
                              'บัญชีนี้ถูกล็อกเพราะใส่รหัสผ่านผิดหลายครั้ง',
                              style: TextStyle(
                                fontFamily: AppTheme.bodyFont,
                                fontSize: 13,
                                color: ActionColors.danger,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: 20),
                      DialogButtons(
                        label: _isNew ? 'สร้างผู้ใช้งาน' : 'บันทึก',
                        icon: Icons.save_rounded,
                        loading: _saving,
                        onSubmit: _submit,
                        cancelLabel: _isNew ? 'ล้างฟอร์ม' : 'ยกเลิก',
                        onCancel: widget.onCancel,
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
