import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/api_service.dart';
import '../utils/unsaved_guard.dart';
import 'form_helpers.dart';

/// กำหนดรหัสผ่านใหม่ให้ผู้ใช้ (ADMIN) — ผู้ใช้ต้องเปลี่ยนเองอีกครั้งตอนเข้าสู่ระบบครั้งถัดไป
/// ปิดด้วยค่า true เมื่อสำเร็จ
class ResetPasswordDialog extends StatefulWidget {
  final ApiService api;
  final Map<String, dynamic> user;

  const ResetPasswordDialog({super.key, required this.api, required this.user});

  @override
  State<ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _dirty => _password.text.isNotEmpty || _confirm.text.isNotEmpty;

  /// กดยกเลิก/Esc: กรอกค้างไว้ให้ถามก่อนว่าจะบันทึกไหม
  Future<void> _close() async {
    if (_loading) return;
    if (_dirty) {
      final choice = await askUnsaved(context, saveLabel: 'กำหนดรหัสผ่านใหม่');
      if (!mounted || choice == UnsavedChoice.stay) return;
      if (choice == UnsavedChoice.save) {
        await _submit();
        return;
      }
    }
    if (mounted) Navigator.of(context).pop(false);
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final message = await widget.api.resetPassword(
        widget.user['id'] as String,
        _password.text,
      );
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: DialogShell(
        icon: Icons.lock_reset_rounded,
        title: 'กำหนดรหัสผ่านใหม่',
        subtitle:
            '${widget.user['username']}  ${widget.user['fullName'] ?? ''}',
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
                controller: _password,
                enabled: !_loading,
                obscureText: _obscure,
                autofocus: true,
                style: fieldText,
                onChanged: (_) => setState(() {}),
                decoration: appInput(
                  context,
                  label: 'รหัสผ่านใหม่',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    tooltip: _obscure ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: PasswordRule.problem,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirm,
                enabled: !_loading,
                obscureText: _obscure,
                style: fieldText,
                onFieldSubmitted: (_) => _submit(),
                decoration: appInput(
                  context,
                  label: 'ยืนยันรหัสผ่านใหม่',
                  icon: Icons.lock_outline,
                ),
                validator: (v) =>
                    v != _password.text ? 'รหัสผ่านสองช่องไม่ตรงกัน' : null,
              ),
              const SizedBox(height: 10),
              PasswordChecklist(password: _password.text),
              const SizedBox(height: 10),
              const Text(
                'ผู้ใช้จะถูกออกจากระบบทุกเครื่อง และต้องเปลี่ยนรหัสผ่านเองตอนเข้าสู่ระบบครั้งถัดไป',
                style: TextStyle(
                  fontFamily: AppTheme.bodyFont,
                  fontSize: 13,
                  color: ActionColors.warning,
                ),
              ),
              const SizedBox(height: 18),
              DialogButtons(
                label: 'กำหนดรหัสผ่านใหม่',
                icon: Icons.lock_reset_rounded,
                loading: _loading,
                onSubmit: _submit,
                onCancel: _close,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
