import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

/// สถานะเข้าสู่ระบบของทั้งแอป — แบบเดียวกับ AuthProvider ของ HTC
class AuthProvider extends ChangeNotifier {
  final ApiService api;

  AuthProvider(this.api) {
    api.onSessionExpired = notifyListeners;
  }

  Session? get session => api.session;
  bool get isLoggedIn => session != null;
  String get username => session?.username ?? '';
  String? get div => session?.div;
  List<String> get roles => session?.roles ?? const [];
  bool hasRole(String role) => roles.contains(role);
  bool get isAdmin => hasRole('ADMIN');
  bool get mustChangePassword => session?.mustChangePassword ?? false;

  String get displayName {
    final n = session?.fullName ?? '';
    return n.isNotEmpty ? n : username;
  }

  /// ชื่อบทบาทภาษาไทย
  static const Map<String, String> roleNames = {
    'ADMIN': 'ผู้ดูแลระบบ',
    'UPLOAD': 'ผู้อัปโหลดไฟล์',
    'USER': 'ผู้ใช้งานทั่วไป',
  };

  static String roleName(String code) => roleNames[code] ?? code;

  String get roleLabel => roles.map(roleName).join(', ');

  Future<void> login(String username, String password) async {
    await api.login(username, password);
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    notifyListeners();
  }

  Future<String> changePassword(String oldPassword, String newPassword) async {
    final message = await api.changePassword(oldPassword, newPassword);
    notifyListeners();
    return message;
  }
}
