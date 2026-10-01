import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/menu_data.dart';
import 'config/theme.dart';
import 'screens/home_screen.dart';
import 'widgets/app_header.dart';
import 'widgets/sidebar_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(SalApp(prefs: prefs));
}

class SalApp extends StatelessWidget {
  final SharedPreferences prefs;

  const SalApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'งานเงินเดือน กรมทางหลวง',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      locale: const Locale('th', 'TH'),
      supportedLocales: const [Locale('th', 'TH')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MainShell(prefs: prefs),
    );
  }
}

/// โครงหน้าหลัก: แถบหัว + เมนูข้าง (ตรึงได้) + เนื้อหา
class MainShell extends StatefulWidget {
  final SharedPreferences prefs;

  const MainShell({super.key, required this.prefs});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  /// จำการตรึงเมนูไว้ในเบราว์เซอร์
  static const String _pinnedKey = 'sal_menu_pinned';

  /// ตรึงเมนูได้เฉพาะจอกว้าง จอแคบ (มือถือ/แท็บเล็ตแนวตั้ง) ใช้เมนูเลื่อนออก
  static const double _pinMinWidth = 900;

  /// ครั้งแรกตรึงไว้เป็นค่าเริ่มต้น ผู้ใช้เลิกตรึงได้ และระบบจำไว้
  late bool _pinned = widget.prefs.getBool(_pinnedKey) ?? true;

  /// ตอนตรึง: true = เหลือแต่ไอคอน
  bool _collapsed = true;

  String _selectedId = MenuData.homeId;

  void _togglePinned() {
    setState(() {
      _pinned = !_pinned;
      _collapsed = true;
    });
    widget.prefs.setBool(_pinnedKey, _pinned);
  }

  void _select(String id) => setState(() => _selectedId = id);

  @override
  Widget build(BuildContext context) {
    final canPin = MediaQuery.of(context).size.width >= _pinMinWidth;
    final docked = _pinned && canPin;
    // ตอนนี้มีหน้าภายในหน้าเดียว (หน้าแรก) เมนูอื่นเปิดระบบปลายทางในแท็บใหม่
    const content = HomeScreen();

    return Scaffold(
      appBar: AppHeader(showMenuButton: !docked),
      drawer: docked
          ? null
          : Drawer(
              width: SidebarMenu.fullWidth,
              shape: const RoundedRectangleBorder(),
              child: SidebarMenu(
                canPin: canPin,
                pinned: _pinned,
                selectedId: _selectedId,
                onTogglePinned: () {
                  Navigator.of(context).pop();
                  _togglePinned();
                },
                onSelectInternal: _select,
              ),
            ),
      body: docked
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SidebarMenu(
                  docked: true,
                  collapsed: _collapsed,
                  canPin: true,
                  pinned: true,
                  selectedId: _selectedId,
                  onTogglePinned: _togglePinned,
                  onToggleCollapsed: () => setState(() => _collapsed = !_collapsed),
                  onSelectInternal: _select,
                ),
                const Expanded(child: content),
              ],
            )
          : content,
    );
  }
}
