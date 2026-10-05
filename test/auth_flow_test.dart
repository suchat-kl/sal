import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sal/main.dart';
import 'package:sal/services/api_service.dart';
import 'package:sal/widgets/sidebar_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// backend จำลอง ตอบตามสัญญาของ Spring Boot `salary` (ชื่อฟิลด์ snake_case ของ /api/auth/*)
class FakeBackend implements HttpClientAdapter {
  /// ผู้ใช้ที่เข้าสู่ระบบได้: username -> (password, roles, mustChange)
  final Map<String, ({String password, List<String> roles, bool mustChange})>
  accounts = {
    'admin': (password: 'Admin@2569x', roles: ['ADMIN'], mustChange: false),
    'user291': (password: 'User@2569x', roles: ['USER'], mustChange: false),
    'newbie': (password: 'Temp@1234', roles: ['USER'], mustChange: true),
  };

  final List<String> calls = [];

  /// จำลองว่าบัญชีนี้ถูกเข้าสู่ระบบจากเครื่องอื่น: token เดิมใช้ไม่ได้และต่ออายุไม่ได้
  bool kicked = false;
  Map<String, dynamic>? lastBody;

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    calls.add('${options.method} $path');
    final data = options.data;
    final body = data is Map ? Map<String, dynamic>.from(data) : null;
    lastBody = body ?? lastBody;

    if (path == '/api/auth/login' && body?['username'] == 'locked') {
      return _json(401, {
        'success': false,
        'message': 'บัญชีถูกล็อกชั่วคราวเพราะใส่รหัสผ่านผิด 5 ครั้ง กรุณาลองใหม่ในอีก 10 นาที',
      });
    }
    if (kicked && path == '/api/auth/refresh-token') {
      return _json(403, {'success': false, 'message': 'กรุณาเข้าสู่ระบบใหม่'});
    }
    if (kicked && path != '/api/auth/login') {
      return _json(401, {'success': false, 'message': 'กรุณาเข้าสู่ระบบ'});
    }
    if (path == '/api/auth/login') {
      final a = accounts[body!['username']];
      if (a == null || a.password != body['password']) {
        return _json(401, {
          'success': false,
          'message': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
        });
      }
      return _json(200, {
        'access_token': 'access-${body['username']}',
        'refresh_token': 'refresh-${body['username']}',
        'username': body['username'],
        'full_name': 'ผู้ใช้ ${body['username']}',
        'div': a.roles.contains('USER') ? '291' : '060',
        'div_name': a.roles.contains('USER')
            ? 'ศูนย์สร้างทางลำปาง'
            : 'ศูนย์เทคโนโลยีสารสนเทศ',
        'roles': a.roles,
        if (a.mustChange) 'must_change_password': true,
      });
    }
    if (options.headers['Authorization'] == null) {
      return _json(401, {'success': false, 'message': 'กรุณาเข้าสู่ระบบ'});
    }
    if (path == '/api/auth/logout') return _json(200, {'success': true});
    if (path == '/api/auth/me') {
      // ข้อมูลล่าสุดจาก backend: ผู้ดูแลเปลี่ยนหน่วยงานของ admin ไปแล้วหลังเข้าสู่ระบบครั้งก่อน
      return _json(200, {
        'username': 'admin',
        'full_name': 'ผู้ใช้ admin',
        'div': '293',
        'div_name': 'ศูนย์สร้างทางขอนแก่น',
        'roles': ['ADMIN'],
        'must_change_password': false,
      });
    }
    if (path == '/api/auth/changepassword') {
      return _json(200, {'success': true, 'message': 'เปลี่ยนรหัสผ่านสำเร็จ'});
    }
    if (path == '/api/download/divs') {
      return _json(200, [
        {'div': '291', 'divname': 'ศูนย์สร้างทางลำปาง'},
        {'div': '293', 'divname': 'ศูนย์สร้างทางขอนแก่น'},
      ]);
    }
    if (path == '/api/admin/users' && options.method == 'GET') {
      return _json(200, {
        'users': [
          {
            'id': 'u1',
            'username': 'user291',
            'fullName': 'สมชาย ใจดี',
            'div': '291',
            'roles': ['USER'],
            'active': true,
            'locked': true,
          },
        ],
        'currentPage': 0,
        'totalItems': 1,
        'totalPages': 1,
        'pageSize': 10,
      });
    }
    if (path.endsWith('/reset-password')) {
      return _json(200, {'success': true, 'message': 'ตั้งรหัสผ่านใหม่สำเร็จ'});
    }
    return _json(200, {'success': true});
  }

  @override
  void close({bool force = false}) {}
}

Future<void> _loadFonts() async {
  for (final family in ['Sarabun', 'Kanit']) {
    final loader = FontLoader(family);
    for (final w in ['Regular', 'Medium', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/$family-$w.ttf'));
    }
    await loader.load();
  }
}

Finder _inMenu(String text) =>
    find.descendant(of: find.byType(SidebarMenu), matching: find.text(text));

void main() {
  setUpAll(_loadFonts);

  late FakeBackend backend;
  late SharedPreferences prefs;

  Future<void> start(WidgetTester tester, {double width = 1400}) async {
    tester.view.physicalSize = Size(width, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    backend = FakeBackend();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'))
      ..httpClientAdapter = backend;
    await tester.pumpWidget(
      SalApp(
        prefs: prefs,
        api: ApiService(prefs, dio: dio),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String user, String pass) async {
    await tester.tap(find.text('เข้าสู่ระบบเจ้าหน้าที่'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ชื่อผู้ใช้'),
      user,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'รหัสผ่าน'),
      pass,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    // หลังเข้าสู่ระบบมีข้อความแจ้งว่าใช้งานได้ทีละเครื่อง กดรับทราบก่อนทำอย่างอื่น
    final ack = find.widgetWithText(FilledButton, 'รับทราบ');
    if (ack.evaluate().isNotEmpty) {
      await tester.tap(ack);
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'กดปุ่มเข้าสู่ระบบแล้วขึ้นหน้าชื่อผู้ใช้/รหัสผ่าน รหัสผิดแจ้งเตือน',
    (tester) async {
      await start(tester);
      await login(tester, 'admin', 'wrong');
      expect(find.text('ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง'), findsOneWidget);
      // ยังอยู่หน้าเข้าสู่ระบบ ไม่ได้เข้าหน้าผู้ใช้งาน
      expect(find.text('เมนูผู้ใช้งาน'), findsNothing);
      expect(prefs.getString('sal_access_token'), isNull);
    },
  );

  testWidgets('ADMIN เข้าสู่ระบบแล้วเห็นหน้าใหม่พร้อมเมนูครบ 4 รายการ', (
    tester,
  ) async {
    await start(tester);
    await login(tester, 'admin', 'Admin@2569x');

    expect(find.text('ยินดีต้อนรับ คุณผู้ใช้ admin'), findsWidgets);
    // แถบต้อนรับแสดงรหัสพร้อมชื่อหน่วยงาน
    expect(
      find.textContaining('หน่วยงาน 060 ศูนย์เทคโนโลยีสารสนเทศ'),
      findsOneWidget,
    );
    expect(find.text('เมนูผู้ใช้งาน'), findsOneWidget);
    for (final t in [
      'เปลี่ยนรหัสผ่าน',
      'สร้างผู้ใช้งาน',
      'แก้ไขผู้ใช้งาน',
      'กำหนดรหัสผ่านใหม่',
    ]) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    // ปุ่มเข้าสู่ระบบหายไป เป็นปุ่มชื่อผู้ใช้แทน
    expect(find.text('เข้าสู่ระบบเจ้าหน้าที่'), findsNothing);
    expect(find.byTooltip('บัญชีผู้ใช้'), findsOneWidget);

    // เมนูข้างยังตรึง/ขยายได้เหมือนหน้าแรก และมีเมนูผู้ใช้งาน
    await tester.tap(find.byTooltip('ขยายเมนู'));
    await tester.pumpAndSettle();
    expect(_inMenu('สร้างผู้ใช้งาน'), findsOneWidget);
    expect(_inMenu('กำหนดรหัสผ่านใหม่'), findsOneWidget);
    expect(_inMenu('หักหนี้ (ข้าราชการ/ลูกจ้างประจำ)'), findsOneWidget);
  });

  testWidgets('USER เห็นเฉพาะเมนูเปลี่ยนรหัสผ่าน', (tester) async {
    await start(tester);
    await login(tester, 'user291', 'User@2569x');

    expect(find.text('เมนูผู้ใช้งาน'), findsOneWidget);
    expect(find.text('เปลี่ยนรหัสผ่าน'), findsOneWidget);
    expect(find.text('สร้างผู้ใช้งาน'), findsNothing);
    expect(find.text('แก้ไขผู้ใช้งาน'), findsNothing);
    expect(find.text('กำหนดรหัสผ่านใหม่'), findsNothing);
  });

  testWidgets(
    'เปลี่ยนรหัสผ่าน: ตรวจกติกาก่อนส่ง แล้วส่งรหัสเดิม/ใหม่ไป backend',
    (tester) async {
      await start(tester);
      await login(tester, 'user291', 'User@2569x');
      await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
      await tester.pumpAndSettle();

      final old = find.widgetWithText(TextFormField, 'รหัสผ่านเดิม');
      final neu = find.widgetWithText(TextFormField, 'รหัสผ่านใหม่');
      final confirm = find.widgetWithText(TextFormField, 'ยืนยันรหัสผ่านใหม่');
      await tester.enterText(old, 'User@2569x');
      await tester.enterText(neu, 'weakpass');
      await tester.enterText(confirm, 'weakpass');
      await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
      await tester.pumpAndSettle();
      expect(find.textContaining('รหัสผ่านต้องมีตัวพิมพ์ใหญ่'), findsOneWidget);
      expect(backend.calls, isNot(contains('POST /api/auth/changepassword')));

      await tester.enterText(neu, 'NewPass@2570');
      await tester.enterText(confirm, 'NewPass@2570');
      await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
      await tester.pumpAndSettle();
      expect(backend.calls, contains('POST /api/auth/changepassword'));
      expect(backend.lastBody, {
        'oldPassword': 'User@2569x',
        'newPassword': 'NewPass@2570',
      });
      expect(find.text('บันทึกรหัสผ่านใหม่'), findsNothing);
    },
  );

  testWidgets('ถูกบังคับเปลี่ยนรหัสผ่าน: ไม่เปลี่ยนแล้วกดออก = ออกจากระบบ', (
    tester,
  ) async {
    await start(tester);
    await login(tester, 'newbie', 'Temp@1234');

    expect(find.text('ต้องเปลี่ยนรหัสผ่านก่อนใช้งานต่อ'), findsOneWidget);
    await tester.ensureVisible(
      find.widgetWithText(OutlinedButton, 'ออกจากระบบ'),
    );
    await tester.tap(find.widgetWithText(OutlinedButton, 'ออกจากระบบ'));
    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบเจ้าหน้าที่'), findsOneWidget);
    expect(prefs.getString('sal_access_token'), isNull);
    expect(backend.calls, contains('POST /api/auth/logout'));
  });

  testWidgets(
    'ADMIN: แก้ไขผู้ใช้งาน เป็นหน้าจอ (ไม่ใช่ dialog) ปลดล็อกแล้วกลับรายการ',
    (tester) async {
      await start(tester);
      await login(tester, 'admin', 'Admin@2569x');
      await tester.tap(find.text('แก้ไขผู้ใช้งาน'));
      await tester.pumpAndSettle();

      expect(find.textContaining('สมชาย ใจดี'), findsOneWidget);
      expect(find.text('หน่วยงาน: 291 ศูนย์สร้างทางลำปาง'), findsOneWidget);
      expect(find.text('ถูกล็อก'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'แก้ไข'));
      await tester.pumpAndSettle();
      // หน้าแก้ไขแสดงแทนรายการ ไม่มี dialog และเมนูข้างยังอยู่
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(SidebarMenu), findsOneWidget);
      expect(find.byTooltip('ปิด'), findsOneWidget);
      // ช่องหน่วยงานเติมรหัส+ชื่อจาก div_dept ให้แล้ว
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, 'หน่วยงาน'),
            )
            .controller!
            .text,
        '291 ศูนย์สร้างทางลำปาง',
      );

      await tester.ensureVisible(find.text('ปลดล็อกบัญชี'));
      await tester.tap(find.text('ปลดล็อกบัญชี'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.widgetWithText(FilledButton, 'บันทึก'));
      await tester.tap(find.widgetWithText(FilledButton, 'บันทึก'));
      await tester.pumpAndSettle();

      expect(backend.calls, contains('PUT /api/admin/users/u1'));
      expect(backend.lastBody!['locked'], false);
      expect(backend.lastBody!['div'], '291');
      expect(backend.lastBody!['roles'], ['USER']);
      // บันทึกแล้วกลับหน้ารายการ
      expect(find.byTooltip('ปิด'), findsNothing);
      expect(find.textContaining('สมชาย ใจดี'), findsOneWidget);
    },
  );

  testWidgets(
    'ADMIN: สร้างผู้ใช้งาน เลือกหน่วยงานแบบ autocomplete จาก div_dept',
    (tester) async {
      await start(tester);
      await login(tester, 'admin', 'Admin@2569x');
      await tester.tap(find.text('สร้างผู้ใช้งาน'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);

      final div = find.widgetWithText(TextFormField, 'หน่วยงาน');
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ชื่อผู้ใช้'),
        'kk01',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ชื่อ-นามสกุล'),
        'สมหญิง รักงาน',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'รหัสผ่านตั้งต้น'),
        'Temp@1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ยืนยันรหัสผ่านตั้งต้น'),
        'Temp@1234',
      );

      // พิมพ์เองโดยไม่เลือกจากรายการ = ยังไม่ถือว่าเลือกหน่วยงาน
      await tester.enterText(div, 'ขอนแก่น');
      await tester.pumpAndSettle();
      expect(find.text('ศูนย์สร้างทางขอนแก่น'), findsOneWidget);
      expect(find.text('ศูนย์สร้างทางลำปาง'), findsNothing);
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'สร้างผู้ใช้งาน'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'สร้างผู้ใช้งาน'));
      await tester.pumpAndSettle();
      expect(find.text('กรุณาเลือกหน่วยงานจากรายการ'), findsOneWidget);
      expect(backend.calls, isNot(contains('POST /api/admin/users')));

      // ค้นด้วยรหัสก็ได้ แล้วเลือกจากรายการ
      await tester.ensureVisible(div);
      await tester.enterText(div, '293');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ศูนย์สร้างทางขอนแก่น'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(div).controller!.text,
        '293 ศูนย์สร้างทางขอนแก่น',
      );
      await tester.ensureVisible(
        find.widgetWithText(FilledButton, 'สร้างผู้ใช้งาน'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'สร้างผู้ใช้งาน'));
      await tester.pumpAndSettle();

      expect(backend.calls, contains('POST /api/admin/users'));
      expect(backend.lastBody!['username'], 'kk01');
      expect(backend.lastBody!['div'], '293');
      expect(backend.lastBody!['roles'], ['USER']);
      expect(backend.lastBody!['password'], 'Temp@1234');
      // สร้างเสร็จไปหน้ารายการผู้ใช้
      expect(find.text('ค้นหาผู้ใช้แล้วกดปุ่มแก้ไขท้ายแถว'), findsOneWidget);
    },
  );

  testWidgets('ADMIN: กำหนดรหัสผ่านใหม่ให้ผู้ใช้', (tester) async {
    await start(tester);
    await login(tester, 'admin', 'Admin@2569x');
    await tester.tap(find.text('กำหนดรหัสผ่านใหม่'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'กำหนดรหัสผ่าน'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'รหัสผ่านใหม่'),
      'Reset@2570',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ยืนยันรหัสผ่านใหม่'),
      'Reset@2570',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'กำหนดรหัสผ่านใหม่'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'กำหนดรหัสผ่านใหม่'));
    await tester.pumpAndSettle();

    expect(backend.calls, contains('POST /api/admin/users/u1/reset-password'));
    expect(backend.lastBody, {'newPassword': 'Reset@2570'});
  });

  testWidgets('เข้าสู่ระบบค้างไว้ เปิดหน้าเว็บใหม่ยังอยู่ในระบบ', (
    tester,
  ) async {
    await start(tester);
    await login(tester, 'admin', 'Admin@2569x');

    await tester.pumpWidget(const SizedBox.shrink());
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'))
      ..httpClientAdapter = backend;
    await tester.pumpWidget(
      SalApp(
        prefs: prefs,
        api: ApiService(prefs, dio: dio),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('เมนูผู้ใช้งาน'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบเจ้าหน้าที่'), findsNothing);
    // เปิดใหม่แล้วอ่านข้อมูลล่าสุดจาก backend มาแทนค่าที่จำไว้
    expect(backend.calls, contains('GET /api/auth/me'));
    expect(
      find.textContaining('หน่วยงาน 293 ศูนย์สร้างทางขอนแก่น'),
      findsOneWidget,
    );
  });

  Future<void> openEdit(WidgetTester tester) async {
    await start(tester);
    await login(tester, 'admin', 'Admin@2569x');
    await tester.tap(find.text('แก้ไขผู้ใช้งาน'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'แก้ไข'));
    await tester.pumpAndSettle();
  }

  const unsavedTitle = 'ยังไม่ได้บันทึกการแก้ไข';

  testWidgets('แก้ไขผู้ใช้: ไม่ได้แก้อะไร กดปิด (X) แล้วปิดเลย ไม่ถาม', (
    tester,
  ) async {
    await openEdit(tester);
    // เป็นปุ่มปิดรูป X ไม่ใช่ลูกศรย้อนกลับ
    expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    await tester.tap(find.byTooltip('ปิด'));
    await tester.pumpAndSettle();
    expect(find.text(unsavedTitle), findsNothing);
    expect(find.byTooltip('ปิด'), findsNothing);
    expect(find.textContaining('สมชาย ใจดี'), findsOneWidget);
  });

  testWidgets('แก้ไขผู้ใช้: แก้แล้วกดปิด (X) ถามก่อน — แก้ไขต่อ / ไม่บันทึก', (
    tester,
  ) async {
    await openEdit(tester);
    final name = find.widgetWithText(TextFormField, 'ชื่อ-นามสกุล');
    await tester.enterText(name, 'สมชาย แก้ไขแล้ว');
    await tester.tap(find.byTooltip('ปิด'));
    await tester.pumpAndSettle();
    expect(find.text(unsavedTitle), findsOneWidget);

    // กลับไปแก้ไขต่อ: ยังอยู่หน้าเดิม ค่าที่พิมพ์ไม่หาย
    await tester.tap(find.widgetWithText(TextButton, 'กลับไปแก้ไขต่อ'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('ปิด'), findsOneWidget);
    expect(
      tester.widget<TextFormField>(name).controller!.text,
      'สมชาย แก้ไขแล้ว',
    );

    // ไม่บันทึก: กลับรายการ ไม่มีการส่งไป backend
    await tester.tap(find.byTooltip('ปิด'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'ไม่บันทึก'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('ปิด'), findsNothing);
    expect(find.textContaining('สมชาย ใจดี'), findsOneWidget);
    expect(backend.calls, isNot(contains('PUT /api/admin/users/u1')));
  });

  testWidgets('แก้ไขผู้ใช้: แก้แล้วกดยกเลิก เลือกบันทึก = บันทึกแล้วปิด', (
    tester,
  ) async {
    await openEdit(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ชื่อ-นามสกุล'),
      'สมชาย แก้ไขแล้ว',
    );
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'ยกเลิก'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'ยกเลิก'));
    await tester.pumpAndSettle();
    expect(find.text(unsavedTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึก').last);
    await tester.pumpAndSettle();

    expect(backend.calls, contains('PUT /api/admin/users/u1'));
    expect(backend.lastBody!['fullName'], 'สมชาย แก้ไขแล้ว');
    expect(find.byTooltip('ปิด'), findsNothing);
  });

  testWidgets('แก้ไขผู้ใช้: เลือกบันทึกแต่ข้อมูลไม่ผ่าน ยังอยู่หน้าเดิม', (
    tester,
  ) async {
    await openEdit(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ชื่อ-นามสกุล'),
      'ก',
    );
    await tester.tap(find.byTooltip('ปิด'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'บันทึก').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('อย่างน้อย 3 ตัวอักษร'), findsOneWidget);
    expect(find.byTooltip('ปิด'), findsOneWidget);
    expect(backend.calls, isNot(contains('PUT /api/admin/users/u1')));
  });

  testWidgets('แก้ไขค้างไว้แล้วไปเมนูอื่นหรือออกจากระบบ ก็ถามก่อน', (
    tester,
  ) async {
    await openEdit(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ชื่อ-นามสกุล'),
      'สมชาย แก้ไขแล้ว',
    );
    // ไปหน้าอื่นจากปุ่มชื่อผู้ใช้
    await tester.tap(find.byTooltip('บัญชีผู้ใช้'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('หน้าผู้ใช้งาน').last);
    await tester.pumpAndSettle();
    expect(find.text(unsavedTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'กลับไปแก้ไขต่อ'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('ปิด'), findsOneWidget);
    expect(find.text('เมนูผู้ใช้งาน'), findsNothing);

    // ออกจากระบบ: เลือกไม่บันทึกแล้วจึงออก
    await tester.tap(find.byTooltip('บัญชีผู้ใช้'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกจากระบบ').last);
    await tester.pumpAndSettle();
    expect(find.text(unsavedTitle), findsOneWidget);
    expect(prefs.getString('sal_access_token'), isNotNull);
    await tester.tap(find.widgetWithText(OutlinedButton, 'ไม่บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('เข้าสู่ระบบเจ้าหน้าที่'), findsOneWidget);
    expect(backend.calls, isNot(contains('PUT /api/admin/users/u1')));
  });

  testWidgets(
    'สร้างผู้ใช้: กรอกค้างแล้วไปเมนูอื่น ถามก่อน เลือกไม่บันทึกจึงไป',
    (tester) async {
      await start(tester);
      await login(tester, 'admin', 'Admin@2569x');
      await tester.tap(find.text('สร้างผู้ใช้งาน'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ชื่อผู้ใช้'),
        'kk01',
      );
      await tester.tap(find.byTooltip('บัญชีผู้ใช้'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('หน้าผู้ใช้งาน').last);
      await tester.pumpAndSettle();
      expect(find.text(unsavedTitle), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'ไม่บันทึก'));
      await tester.pumpAndSettle();
      expect(find.text('เมนูผู้ใช้งาน'), findsOneWidget);
      expect(backend.calls, isNot(contains('POST /api/admin/users')));
    },
  );

  testWidgets('เปลี่ยนรหัสผ่าน: กรอกค้างแล้วกดยกเลิก ถามก่อน', (tester) async {
    await start(tester);
    await login(tester, 'user291', 'User@2569x');
    await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();

    // ยังไม่กรอกอะไร ยกเลิกแล้วปิดเลย
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'ยกเลิก'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'ยกเลิก'));
    await tester.pumpAndSettle();
    expect(find.text(unsavedTitle), findsNothing);
    expect(find.text('บันทึกรหัสผ่านใหม่'), findsNothing);

    await tester.tap(find.text('เปลี่ยนรหัสผ่าน'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'รหัสผ่านเดิม'),
      'User@2569x',
    );
    await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'ยกเลิก'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'ยกเลิก'));
    await tester.pumpAndSettle();
    expect(find.text(unsavedTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'ไม่บันทึก'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'รหัสผ่านเดิม'), findsNothing);
    expect(backend.calls, isNot(contains('POST /api/auth/changepassword')));
  });

  testWidgets(
    'กำหนดรหัสผ่านใหม่: กรอกค้างแล้วกดยกเลิก เลือกบันทึก = ส่งไป backend',
    (tester) async {
      await start(tester);
      await login(tester, 'admin', 'Admin@2569x');
      await tester.tap(find.text('กำหนดรหัสผ่านใหม่'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'กำหนดรหัสผ่าน'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'รหัสผ่านใหม่'),
        'Reset@2570',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ยืนยันรหัสผ่านใหม่'),
        'Reset@2570',
      );
      await tester.ensureVisible(find.widgetWithText(OutlinedButton, 'ยกเลิก'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'ยกเลิก'));
      await tester.pumpAndSettle();
      expect(find.text(unsavedTitle), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, 'กำหนดรหัสผ่านใหม่').last,
      );
      await tester.pumpAndSettle();
      expect(
        backend.calls,
        contains('POST /api/admin/users/u1/reset-password'),
      );
      expect(find.widgetWithText(TextFormField, 'รหัสผ่านใหม่'), findsNothing);
    },
  );

  testWidgets('หลังเข้าสู่ระบบ แจ้งว่าบัญชีใช้งานได้ทีละเครื่อง', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('เข้าสู่ระบบเจ้าหน้าที่'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ชื่อผู้ใช้'),
      'user291',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'รหัสผ่าน'),
      'User@2569x',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();

    expect(find.text('ใช้งานได้ทีละเครื่อง'), findsOneWidget);
    expect(
      find.textContaining('เครื่องนี้จะถูกออกจากระบบโดยอัตโนมัติ'),
      findsWidgets,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'รับทราบ'));
    await tester.pumpAndSettle();
    expect(find.text('ใช้งานได้ทีละเครื่อง'), findsNothing);
    // ข้อความเดียวกันยังอยู่ในหน้าผู้ใช้งานให้อ่านซ้ำได้
    expect(find.textContaining('บัญชีนี้ใช้งานได้ทีละเครื่อง'), findsOneWidget);
  });

  testWidgets(
    'ถูกบังคับเปลี่ยนรหัสผ่านก่อน แล้วจึงแจ้งเรื่องใช้งานทีละเครื่อง',
    (tester) async {
      await start(tester);
      await tester.tap(find.text('เข้าสู่ระบบเจ้าหน้าที่'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ชื่อผู้ใช้'),
        'newbie',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'รหัสผ่าน'),
        'Temp@1234',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
      await tester.pumpAndSettle();

      expect(find.text('ต้องเปลี่ยนรหัสผ่านก่อนใช้งานต่อ'), findsOneWidget);
      expect(find.text('ใช้งานได้ทีละเครื่อง'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'รหัสผ่านเดิม'),
        'Temp@1234',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'รหัสผ่านใหม่'),
        'NewPass@2570',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ยืนยันรหัสผ่านใหม่'),
        'NewPass@2570',
      );
      await tester.ensureVisible(find.text('บันทึกรหัสผ่านใหม่'));
      await tester.tap(find.text('บันทึกรหัสผ่านใหม่'));
      await tester.pumpAndSettle();
      expect(find.text('ใช้งานได้ทีละเครื่อง'), findsOneWidget);
    },
  );

  testWidgets('ถูกเข้าสู่ระบบจากเครื่องอื่น: เครื่องนี้หลุดและบอกเหตุผล', (
    tester,
  ) async {
    await start(tester);
    await login(tester, 'admin', 'Admin@2569x');
    backend.kicked = true;
    await tester.tap(find.text('แก้ไขผู้ใช้งาน'));
    await tester.pumpAndSettle();

    expect(find.text('เข้าสู่ระบบเจ้าหน้าที่'), findsOneWidget);
    expect(prefs.getString('sal_access_token'), isNull);
    expect(
      find.textContaining('มีการเข้าสู่ระบบด้วยบัญชีนี้จากเครื่องอื่น'),
      findsOneWidget,
    );
  });

  testWidgets('บัญชีถูกล็อกชั่วคราว: หน้าเข้าสู่ระบบบอกเวลาที่ต้องรอ', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('เข้าสู่ระบบเจ้าหน้าที่'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ชื่อผู้ใช้'),
      'locked',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'รหัสผ่าน'), 'x');
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('กรุณาลองใหม่ในอีก 10 นาที'), findsOneWidget);
    expect(find.text('ใช้งานได้ทีละเครื่อง'), findsNothing);
  });
}
