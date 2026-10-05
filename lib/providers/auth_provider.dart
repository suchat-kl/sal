import 'package:flutter/foundation.dart';

import '../config/menu_data.dart';
import '../services/api_service.dart';

/// สถานะเข้าสู่ระบบของทั้งแอป — แบบเดียวกับ AuthProvider ของ HTC
class AuthProvider extends ChangeNotifier {
  final ApiService api;

  AuthProvider(this.api) {
    api.onSessionExpired = notifyListeners;
    // เปิดหน้าเว็บใหม่ทั้งที่เข้าสู่ระบบค้างอยู่: อ่านชื่อ/หน่วยงาน/บทบาทล่าสุดมาแทนค่าที่จำไว้
    if (isLoggedIn) {
      api.refreshSession().then((changed) {
        if (changed) notifyListeners();
      });
    }
  }

  Session? get session => api.session;
  bool get isLoggedIn => session != null;
  String get username => session?.username ?? '';
  String? get div => session?.div;

  /// หน่วยงานแบบ "รหัส ชื่อ" เช่น "060 ศูนย์เทคโนโลยีสารสนเทศ" (ไม่มีหน่วยงาน = null)
  String? get divLabel {
    final d = session?.div;
    if (d == null) return null;
    final n = session?.divName;
    return n == null || n.isEmpty ? d : '$d $n';
  }

  List<String> get roles => session?.roles ?? const [];
  bool hasRole(String role) => roles.contains(role);
  bool get isAdmin => hasRole('ADMIN');

  /// อัปโหลดไฟล์เงินเดือนได้
  bool get canUpload => isAdmin || hasRole('UPLOAD');

  /// ดาวน์โหลดไฟล์ของหน่วยงานได้
  bool get canDownload => isAdmin || hasRole('USER') || hasRole('UPLOAD');

  /// ดูไฟล์ของทุกหน่วยงานได้ (ไว้ช่วยแก้ปัญหาให้ผู้ใช้) ผู้ใช้ทั่วไปเห็นเฉพาะหน่วยงานตัวเอง
  bool get canSeeAllDivs => isAdmin || hasRole('UPLOAD');

  /// เมนูของผู้ใช้คนนี้ตามบทบาท
  List<MenuNode> get menuItems => isLoggedIn
      ? MenuData.userItems(
          isAdmin: isAdmin,
          canUpload: canUpload,
          canDownload: canDownload,
        )
      : const [];
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
