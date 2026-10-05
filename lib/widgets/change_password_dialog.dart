import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';
import 'form_helpers.dart';

/// เปลี่ยนรหัสผ่านของตัวเอง
/// [forced] = ถูกบังคับเปลี่ยน (เข้าครั้งแรก หรือผู้ดูแลระบบตั้งรหัสให้ใหม่) ปิดไม่ได้นอกจากออกจากระบบ
/// ปิดด้วยค่า true เมื่อเปลี่ยนสำเร็จ
class ChangePasswordDialog extends StatefulWidget {
  final AuthProvider auth;
  final bool forced;

  const ChangePasswordDialog({
    super.key,
    required this.auth,
    this.forced = false,
  });

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final message = await widget.auth.changePassword(_old.text, _new.text);
      if (!mounted) return;
      showAppMessage(context, message);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _passwordField(
    TextEditingController controller,
    String label, {
    String? Function(String?)? validator,
    bool last = false,
  }) => TextFormField(
    controller: controller,
    enabled: !_loading,
    obscureText: _obscure,
    style: fieldText,
    textInputAction: last ? TextInputAction.done : TextInputAction.next,
    onFieldSubmitted: last ? (_) => _submit() : null,
    onChanged: (_) => setState(() {}),
    decoration: appInput(context, label: label, icon: Icons.lock_outline),
    validator: validator,
  );

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forced,
      child: DialogShell(
        icon: Icons.key_rounded,
        title: 'เปลี่ยนรหัสผ่าน',
        subtitle: widget.forced
            ? 'ต้องเปลี่ยนรหัสผ่านก่อนใช้งานต่อ'
            : 'ผู้ใช้ ${widget.auth.username}',
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
              _passwordField(
                _old,
                'รหัสผ่านเดิม',
                validator: (v) =>
                    v == null || v.isEmpty ? 'กรุณากรอกรหัสผ่านเดิม' : null,
              ),
              const SizedBox(height: 14),
              _passwordField(
                _new,
                'รหัสผ่านใหม่',
                validator: (v) {
                  final problem = PasswordRule.problem(v);
                  if (problem != null) return problem;
                  if (v == _old.text) {
                    return 'รหัสผ่านใหม่ต้องไม่เหมือนรหัสผ่านเดิม';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _passwordField(
                _confirm,
                'ยืนยันรหัสผ่านใหม่',
                last: true,
                validator: (v) =>
                    v != _new.text ? 'รหัสผ่านใหม่สองช่องไม่ตรงกัน' : null,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                    size: 18,
                  ),
                  label: Text(_obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน'),
                ),
              ),
              PasswordChecklist(password: _new.text),
              const SizedBox(height: 20),
              DialogButtons(
                label: 'บันทึกรหัสผ่านใหม่',
                icon: Icons.save_rounded,
                loading: _loading,
                onSubmit: _submit,
                cancelLabel: widget.forced ? 'ออกจากระบบ' : 'ยกเลิก',
                onCancel: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
