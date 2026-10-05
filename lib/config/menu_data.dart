import 'package:flutter/material.dart';

/// รายการเมนู 1 รายการ — มี [url] = เปิดระบบปลายทางในแท็บใหม่, มี [children] = กลุ่มเมนู
class MenuNode {
  final String id;
  final String title;
  final IconData icon;
  final String? url;
  final String? description;
  final String? statusLabel;
  final List<MenuNode> children;

  const MenuNode({
    required this.id,
    required this.title,
    required this.icon,
    this.url,
    this.description,
    this.statusLabel,
    this.children = const [],
  });

  bool get isGroup => children.isNotEmpty;
}

/// ลิงก์เดียวกับเมนูของระบบเดิม https://sal.doh.go.th/sal/
/// ลิงก์ของ dbdoh เปลี่ยนเป็น https (เครื่องนั้นเปิด HTTPS และ redirect จาก http อยู่แล้ว)
/// dev.doh.go.th:8088 และ hr-app:7777 คงตามเดิม เพราะยังไม่ได้ตรวจว่ารองรับ https
class MenuData {
  MenuData._();

  static const String homeId = 'home';
  static const String helpdeskUrl = 'https://smhd.doh.go.th/login';
  static const String legacyLoginUrl = 'https://sal.doh.go.th/sal/';

  static const List<MenuNode> items = [
    MenuNode(id: homeId, title: 'หน้าแรก', icon: Icons.home_rounded),
    MenuNode(
      id: 'tax',
      title: 'ใบรับรองภาษี/สลิป',
      icon: Icons.receipt_long_rounded,
      children: [
        MenuNode(
          id: 'tax-doh',
          title: 'ใบรับรองภาษีกรมทางหลวง/สลิป',
          icon: Icons.description_rounded,
          url: 'https://dbdoh.doh.go.th/yt/',
          description: 'หนังสือรับรองการหักภาษี ณ ที่จ่าย และสลิปเงินเดือน ข้าราชการ/ลูกจ้างประจำ/พนักงานราชการส่วนกลาง กรมทางหลวง',
        ),
        MenuNode(
          id: 'tax-police',
          title: 'ใบรับรองภาษีตำรวจทางหลวง/สลิป',
          icon: Icons.local_police_rounded,
          url: 'https://dbdoh.doh.go.th/tax/',
          description:
              'หนังสือรับรองการหักภาษี ณ ที่จ่าย และสลิปเงินเดือน ตำรวจทางหลวง',
        ),
        MenuNode(
          id: 'payroll-gov',
          title: 'สลิป (พนักงานราชการส่วนกลาง)',
          icon: Icons.badge_rounded,
          url: 'http://dev.doh.go.th:8088/payroll',
          description: 'สลิปเงินเดือนพนักงานราชการ สังกัดส่วนกลาง',
        ),
      ],
    ),
    MenuNode(
      id: 'debt',
      title: 'หักหนี้ (ข้าราชการ/ลูกจ้างประจำ)',
      icon: Icons.account_balance_wallet_rounded,
      url: 'https://dbdoh.doh.go.th/dp',
      description: 'รายการหักหนี้จากเงินเดือน สำหรับข้าราชการและลูกจ้างประจำ',
    ),
    MenuNode(
      id: 'funeral',
      title: 'ฌาปนกิจ',
      icon: Icons.volunteer_activism_rounded,
      children: [
        MenuNode(
          id: 'funeral-download',
          title: 'ดาวน์โหลดไฟล์',
          icon: Icons.download_rounded,
          url: 'https://sal.doh.go.th/Funeral/',
          description: 'ดาวน์โหลดเอกสารฌาปนกิจสงเคราะห์',
        ),
        MenuNode(
          id: 'funeral-system',
          title: 'ระบบฌาปนกิจสงเคราะห์',
          icon: Icons.groups_rounded,
          url: 'http://hr-app:7777/DohHrFfd/common/Login',
          description:
              'เข้าระบบฌาปนกิจสงเคราะห์ (ใช้ได้ภายในเครือข่ายกรมทางหลวง)',
        ),
        // คู่มือฌาปนกิจ (Funeral.pdf) เอาออกทั้งเมนู การ์ด และปุ่ม ตามที่ผู้ใช้สั่ง
      ],
    ),
    MenuNode(
      id: 'htc',
      title: 'จองห้องพัก/ห้องอบรม (HTC)',
      icon: Icons.apartment_rounded,
      url: 'https://inf.doh.go.th/htc/',
      description: 'ระบบจองห้องพัก ห้องประชุม และห้องกิจกรรม ศูนย์พัฒนาทรัพยากรบุคคลงานทาง',
      statusLabel: 'ระบบงานอยู่ในช่วงทดสอบ',
    ),
    MenuNode(
      id: 'helpdesk',
      title: 'Smart Helpdesk',
      icon: Icons.support_agent_rounded,
      url: helpdeskUrl,
      description: 'แจ้งปัญหาและสอบถามการใช้งาน',
    ),
  ];

  // ---- เมนูหลังเข้าสู่ระบบ (หน้าจอภายใน ไม่ใช่ลิงก์) ----
  static const String accountId = 'account';
  static const String changePasswordId = 'change-password';
  static const String userCreateId = 'user-create';
  static const String userEditId = 'user-edit';
  static const String userResetId = 'user-reset';

  /// เมนูของผู้ที่เข้าสู่ระบบแล้ว — เปลี่ยนรหัสผ่านใช้ได้ทุกบทบาท ที่เหลือเฉพาะ ADMIN
  static List<MenuNode> userItems({required bool isAdmin}) => [
    const MenuNode(
      id: accountId,
      title: 'หน้าผู้ใช้งาน',
      icon: Icons.account_circle_rounded,
    ),
    const MenuNode(
      id: changePasswordId,
      title: 'เปลี่ยนรหัสผ่าน',
      icon: Icons.key_rounded,
      description: 'เปลี่ยนรหัสผ่านของบัญชีตัวเอง',
    ),
    if (isAdmin) ...const [
      MenuNode(
        id: userCreateId,
        title: 'สร้างผู้ใช้งาน',
        icon: Icons.person_add_alt_1_rounded,
        description: 'เพิ่มบัญชีใหม่ กำหนดหน่วยงานและบทบาท',
      ),
      MenuNode(
        id: userEditId,
        title: 'แก้ไขผู้ใช้งาน',
        icon: Icons.manage_accounts_rounded,
        description: 'แก้ข้อมูล บทบาท ระงับหรือปลดล็อกบัญชี',
      ),
      MenuNode(
        id: userResetId,
        title: 'กำหนดรหัสผ่านใหม่',
        icon: Icons.lock_reset_rounded,
        description: 'ตั้งรหัสผ่านใหม่ให้ผู้ใช้ที่ลืมรหัสผ่าน',
      ),
    ],
  ];

  /// เมนูปลายทางทั้งหมด (ไม่รวมหน้าแรก) ใช้ทำการ์ดทางลัดในหน้าแรก
  static List<MenuNode> get shortcuts => [
    for (final m in items)
      if (m.isGroup) ...m.children else if (m.url != null) m,
  ];
}
