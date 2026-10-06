import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/menu_data.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/account_screen.dart';
import 'screens/download_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/upload_screen.dart';
import 'screens/user_form_screen.dart';
import 'screens/user_list_screen.dart';
import 'services/api_service.dart';
import 'utils/unsaved_guard.dart';
import 'widgets/app_header.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/form_helpers.dart';
import 'widgets/login_dialog.dart';
import 'widgets/sidebar_menu.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(SalApp(prefs: prefs));
}

class SalApp extends StatefulWidget {
  final SharedPreferences prefs;

  /// ใส่เองได้ตอนเทสต์ (ต่อกับ backend จำลอง) ปกติสร้างจาก [prefs]
  final ApiService? api;

  const SalApp({super.key, required this.prefs, this.api});

  @override
  State<SalApp> createState() => _SalAppState();
}

class _SalAppState extends State<SalApp> {
  static const String _themePreferenceKey = 'sal_theme';

  late String _themeId;

  /// สถานะเข้าสู่ระบบ อยู่ระดับแอป จะได้ไม่หายตอนเปลี่ยนธีม
  late final AuthProvider _auth = AuthProvider(
    widget.api ?? ApiService(widget.prefs),
  );

  @override
  void initState() {
    super.initState();
    _themeId = AppTheme.paletteFor(widget.prefs.getString(_themePreferenceKey))
        .id;
  }

  void _selectTheme(String themeId) {
    setState(() => _themeId = themeId);
    widget.prefs.setString(_themePreferenceKey, themeId);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'งานเงินเดือน กรมทางหลวง',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.themeFor(_themeId),
      locale: const Locale('th', 'TH'),
      supportedLocales: const [Locale('th', 'TH')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MainShell(
        prefs: widget.prefs,
        themeId: _themeId,
        onThemeChanged: _selectTheme,
        auth: _auth,
      ),
    );
  }
}

/// โครงหน้าหลัก: แถบหัว + เมนูข้าง (ตรึงได้) + เนื้อหา
class MainShell extends StatefulWidget {
  final SharedPreferences prefs;
  final String themeId;
  final ValueChanged<String> onThemeChanged;
  final AuthProvider auth;

  const MainShell({
    super.key,
    required this.prefs,
    required this.themeId,
    required this.onThemeChanged,
    required this.auth,
  });

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

  AuthProvider get _auth => widget.auth;

  /// กำลังเปิดหน้าบังคับเปลี่ยนรหัสผ่านอยู่ กันเปิดซ้อน
  bool _forcingPasswordChange = false;

  /// เปลี่ยนค่าเพื่อให้หน้ารายการผู้ใช้โหลดใหม่หลังสร้างผู้ใช้
  int _listVersion = 0;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
    // เปิดหน้าเว็บใหม่ทั้งที่ยังเข้าสู่ระบบค้างอยู่: กลับไปหน้าผู้ใช้งาน
    if (_auth.isLoggedIn) _selectedId = MenuData.accountId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkMustChangePassword(),
    );
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() {
      // ออกจากระบบ (กดเอง หรือ session หมดอายุ) กลับหน้าแรก
      if (!_auth.isLoggedIn) {
        _selectedId = MenuData.homeId;
        DivCache.clear();
      }
    });
    // ถูกออกจากระบบโดยไม่ได้กดเอง: บอกเหตุผล ไม่งั้นผู้ใช้จะงงว่าทำไมหลุด
    if (!_auth.isLoggedIn && _auth.takeSessionExpired()) {
      showAppMessage(
        context,
        'ถูกออกจากระบบ เพราะมีการเข้าสู่ระบบด้วยบัญชีนี้จากเครื่องอื่น หรือไม่ได้ใช้งานนานเกินกำหนด กรุณาเข้าสู่ระบบใหม่',
        error: true,
      );
    }
    _checkMustChangePassword();
  }

  /// เข้าครั้งแรกหรือผู้ดูแลระบบตั้งรหัสให้ใหม่: ต้องเปลี่ยนรหัสผ่านก่อน ไม่เปลี่ยน = ออกจากระบบ
  Future<void> _checkMustChangePassword() async {
    if (!mounted ||
        _loggingIn ||
        _forcingPasswordChange ||
        !_auth.mustChangePassword) {
      return;
    }
    _forcingPasswordChange = true;
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangePasswordDialog(auth: _auth, forced: true),
    );
    _forcingPasswordChange = false;
    if (changed != true && _auth.isLoggedIn) await _auth.logout();
  }

  /// หน้าเข้าสู่ระบบยังเปิดอยู่ — รอให้ปิดก่อนค่อยเปิดหน้าบังคับเปลี่ยนรหัสผ่าน
  /// ไม่งั้นสอง dialog ซ้อนกัน แล้วหน้าเข้าสู่ระบบจะไปปิดผิดตัว
  bool _loggingIn = false;

  Future<void> _login() async {
    _loggingIn = true;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LoginDialog(auth: _auth),
    );
    _loggingIn = false;
    if (ok == true && mounted) {
      setState(() => _selectedId = MenuData.accountId);
      await _checkMustChangePassword();
    }
  }

  /// เลือกเมนูภายใน — บางเมนูเปิดเป็น dialog ทับหน้าปัจจุบัน ที่เหลือเปลี่ยนเนื้อหาด้านขวา
  Future<void> _select(String id) async {
    // หน้าจอที่เปิดอยู่มีการแก้ไขค้าง: ถามก่อนพาไปหน้าอื่น
    if (!await UnsavedGuard.canLeave() || !mounted) return;
    switch (id) {
      case MenuData.changePasswordId:
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => ChangePasswordDialog(auth: _auth),
        );
      default:
        setState(() => _selectedId = id);
    }
  }

  Widget _content() {
    final admin = _auth.isLoggedIn && _auth.isAdmin;
    switch (_selectedId) {
      case MenuData.accountId when _auth.isLoggedIn:
        return AccountScreen(auth: _auth, onAction: _select);
      case MenuData.downloadId when _auth.isLoggedIn && _auth.canDownload:
        return DownloadScreen(auth: _auth);
      case MenuData.uploadId when _auth.isLoggedIn && _auth.canUpload:
        return UploadScreen(api: _auth.api);
      case MenuData.userCreateId when admin:
        return UserFormScreen(
          key: ValueKey('create-$_listVersion'),
          api: _auth.api,
          // ล้างฟอร์ม = สร้างหน้าใหม่ด้วย key ใหม่
          onCancel: () => setState(() => _listVersion++),
          // สร้างเสร็จพาไปหน้ารายการ จะได้เห็นผู้ใช้ที่เพิ่งสร้าง
          onSaved: () => setState(() {
            _selectedId = MenuData.userEditId;
            _listVersion++;
          }),
        );
      case MenuData.userEditId when admin:
        return UserListScreen(
          key: ValueKey('edit-$_listVersion'),
          api: _auth.api,
          mode: UserListMode.edit,
        );
      case MenuData.historyId when _auth.isLoggedIn && _auth.canUpload:
        return HistoryScreen(api: _auth.api);
      case MenuData.userResetId when admin:
        return UserListScreen(
          key: const ValueKey('reset'),
          api: _auth.api,
          mode: UserListMode.resetPassword,
        );
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPin = MediaQuery.of(context).size.width >= _pinMinWidth;
    final docked = _pinned && canPin;
    final content = _content();
    final userItems = _auth.menuItems;

    return Scaffold(
      appBar: AppHeader(
        showMenuButton: !docked,
        selectedThemeId: widget.themeId,
        onThemeChanged: widget.onThemeChanged,
        auth: _auth,
        onLogin: _login,
        onLogout: () async {
          if (await UnsavedGuard.canLeave()) await _auth.logout();
        },
        onUserAction: _select,
      ),
      drawer: docked
          ? null
          : Drawer(
              width: SidebarMenu.fullWidth,
              shape: const RoundedRectangleBorder(),
              child: SidebarMenu(
                canPin: canPin,
                pinned: _pinned,
                selectedId: _selectedId,
                userItems: userItems,
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
                  userItems: userItems,
                  onTogglePinned: _togglePinned,
                  onToggleCollapsed: () =>
                      setState(() => _collapsed = !_collapsed),
                  onSelectInternal: _select,
                ),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}
