import 'package:flutter/material.dart';

/// โลโก้ระบบงานเงินเดือน: ปฏิทิน (วันที่ 25 วันเงินเดือนออก) + เหรียญบาท
/// ใช้ภาพเดียวกับไอคอนเว็บ (web/favicon.png, web/icons/*) สร้างจาก tool/make_icons.py
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_logo.png',
      width: size,
      height: size,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'งานเงินเดือน',
    );
  }
}
