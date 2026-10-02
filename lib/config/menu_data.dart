import 'package:flutter/material.dart';

/// รายการเมนู 1 รายการ — มี [url] = เปิดระบบปลายทางในแท็บใหม่, มี [children] = กลุ่มเมนู
class MenuNode {
  final String id;
  final String title;
  final IconData icon;
  final String? url;
  final String? description;
  final List<MenuNode> children;

  const MenuNode({
    required this.id,
    required this.title,
    required this.icon,
    this.url,
    this.description,
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
      id: 'helpdesk',
      title: 'Smart Helpdesk',
      icon: Icons.support_agent_rounded,
      url: helpdeskUrl,
      description: 'แจ้งปัญหาและสอบถามการใช้งาน',
    ),
  ];

  /// เมนูปลายทางทั้งหมด (ไม่รวมหน้าแรก) ใช้ทำการ์ดทางลัดในหน้าแรก
  static List<MenuNode> get shortcuts => [
    for (final m in items)
      if (m.isGroup) ...m.children else if (m.url != null) m,
  ];
}
