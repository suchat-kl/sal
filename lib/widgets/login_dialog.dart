import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import 'form_helpers.dart';

/// หน้าเข้าสู่ระบบ (ชื่อผู้ใช้ + รหัสผ่าน) — แบบเดียวกับ LoginDialog ของ HTC
/// ปิดด้วยค่า true เมื่อเข้าสู่ระบบสำเร็จ
class LoginDialog extends StatefulWidget {
  final AuthProvider auth;

  const LoginDialog({super.key, required this.auth});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.auth.login(_username.text.trim(), _password.text);
      if (!mounted) return;
      showAppMessage(context, 'ยินดีต้อนรับ คุณ${widget.auth.displayName}');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DialogShell(
      icon: Icons.lock_person_rounded,
      title: 'เข้าสู่ระบบ',
      subtitle: 'งานเงินเดือน กรมทางหลวง',
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
              enabled: !_loading,
              autofocus: true,
              style: fieldText,
              textInputAction: TextInputAction.next,
              decoration: appInput(
                context,
                label: 'ชื่อผู้ใช้',
                hint: 'กรอกชื่อผู้ใช้',
                icon: Icons.person_outline,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'กรุณากรอกชื่อผู้ใช้' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password,
              enabled: !_loading,
              obscureText: _obscure,
              style: fieldText,
              onFieldSubmitted: (_) => _submit(),
              decoration: appInput(
                context,
                label: 'รหัสผ่าน',
                hint: 'กรอกรหัสผ่าน',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null,
            ),
            const SizedBox(height: 24),
            DialogButtons(
              label: 'เข้าสู่ระบบ',
              icon: Icons.login,
              loading: _loading,
              onSubmit: _submit,
              onCancel: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
