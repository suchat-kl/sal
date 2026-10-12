import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sal/config/theme.dart';
import 'package:sal/main.dart';
import 'package:sal/models/announcement.dart';
import 'package:sal/screens/announcement_form_screen.dart';
import 'package:sal/screens/announcement_list_screen.dart';
import 'package:sal/services/api_service.dart';
import 'package:sal/utils/thai_date.dart';
import 'package:sal/widgets/home_announcements.dart';
import 'package:sal/widgets/linked_text.dart';
import 'package:sal/widgets/payroll_illustration.dart';
import 'package:sal/widgets/sidebar_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String groupUrl = 'https://www.facebook.com/groups/saldoh';

/// backend จำลองของส่วนประกาศ ตอบตามสัญญา API ของ Spring Boot `salary`
class FakeAnnouncements implements HttpClientAdapter {
  final List<String> calls = [];

  /// query ของ GET /api/admin/announcements ทุกครั้งที่ถูกเรียก
  final List<Map<String, dynamic>> queries = [];

  /// (method path, body) ของ POST/PUT ที่ส่งมา
  final List<(String, Map<String, dynamic>)> saved = [];

  /// ค่า Authorization ของแต่ละครั้งที่เรียกเส้นสาธารณะ (ต้องเป็น null เสมอ)
  final List<Object?> activeAuthHeaders = [];

  /// ประกาศที่ยังมีผล (เส้นสาธารณะ)
  List<Map<String, dynamic>> active = [
    {
      'id': 'a1',
      'title': 'กำหนดส่งเอกสารลดหย่อนภาษี',
      'message':
          'ส่งเอกสารได้ที่ฝ่ายบัญชี\nสอบถามเพิ่มเติมที่กลุ่ม ($groupUrl) ได้ทุกวัน',
      'startDate': '2026-10-12',
      'stopDate': '2026-10-16',
      'sequence': 0,
    },
    {
      'id': 'a2',
      'title': 'ปิดปรับปรุงระบบ',
      'message': 'งดใช้งานชั่วคราว',
      'startDate': null,
      'stopDate': null,
      'sequence': 1,
    },
  ];

  /// สถานะที่เส้นสาธารณะตอบ (500 = จำลอง backend ล่ม)
  int activeStatus = 200;

  /// รายการในหน้าจัดการ
  List<Map<String, dynamic>> all = [
    {
      'id': 'a1',
      'title': 'กำหนดส่งเอกสารลดหย่อนภาษี',
      'message': 'ส่งเอกสารได้ที่ฝ่ายบัญชี',
      'startDate': '2026-10-12',
      'stopDate': '2026-10-16',
      'sequence': 2,
      'status': '1',
      'createdBy': 'admin',
    },
    {
      'id': 'a2',
      'title': 'ปิดปรับปรุงระบบ',
      'message': 'งดใช้งานชั่วคราว',
      'startDate': null,
      'stopDate': null,
      'sequence': 1,
      'status': '1',
      'createdBy': 'admin',
    },
    {
      'id': 'a3',
      'title': 'ประกาศเก่าที่ปิดแล้ว',
      // เนื้อความว่าง backend ส่งเป็น null
      'message': null,
      'createdAt': '2026-10-12T09:30:00',
      'updatedAt': '2026-10-12T09:30:00',
      'startDate': null,
      'stopDate': null,
      'sequence': 0,
      'status': '2',
      'createdBy': 'admin',
    },
  ];

  /// backend จริงตอบชื่อช่องแบบเดียวกับ /api/admin/users (announcements + totalItems)
  /// true = ตอบแบบสัญญาฉบับแรก (items + total) ซึ่งตัวอ่านยังรับได้
  bool contractStyle = false;

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
    final method = options.method;
    calls.add('$method $path');
    final data = options.data;
    final body = data is Map ? Map<String, dynamic>.from(data) : null;

    if (path == '/api/announcements/active') {
      activeAuthHeaders.add(options.headers['Authorization']);
      if (activeStatus != 200) {
        return _json(activeStatus, {'success': false, 'message': 'ล่ม'});
      }
      return _json(200, active);
    }
    if (path == '/api/auth/login') {
      final user = body!['username'] as String;
      return _json(200, {
        'access_token': 'access-$user',
        'refresh_token': 'refresh-$user',
        'username': user,
        'full_name': 'ผู้ใช้ $user',
        'div': '060',
        'div_name': 'ศูนย์เทคโนโลยีสารสนเทศ',
        'roles': [
          user == 'admin'
              ? 'ADMIN'
              : user.startsWith('upload')
              ? 'UPLOAD'
              : 'USER',
        ],
      });
    }
    if (path == '/api/auth/refresh-token') {
      return _json(403, {'success': false, 'message': 'กรุณาเข้าสู่ระบบใหม่'});
    }
    if (options.headers['Authorization'] == null) {
      return ResponseBody.fromString('', 401); // backend จริงตอบ 401 body ว่าง
    }
    if (path == '/api/admin/announcements' && method == 'GET') {
      final q = Map<String, dynamic>.from(options.queryParameters);
      queries.add(q);
      final title = (q['title'] ?? '').toString();
      final status = q['status']?.toString();
      final rows = [
        for (final a in all)
          if ((a['title'] as String).contains(title) &&
              (status == null || a['status'] == status))
            a,
      ];
      final page = q['page'] as int;
      final size = q['size'] as int;
      final items = rows.skip(page * size).take(size).toList();
      return _json(
        200,
        contractStyle
            ? {'items': items, 'total': rows.length, 'page': page, 'size': size}
            : {
                'announcements': items,
                'currentPage': page,
                'totalItems': rows.length,
                'totalPages': (rows.length / size).ceil(),
                'pageSize': size,
                'success': true,
              },
      );
    }
    if (path.startsWith('/api/admin/announcements')) {
      // ไม่พบ id ตอน PUT/DELETE: backend ตอบ 400 (ไม่ใช่ 404)
      final id = path.split('/').last;
      if (method != 'POST' && !all.any((a) => a['id'] == id)) {
        return _json(400, {
          'success': false,
          'status': 400,
          'message': 'ไม่พบประกาศ ID: $id',
        });
      }
      if (method == 'DELETE') {
        all.removeWhere((a) => a['id'] == id);
        return _json(200, {'message': 'ลบข้อมูลสำเร็จ', 'success': true});
      }
      saved.add(('$method $path', body!));
      if ((body['title'] as String).contains('ซ้ำ')) {
        return _json(400, {
          'success': false,
          'status': 400,
          'message': 'มีประกาศหัวเรื่องนี้อยู่แล้ว',
        });
      }
      return _json(200, {
        'announcement': {...body, 'id': 'new'},
        'message': method == 'POST'
            ? 'บันทึกข้อมูลสำเร็จ'
            : 'อัปเดตข้อมูลสำเร็จ',
        'success': true,
      });
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

void main() {
  setUpAll(_loadFonts);

  late FakeAnnouncements backend;
  late SharedPreferences prefs;
  late ApiService api;

  setUp(() => backend = FakeAnnouncements());

  Future<void> makeApi([Map<String, Object> stored = const {}]) async {
    SharedPreferences.setMockInitialValues(stored);
    prefs = await SharedPreferences.getInstance();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'))
      ..httpClientAdapter = backend;
    api = ApiService(prefs, dio: dio);
  }

  void setView(WidgetTester tester, [double width = 1400]) {
    tester.view.physicalSize = Size(width, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  /// เปิดแอปทั้งตัว (ยังไม่เข้าสู่ระบบ = อยู่หน้าแรก)
  Future<void> start(WidgetTester tester, {double width = 1400}) async {
    setView(tester, width);
    await makeApi();
    await tester.pumpWidget(SalApp(prefs: prefs, api: api));
    await tester.pumpAndSettle();
  }

  Future<void> login(WidgetTester tester, String user) async {
    await tester.tap(find.text('เข้าสู่ระบบเจ้าหน้าที่'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'ชื่อผู้ใช้'),
      user,
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'รหัสผ่าน'), 'x');
    await tester.tap(find.widgetWithText(FilledButton, 'เข้าสู่ระบบ'));
    await tester.pumpAndSettle();
  }

  /// ADMIN เข้าสู่ระบบแล้วเปิดหน้าจัดการประกาศ
  Future<void> openAdmin(WidgetTester tester) async {
    await start(tester);
    await login(tester, 'admin');
    await tester.tap(find.text('ประกาศ'));
    await tester.pumpAndSettle();
    expect(find.byType(AnnouncementListScreen), findsOneWidget);
  }

  Future<void> tapVisible(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) =>
      tapVisible(tester, find.widgetWithText(FilledButton, 'บันทึก'));

  /// เปิดปฏิทินของช่องที่แสดงข้อความ [fieldText] แล้วเลือกวันที่ [day] ของเดือนที่ปฏิทินเปิดอยู่
  Future<void> pickDay(WidgetTester tester, String fieldText, int day) async {
    await tapVisible(tester, find.text(fieldText));
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('$day'),
      ),
    );
    await tester.pumpAndSettle();
  }

  final now = DateTime.now();
  String isoDay(int day) => toIsoDate(DateTime(now.year, now.month, day))!;

  // ---------------- ตัวช่วย ----------------

  test('ช่วงวันที่ไทย พ.ศ. ย่อส่วนที่ซ้ำกัน', () {
    final d = DateTime.new;
    expect(
      formatThaiDateRange(d(2026, 10, 12), d(2026, 10, 16)),
      '12 - 16 ตุลาคม 2569',
    );
    expect(
      formatThaiDateRange(d(2026, 10, 28), d(2026, 11, 3)),
      '28 ตุลาคม - 3 พฤศจิกายน 2569',
    );
    expect(
      formatThaiDateRange(d(2026, 12, 28), d(2027, 1, 3)),
      '28 ธันวาคม 2569 - 3 มกราคม 2570',
    );
    expect(
      formatThaiDateRange(d(2026, 10, 12), d(2026, 10, 12)),
      '12 ตุลาคม 2569',
    );
    expect(
      formatThaiDateRange(d(2026, 10, 12), null),
      'ตั้งแต่ 12 ตุลาคม 2569',
    );
    expect(formatThaiDateRange(null, d(2026, 10, 16)), 'ถึง 16 ตุลาคม 2569');
    expect(formatThaiDateRange(null, null), '');
    expect(toIsoDate(d(2026, 1, 5)), '2026-01-05');
    expect(toIsoDate(null), isNull);
    expect(parseIsoDate('2026-10-12'), d(2026, 10, 12));
    expect(parseIsoDate('ไม่ใช่วันที่'), isNull);
  });

  test('ตัดลิงก์ในเนื้อความ: ไม่รวมวงเล็บปิดและเครื่องหมายท้ายประโยค', () {
    List<String> links(String s) => [
      for (final p in splitLinks(s))
        if (p.isLink) p.text,
    ];
    expect(links('ดูที่กลุ่ม ($groupUrl) ได้เลย'), [groupUrl]);
    // ต่อกลับแล้วได้ข้อความเดิมครบทุกตัวอักษร
    const text = 'ก ($groupUrl) ข\nhttp://a.example/x.pdf.';
    expect(splitLinks(text).map((p) => p.text).join(), text);
    expect(links(text), [groupUrl, 'http://a.example/x.pdf']);
    // วงเล็บที่เป็นส่วนของ URL เอง (เปิด-ปิดครบคู่) ยังอยู่
    expect(links('https://th.wikipedia.org/wiki/A_(b) จบ'), [
      'https://th.wikipedia.org/wiki/A_(b)',
    ]);
    expect(links('[https://a.example/q?x=1&y=2], "https://b.example"'), [
      'https://a.example/q?x=1&y=2',
      'https://b.example',
    ]);
    // ตัวอักษรไทยที่พิมพ์ติดกันไม่ใช่ส่วนของลิงก์
    expect(links('https://a.example/docครับ'), ['https://a.example/doc']);
    expect(links('ไม่มีลิงก์ www.example.com และ https:// เฉย ๆ'), isEmpty);
  });

  test('ประกาศ "กำลังแสดง" เมื่อสถานะใช้งานและวันนี้อยู่ในช่วง', () {
    final today = DateTime(2026, 10, 12);
    Announcement a({String? start, String? stop, String status = '1'}) =>
        Announcement.fromJson({
          'id': 1,
          'title': 't',
          'startDate': start,
          'stopDate': stop,
          'status': status,
        });
    expect(a().isShowing(today), isTrue);
    expect(a(start: '2026-10-12', stop: '2026-10-12').isShowing(today), isTrue);
    expect(a(start: '2026-10-13').isShowing(today), isFalse);
    expect(a(stop: '2026-10-11').isShowing(today), isFalse);
    expect(a(status: '2').isShowing(today), isFalse);
    // id เป็นตัวเลขก็อ่านได้
    expect(a().id, '1');
  });

  // ---------------- (ก) หน้าแรก ----------------

  testWidgets(
    'หน้าแรกแสดงประกาศใต้ภาพหัว: หัวเรื่อง เนื้อความหลายบรรทัด ช่วงวันที่ไทย',
    (tester) async {
      await start(tester);

      expect(find.text('ประกาศ'), findsOneWidget);
      expect(find.text('กำหนดส่งเอกสารลดหย่อนภาษี'), findsOneWidget);
      expect(find.text('ปิดปรับปรุงระบบ'), findsOneWidget);
      // การขึ้นบรรทัดใหม่ในเนื้อความยังอยู่
      expect(
        find.textContaining(
          'ส่งเอกสารได้ที่ฝ่ายบัญชี\nสอบถามเพิ่มเติมที่กลุ่ม',
          findRichText: true,
        ),
        findsOneWidget,
      );
      expect(find.text('ประกาศ 12 - 16 ตุลาคม 2569'), findsOneWidget);
      // ประกาศที่ไม่กำหนดช่วงวันที่ไม่มีบรรทัดวันที่
      expect(find.textContaining('ประกาศ ตั้งแต่'), findsNothing);

      // อยู่ใต้ภาพหัว เหนือทางลัด เรียงตามที่ backend ส่ง และเห็นได้โดยไม่ต้องเลื่อน
      double top(Finder f) => tester.getTopLeft(f).dy;
      final first = top(find.text('กำหนดส่งเอกสารลดหย่อนภาษี'));
      final second = top(find.text('ปิดปรับปรุงระบบ'));
      expect(
        first,
        greaterThan(tester.getBottomLeft(find.byType(PayrollIllustration)).dy),
      );
      expect(second, greaterThan(first));
      expect(top(find.text('บริการทั้งหมด')), greaterThan(second));
      expect(first, lessThan(1000));

      // ยังไม่เข้าสู่ระบบก็โหลดได้ และไม่แนบ token
      expect(backend.activeAuthHeaders, [null]);
    },
  );

  testWidgets('ประกาศไม่ล้นจอแคบ (มือถือ)', (tester) async {
    await start(tester, width: 380);
    // pumpAndSettle จะล้มเองถ้ามี RenderFlex overflow
    expect(find.text('กำหนดส่งเอกสารลดหย่อนภาษี'), findsOneWidget);
  });

  testWidgets('ลิงก์ในเนื้อความกดได้ เปิดด้วย URL ที่ไม่รวมวงเล็บปิด', (
    tester,
  ) async {
    setView(tester);
    await makeApi();
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(null),
        home: Scaffold(
          body: SingleChildScrollView(
            child: HomeAnnouncements(
              api: api,
              onOpenLink: (_, url) async => opened.add(url),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapOnText(find.textRange.ofSubstring(groupUrl));
    await tester.pumpAndSettle();
    expect(opened, [groupUrl]);

    // กดข้อความธรรมดาไม่เปิดอะไร
    await tester.tapOnText(find.textRange.ofSubstring('ส่งเอกสารได้ที่'));
    await tester.pumpAndSettle();
    expect(opened, [groupUrl]);
  });

  testWidgets('ไม่มีประกาศ = ไม่มีส่วนประกาศและไม่กินที่', (tester) async {
    backend.active = [];
    await start(tester);

    expect(find.text('ประกาศ'), findsNothing);
    expect(tester.getSize(find.byType(HomeAnnouncements)).height, 0);
    expect(find.text('บริการทั้งหมด'), findsOneWidget);
  });

  testWidgets('โหลดประกาศล้ม = ไม่มีส่วนประกาศ ไม่มีข้อความผิดพลาด', (
    tester,
  ) async {
    backend.activeStatus = 500;
    await start(tester);

    expect(find.text('ประกาศ'), findsNothing);
    expect(tester.getSize(find.byType(HomeAnnouncements)).height, 0);
    expect(find.textContaining('เกิดข้อผิดพลาด'), findsNothing);
    expect(find.textContaining('ล่ม'), findsNothing);
    expect(find.text('บริการทั้งหมด'), findsOneWidget);
  });

  test(
    'เส้นประกาศไม่แนบ token ที่ค้างในเบราว์เซอร์ และโดน 401 ก็ไม่พาออกจากระบบ',
    () async {
      await makeApi({
        'sal_access_token': 'expired',
        'sal_refresh_token': 'old',
        'sal_session': jsonEncode({
          'username': 'admin',
          'full_name': 'ผู้ใช้ admin',
          'roles': ['ADMIN'],
        }),
      });
      var expired = false;
      api.onSessionExpired = () => expired = true;

      expect((await api.activeAnnouncements()).length, 2);
      expect(backend.activeAuthHeaders, [null]);

      // backend ตอบ 401 ให้เส้นนี้: ไม่ต่ออายุ token ไม่ล้าง session
      backend.activeStatus = 401;
      await expectLater(
        api.activeAnnouncements(),
        throwsA(isA<ApiException>()),
      );
      expect(backend.calls, isNot(contains('POST /api/auth/refresh-token')));
      expect(expired, isFalse);
      expect(api.session, isNotNull);
      expect(prefs.getString('sal_access_token'), 'expired');
    },
  );

  // ---------------- (ข) หน้าจัดการประกาศ ----------------

  testWidgets('เมนูประกาศเห็นเฉพาะ UPLOAD และ ADMIN', (tester) async {
    await start(tester);
    await login(tester, 'user291');
    expect(find.text('เมนูผู้ใช้งาน'), findsOneWidget);
    expect(find.text('ประกาศ'), findsNothing);

    // งานเงินเดือน (UPLOAD) เขียนประกาศเองได้
    await tester.tap(find.byTooltip('บัญชีผู้ใช้'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกจากระบบ').last);
    await tester.pumpAndSettle();
    await login(tester, 'upload1');
    expect(find.text('ประกาศ'), findsOneWidget);

    await tester.tap(find.byTooltip('บัญชีผู้ใช้'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ออกจากระบบ').last);
    await tester.pumpAndSettle();
    await login(tester, 'admin');
    expect(find.text('ประกาศ'), findsOneWidget);
    await tester.tap(find.byTooltip('ขยายเมนู'));
    await tester.pumpAndSettle();
    // การ์ดในหน้าผู้ใช้งาน + เมนูข้าง
    expect(find.text('ประกาศ'), findsNWidgets(2));
  });

  testWidgets('รายการ: แสดงหัวเรื่อง ช่วงวันที่ ลำดับ สถานะ และป้ายกำลังแสดง', (
    tester,
  ) async {
    await openAdmin(tester);

    expect(backend.queries.single, {'page': 0, 'size': 10});
    expect(find.text('กำหนดส่งเอกสารลดหย่อนภาษี'), findsOneWidget);
    expect(
      find.text('ช่วงวันที่: 12 - 16 ตุลาคม 2569   ·   ลำดับ 2'),
      findsOneWidget,
    );
    expect(find.text('ช่วงวันที่: ไม่กำหนด   ·   ลำดับ 1'), findsOneWidget);
    // ตัวกรอง "ใช้งาน"/"ไม่ใช้งาน" 1 + ป้ายสถานะในแถว
    expect(find.text('ใช้งาน'), findsNWidgets(3));
    expect(find.text('ไม่ใช้งาน'), findsNWidgets(2));
    // a2 ใช้งานและไม่กำหนดช่วง = กำลังแสดงเสมอ, a3 ไม่ใช้งาน = ไม่แสดง
    // a1 ขึ้นกับวันนี้ว่าอยู่ใน 12-16 ต.ค. 2569 หรือไม่
    final a1Showing = Announcement.fromJson(backend.all[0]).isShowing();
    expect(find.text('กำลังแสดง'), findsNWidgets(a1Showing ? 2 : 1));
    expect(find.textContaining('แสดง 1-3 จาก 3 รายการ'), findsOneWidget);
  });

  testWidgets('ค้นหัวเรื่อง กรองสถานะ แบ่งหน้า ส่ง query ถูก', (tester) async {
    backend.all = [
      for (var i = 1; i <= 12; i++)
        {
          'id': 'n$i',
          'title': 'ประกาศที่ $i',
          'message': '',
          'startDate': null,
          'stopDate': null,
          'sequence': i,
          'status': i.isEven ? '2' : '1',
        },
    ];
    await openAdmin(tester);
    expect(find.textContaining('แสดง 1-10 จาก 12 รายการ'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('ถัดไป'));
    expect(backend.queries.last, {'page': 1, 'size': 10});
    expect(find.text('ประกาศที่ 11'), findsOneWidget);
    expect(find.text('ประกาศที่ 1'), findsNothing);

    // กรองสถานะ: กลับไปหน้าแรก
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'ไม่ใช้งาน'));
    expect(backend.queries.last, {'page': 0, 'size': 10, 'status': '2'});
    expect(find.textContaining('จาก 6 รายการ'), findsOneWidget);

    // ค้นหัวเรื่อง (รอหน่วงเวลาพิมพ์) ตัดช่องว่างหัวท้าย
    await tester.enterText(find.widgetWithText(TextField, 'ค้นหา'), ' ที่ 12 ');
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pumpAndSettle();
    expect(backend.queries.last, {
      'page': 0,
      'size': 10,
      'title': 'ที่ 12',
      'status': '2',
    });
    expect(find.text('ประกาศที่ 12'), findsOneWidget);
    expect(find.text('ประกาศที่ 2'), findsNothing);

    // กลับเป็นทั้งหมด = ไม่ส่ง status, ล้างคำค้น = ไม่ส่ง title
    await tapVisible(tester, find.widgetWithText(ChoiceChip, 'ทั้งหมด'));
    expect(backend.queries.last, {'page': 0, 'size': 10, 'title': 'ที่ 12'});
    await tapVisible(tester, find.byTooltip('ล้างคำค้น'));
    expect(backend.queries.last, {'page': 0, 'size': 10});

    // เปลี่ยนแถวต่อหน้า
    await tapVisible(tester, find.byType(DropdownButton<int>));
    await tester.tap(find.text('5').last);
    await tester.pumpAndSettle();
    expect(backend.queries.last, {'page': 0, 'size': 5});
    expect(find.textContaining('แสดง 1-5 จาก 12 รายการ'), findsOneWidget);
  });

  testWidgets('อ่าน response แบบสัญญาฉบับแรกได้ด้วย (items + total)', (
    tester,
  ) async {
    backend.contractStyle = true;
    await openAdmin(tester);
    expect(find.text('ปิดปรับปรุงระบบ'), findsOneWidget);
    expect(find.textContaining('แสดง 1-3 จาก 3 รายการ'), findsOneWidget);
  });

  testWidgets(
    'เพิ่มประกาศ: ฟอร์มเป็นหน้าจอ (ไม่ใช่ dialog) ส่งวันที่ yyyy-MM-dd ค.ศ.',
    (tester) async {
      await openAdmin(tester);
      await tapVisible(tester, find.text('เพิ่มประกาศ'));

      expect(find.byType(AnnouncementFormScreen), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      // มีคำอธิบายว่าเว้นวันที่ว่างหมายถึงอะไร และตัวนับตัวอักษร
      expect(find.textContaining('เว้นวันที่เริ่มว่าง = แสดงทันที'), findsOne);
      expect(find.text('0/200'), findsOneWidget);
      expect(find.text('0/2000'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'หัวเรื่อง'),
        'ประกาศใหม่',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'เนื้อความ'),
        'บรรทัดหนึ่ง\nบรรทัดสอง',
      );
      await tester.pump();
      // นับแบบเดียวกับ backend (หน่วย UTF-16) สระ/วรรณยุกต์ไทยนับด้วย
      expect(find.text('21/2000'), findsOneWidget);
      expect(find.text('10/200'), findsOneWidget);
      await pickDay(tester, 'ไม่กำหนด (แสดงทันที)', 10);
      await pickDay(tester, 'ไม่กำหนด (ไม่หมดอายุ)', 15);
      // ช่องแสดงวันที่ไทย พ.ศ.
      expect(
        find.text(formatThaiDate(DateTime(now.year, now.month, 10))),
        findsOneWidget,
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ลำดับการแสดง'),
        '3',
      );
      await save(tester);

      final (call, body) = backend.saved.single;
      expect(call, 'POST /api/admin/announcements');
      expect(body, {
        'title': 'ประกาศใหม่',
        'message': 'บรรทัดหนึ่ง\nบรรทัดสอง',
        'startDate': isoDay(10),
        'stopDate': isoDay(15),
        'sequence': 3,
        'status': '1',
      });
      // กลับหน้ารายการ โหลดใหม่ และแจ้งข้อความของ backend
      expect(find.byType(AnnouncementFormScreen), findsNothing);
      expect(find.text('บันทึกข้อมูลสำเร็จ'), findsOneWidget);
      expect(backend.queries.length, 2);
    },
  );

  testWidgets('แก้ไขประกาศ: ล้างวันที่ = null และเปลี่ยนสถานะ ส่ง PUT ถูก', (
    tester,
  ) async {
    await openAdmin(tester);
    await tapVisible(tester, find.byTooltip('แก้ไข').first);

    expect(find.text('แก้ไขประกาศ'), findsOneWidget);
    // ค่าเดิมถูกเติมมาให้ วันที่เป็นไทย พ.ศ.
    expect(
      find.widgetWithText(TextFormField, 'กำหนดส่งเอกสารลดหย่อนภาษี'),
      findsOneWidget,
    );
    expect(find.text('12 ตุลาคม 2569'), findsOneWidget);
    expect(find.text('16 ตุลาคม 2569'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('ล้างวันที่เริ่มประกาศ'));
    await tapVisible(tester, find.byTooltip('ล้างวันที่สิ้นสุด'));
    expect(find.text('ไม่กำหนด (แสดงทันที)'), findsOneWidget);
    expect(find.text('ไม่กำหนด (ไม่หมดอายุ)'), findsOneWidget);
    await tapVisible(tester, find.byType(Switch));
    expect(find.text('สถานะ: ไม่ใช้งาน'), findsOneWidget);
    await save(tester);

    final (call, body) = backend.saved.single;
    expect(call, 'PUT /api/admin/announcements/a1');
    expect(body, {
      'title': 'กำหนดส่งเอกสารลดหย่อนภาษี',
      'message': 'ส่งเอกสารได้ที่ฝ่ายบัญชี',
      'startDate': null,
      'stopDate': null,
      'sequence': 2,
      'status': '2',
    });
    expect(find.text('อัปเดตข้อมูลสำเร็จ'), findsOneWidget);
    expect(find.byType(AnnouncementListScreen), findsOneWidget);
    expect(backend.queries.length, 2);
  });

  testWidgets('ลบประกาศ: ต้องยืนยันก่อน แล้วรายการโหลดใหม่', (tester) async {
    await openAdmin(tester);

    await tapVisible(tester, find.byTooltip('ลบ').first);
    expect(find.textContaining('ต้องการลบประกาศ "กำหนดส่ง'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'ยกเลิก'));
    await tester.pumpAndSettle();
    expect(backend.calls.where((c) => c.startsWith('DELETE')), isEmpty);
    expect(find.text('กำหนดส่งเอกสารลดหย่อนภาษี'), findsOneWidget);

    await tapVisible(tester, find.byTooltip('ลบ').first);
    await tester.tap(find.widgetWithText(FilledButton, 'ลบประกาศ'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('DELETE /api/admin/announcements/a1'));
    expect(find.text('ลบข้อมูลสำเร็จ'), findsOneWidget);
    expect(find.text('กำหนดส่งเอกสารลดหย่อนภาษี'), findsNothing);
    expect(find.textContaining('จาก 2 รายการ'), findsOneWidget);
    expect(backend.queries.length, 2);
  });

  testWidgets('ลบรายการที่ไม่มีแล้ว: แสดง message 400 ของ backend', (
    tester,
  ) async {
    await openAdmin(tester);
    backend.all.removeAt(0); // มีคนลบไปก่อนแล้ว
    await tapVisible(tester, find.byTooltip('ลบ').first);
    await tester.tap(find.widgetWithText(FilledButton, 'ลบประกาศ'));
    await tester.pumpAndSettle();
    expect(find.text('ไม่พบประกาศ ID: a1'), findsOneWidget);
  });

  testWidgets(
    'แก้ไขประกาศที่เนื้อความเป็น null: ฟอร์มเปิดได้ ส่งเนื้อความว่าง',
    (tester) async {
      await openAdmin(tester);
      await tapVisible(tester, find.byTooltip('แก้ไข').last);
      expect(find.text('0/2000'), findsOneWidget);
      expect(find.text('สถานะ: ไม่ใช้งาน'), findsOneWidget);
      await tapVisible(tester, find.byType(Switch));
      await save(tester);
      final (call, body) = backend.saved.single;
      expect(call, 'PUT /api/admin/announcements/a3');
      expect(body['message'], '');
      expect(body['status'], '1');
    },
  );

  testWidgets(
    'ตรวจฟอร์ม: หัวเรื่องว่าง และวันที่สิ้นสุดก่อนวันที่เริ่ม ไม่ส่งไป backend',
    (tester) async {
      await openAdmin(tester);
      await tapVisible(tester, find.text('เพิ่มประกาศ'));

      await save(tester);
      expect(find.text('กรุณากรอกหัวเรื่อง'), findsOneWidget);
      expect(backend.saved, isEmpty);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'หัวเรื่อง'),
        'ประกาศ',
      );
      await pickDay(tester, 'ไม่กำหนด (แสดงทันที)', 15);
      await pickDay(tester, 'ไม่กำหนด (ไม่หมดอายุ)', 10);
      await save(tester);
      expect(find.text('กรุณากรอกหัวเรื่อง'), findsNothing);
      expect(
        find.text('วันที่สิ้นสุดต้องไม่ก่อนวันที่เริ่มประกาศ'),
        findsOneWidget,
      );
      expect(backend.saved, isEmpty);

      // ลำดับว่าง = ไม่ผ่าน
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ลำดับการแสดง'),
        '',
      );
      await save(tester);
      expect(
        find.textContaining('กรุณากรอกลำดับเป็นจำนวนเต็ม'),
        findsOneWidget,
      );
      expect(backend.saved, isEmpty);

      // แก้วันที่สิ้นสุดให้ไม่ก่อนวันเริ่ม (วันเดียวกันได้) แล้วบันทึกผ่าน
      await tester.enterText(
        find.widgetWithText(TextFormField, 'ลำดับการแสดง'),
        '0',
      );
      await pickDay(
        tester,
        formatThaiDate(DateTime(now.year, now.month, 10)),
        15,
      );
      await save(tester);
      expect(backend.saved.single.$2['startDate'], isoDay(15));
      expect(backend.saved.single.$2['stopDate'], isoDay(15));
    },
  );

  testWidgets('backend ตอบ 400: แสดง message ของ backend และยังอยู่ที่ฟอร์ม', (
    tester,
  ) async {
    await openAdmin(tester);
    await tapVisible(tester, find.text('เพิ่มประกาศ'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'หัวเรื่อง'),
      'หัวเรื่องซ้ำ',
    );
    await save(tester);

    expect(find.text('มีประกาศหัวเรื่องนี้อยู่แล้ว'), findsOneWidget);
    expect(find.byType(AnnouncementFormScreen), findsOneWidget);
    // ยังไม่ได้กลับไปโหลดรายการ
    expect(backend.queries.length, 1);
  });

  testWidgets('ฟอร์มมีการแก้ไขค้าง กดปิดแล้วถามก่อน', (tester) async {
    await openAdmin(tester);
    await tapVisible(tester, find.text('เพิ่มประกาศ'));

    // ยังไม่แก้อะไร ปิดได้เลย
    await tapVisible(tester, find.byTooltip('ปิด'));
    expect(find.byType(AnnouncementFormScreen), findsNothing);

    await tapVisible(tester, find.text('เพิ่มประกาศ'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'หัวเรื่อง'),
      'ค้างไว้',
    );
    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'ยกเลิก'));
    expect(find.text('ยังไม่ได้บันทึกการแก้ไข'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'ไม่บันทึก'));
    await tester.pumpAndSettle();
    expect(find.byType(AnnouncementFormScreen), findsNothing);
    expect(backend.saved, isEmpty);
  });

  testWidgets('บันทึกแล้วกลับหน้าแรก: โหลดประกาศใหม่อีกครั้ง', (tester) async {
    await openAdmin(tester);
    expect(backend.activeAuthHeaders.length, 1);

    backend.active = [
      {
        'id': 'a9',
        'title': 'ประกาศล่าสุด',
        'message': '',
        'startDate': null,
        'stopDate': null,
        'sequence': 0,
      },
    ];
    await tester.tap(
      find.descendant(
        of: find.byType(SidebarMenu),
        matching: find.byTooltip('หน้าแรก'),
      ),
    );
    await tester.pumpAndSettle();

    // เข้าสู่ระบบอยู่ก็ยังไม่แนบ token ให้เส้นสาธารณะ
    expect(backend.activeAuthHeaders, [null, null]);
    expect(find.text('ประกาศล่าสุด'), findsOneWidget);
    expect(find.text('กำหนดส่งเอกสารลดหย่อนภาษี'), findsNothing);
  });
}
