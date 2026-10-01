import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// เปิดระบบปลายทางในแท็บใหม่ เปิดไม่ได้ให้แจ้งผู้ใช้
Future<void> openLink(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เปิดลิงก์ไม่ได้: $url', style: const TextStyle(fontFamily: 'Sarabun'))),
    );
  }
}
