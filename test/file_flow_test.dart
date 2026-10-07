import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sal/config/features.dart';
import 'package:sal/main.dart';
import 'package:sal/services/api_service.dart';
import 'package:sal/utils/file_pick.dart';
import 'package:sal/utils/file_saver.dart';
import 'package:sal/widgets/file_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// backend จำลองของส่วนอัปโหลด/ดาวน์โหลด ตอบตามสัญญาของ Spring Boot `salary`
class FakeFiles implements HttpClientAdapter {
  static const accounts = {
    'user291': (roles: ['USER'], div: '291', divName: 'ศูนย์สร้างทางลำปาง'),
    'uploader': (roles: ['UPLOAD'], div: null, divName: null),
    'admin': (roles: ['ADMIN'], div: '060', divName: 'ศูนย์เทคโนโลยีสารสนเทศ'),
  };

  final List<String> calls = [];

  /// เดือนที่มีไฟล์ (ตั้งก่อนเปิดแอปในเทสต์ที่ต้องใช้)
  static List<Map<String, int>> periods = [];

  /// query ของคำขอประวัติล่าสุด
  Map<String, dynamic> lastHistoryQuery = {};

  /// query ของคำขอ /api/download/* ล่าสุด
  Map<String, dynamic> lastDownloadQuery = {};
  final List<Map<String, dynamic>> batches = [];
  final Map<String, int> common = {'ประกาศ.docx': 20480};
  int _seq = 0;

  ResponseBody _json(int status, Object body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  List<Map<String, Object>> get _commonList => [
    for (final e in common.entries) {'name': e.key, 'size': e.value},
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final path = options.path;
    final method = options.method;
    final q = options.queryParameters;
    calls.add('$method $path');
    final data = options.data;

    if (path == '/api/auth/login') {
      final body = Map<String, dynamic>.from(data as Map);
      final a = accounts[body['username']]!;
      return _json(200, {
        'access_token': 'a',
        'refresh_token': 'r',
        'username': body['username'],
        'full_name': 'ผู้ใช้ ${body['username']}',
        'div': a.div,
        'div_name': a.divName,
        'roles': a.roles,
      });
    }
    if (path == '/api/upload/payroll' && method == 'GET') {
      return _json(200, batches);
    }
    if (path == '/api/upload/payroll' && method == 'POST') {
      final form = data as FormData;
      final f = {for (final e in form.fields) e.key: e.value};
      final name = form.files.first.value.filename!;
      batches.removeWhere(
        (b) => b['type'] == f['type'] && b['status'] == 'PENDING',
      );
      final batch = {
        'id': 'b${++_seq}',
        'year': int.parse(f['year']!),
        'month': int.parse(f['month']!),
        'type': f['type'],
        'status': 'PENDING',
        'fileName': name,
        'totalPages': 21,
        'sourceKept': true,
        'uploadedBy': 'uploader',
        'uploadedAt': '2026-10-05T14:30:00',
        'units': [
          {
            'div': '291',
            'divname': 'ศูนย์สร้างทางลำปาง',
            'fromPage': 1,
            'toPage': 9,
            'pages': 9,
            'size': 53406,
          },
          {
            'div': '293',
            'divname': 'ศูนย์สร้างทางขอนแก่น',
            'fromPage': 10,
            'toPage': 21,
            'pages': 12,
            'size': 60210,
          },
        ],
      };
      batches.insert(0, batch);
      return _json(200, batch);
    }
    final action = RegExp(
      r'^/api/upload/payroll/(\w+)/(publish|cancel|source)$',
    ).firstMatch(path);
    if (action != null) {
      final b = batches.firstWhere((x) => x['id'] == action.group(1));
      switch (action.group(2)) {
        case 'publish':
          batches.removeWhere(
            (x) =>
                x != b && x['type'] == b['type'] && x['status'] == 'PUBLISHED',
          );
          b['status'] = 'PUBLISHED';
          b['publishedBy'] = 'uploader';
          b['publishedAt'] = '2026-10-05T14:35:00';
        case 'cancel':
          batches.remove(b);
        case 'source':
          b['sourceKept'] = false;
      }
      return _json(200, b);
    }
    if (path == '/api/upload/common' && method == 'GET') {
      return _json(200, _commonList);
    }
    if (path == '/api/upload/common' && method == 'POST') {
      final form = data as FormData;
      final f = {for (final e in form.fields) e.key: e.value};
      final name = form.files.first.value.filename!;
      if (common.containsKey(name) && f['overwrite'] != 'true') {
        return _json(409, {
          'success': false,
          'message': 'มีไฟล์ชื่อ $name อยู่แล้วในเดือนนี้',
        });
      }
      common[name] = form.files.first.value.length;
      return _json(200, {'name': name, 'size': common[name]});
    }
    if (path == '/api/upload/common' && method == 'DELETE') {
      common.remove(q['name']);
      return _json(200, {'success': true});
    }
    if (path.startsWith('/api/download/')) lastDownloadQuery = Map.of(q);
    if (path == '/api/download/periods') return _json(200, periods);
    if (path == '/api/upload/download-status') {
      return _json(200, {
        'year': q['year'],
        'month': q['month'],
        'total': 3,
        'downloaded': 1,
        'units': [
          {
            'div': '291',
            'divName': 'ศูนย์สร้างทางลำปาง',
            'types': ['G2'],
            'downloaded': true,
            'count': 2,
            'lastAt': '2026-10-05T09:15:00',
            'lastBy': '291',
          },
          {
            'div': '293',
            'divName': 'ศูนย์สร้างทางขอนแก่น',
            'types': ['G2'],
            'downloaded': false,
            'count': 0,
          },
          {
            'div': '294',
            'divName': 'ศูนย์สร้างทางหล่มสัก',
            'types': ['G2', 'E'],
            'downloaded': false,
            'count': 0,
          },
        ],
      });
    }
    if (path.startsWith('/api/upload/history/')) {
      lastHistoryQuery = {'kind': path.split('/').last, ...q};
      final items = switch (path.split('/').last) {
        'payroll' => [
          {
            'year': 2569,
            'month': 9,
            'type': 'G2',
            'status': 'PUBLISHED',
            'fileName': '256909G2.pdf',
            'totalPages': 804,
            'uploadedBy': '030',
            'uploadedAt': '2026-10-05T14:30:00',
            'publishedBy': 'admin',
            'publishedAt': '2026-10-05T14:35:00',
          },
        ],
        'common' => [
          {
            'username': '030',
            'action': 'REPLACE',
            'year': 2569,
            'month': 9,
            'file': 'ประกาศ.docx',
            'at': '2026-10-05T10:00:00',
          },
        ],
        _ => [
          {
            'username': '291',
            'userDiv': '291',
            'div': '291',
            'year': 2569,
            'month': 9,
            'file': '291_256909G2.pdf',
            'at': '2026-10-05T09:15:00',
          },
        ],
      };
      return _json(200, {
        'items': items,
        'currentPage': 0,
        'pageSize': 10,
        'totalItems': items.length,
      });
    }
    if (path == '/api/download/divs') {
      return _json(200, [
        {'div': '291', 'divname': 'ศูนย์สร้างทางลำปาง'},
        {'div': '293', 'divname': 'ศูนย์สร้างทางขอนแก่น'},
      ]);
    }
    if (path == '/api/download/files' && q['all'] == true) {
      return _json(200, {
        'all': true,
        'divCount': 2,
        'year': q['year'],
        'month': q['month'],
        'zipName': 'ทุกหน่วยงาน_256910.zip',
        'payroll': [
          for (final d in const [
            ('291', 'ศูนย์สร้างทางลำปาง', 53406),
            ('293', 'ศูนย์สร้างทางขอนแก่น', 60210),
          ])
            {
              'name': '${d.$1}_256910G2.pdf',
              'size': d.$3,
              'type': 'G2',
              'typeName': 'ข้าราชการส่วนภูมิภาค',
              'div': d.$1,
              'divName': d.$2,
            },
        ],
        'common': _commonList,
      });
    }
    if (path == '/api/download/files') {
      final none = q['month'] == 8;
      final div = (q['div'] ?? '291') as String;
      return _json(200, {
        'div': div,
        'divName': div == '293' ? 'ศูนย์สร้างทางขอนแก่น' : 'ศูนย์สร้างทางลำปาง',
        'year': q['year'],
        'month': q['month'],
        'zipName': '$div.zip',
        'payroll': none
            ? <Object>[]
            : [
                {
                  'name': '${div}_256910G2.pdf',
                  'size': 53406,
                  'type': 'G2',
                  'typeName': 'ข้าราชการส่วนภูมิภาค',
                },
              ],
        'common': none ? <Object>[] : _commonList,
      });
    }
    if (path.startsWith('/api/download/')) {
      return ResponseBody.fromBytes(utf8.encode('FILE:$path'), 200);
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

  late FakeFiles backend;
  final saved = <String, Uint8List>{};
  final now = DateTime.now();
  final year = now.year + 543;
  final mm = now.month.toString().padLeft(2, '0');

  setUp(() {
    // ส่วนไฟล์ประกอบปิดเป็นค่าเริ่มต้น ชุดทดสอบเดิมเปิดไว้เพื่อทดสอบส่วนนั้นต่อ
    AppFeatures.commonFiles = true;
    saved.clear();
    FakeFiles.periods = [];
    FileSaver.override = (name, bytes) => saved[name] = bytes;
  });
  tearDown(() {
    AppFeatures.commonFiles = false;
    FileSaver.override = null;
    FilePick.override = null;
    FilePick.overrideMany = null;
  });

  Future<void> start(WidgetTester tester, String user) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    backend = FakeFiles();
    final dio = Dio(BaseOptions(baseUrl: 'https://test.invalid'))
      ..httpClientAdapter = backend;
    await tester.pumpWidget(
      SalApp(
        prefs: prefs,
        api: ApiService(prefs, dio: dio),
      ),
    );
    await tester.pumpAndSettle();
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

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).last;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'USER: เมนูดาวน์โหลด ตารางไฟล์ ลิงก์รายไฟล์ และปุ่มดาวน์โหลดรวมบนสุด',
    (tester) async {
      await start(tester, 'user291');
      expect(find.text('ดาวน์โหลดไฟล์'), findsOneWidget);
      expect(find.text('อัปโหลดไฟล์'), findsNothing);

      await tapText(tester, 'ดาวน์โหลดไฟล์');
      expect(find.text('หน่วยงาน 291 ศูนย์สร้างทางลำปาง'), findsOneWidget);
      expect(find.byKey(const ValueKey('download-div')), findsNothing);
      expect(backend.lastDownloadQuery.containsKey('div'), isFalse);
      // ตาราง: ไอคอนหน้าไฟล์ ชื่อไฟล์ ขนาดไฟล์ ลิงก์ดาวน์โหลด
      expect(find.text('ชื่อไฟล์'), findsNWidgets(2));
      expect(find.text('ขนาดไฟล์'), findsNWidgets(2));
      expect(find.text('291_256910G2.pdf'), findsOneWidget);
      expect(find.text('52.2 KB'), findsOneWidget);
      expect(find.text('ประกาศ.docx'), findsOneWidget);
      expect(find.text('20.0 KB'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
      expect(find.byIcon(Icons.description_rounded), findsOneWidget);
      expect(find.text('ดาวน์โหลด'), findsNWidgets(2));

      // ปุ่มดาวน์โหลดรวมอยู่เหนือตารางทั้งสอง
      final zip = find.text('ดาวน์โหลดรวม (291.zip)');
      expect(zip, findsOneWidget);
      expect(
        tester.getTopLeft(zip).dy,
        lessThan(tester.getTopLeft(find.byType(FileTable).first).dy),
      );

      await tester.tap(find.text('ดาวน์โหลด').first);
      await tester.pumpAndSettle();
      expect(backend.calls, contains('GET /api/download/payroll'));
      expect(
        utf8.decode(saved['291_256910G2.pdf']!),
        'FILE:/api/download/payroll',
      );

      await tester.tap(zip);
      await tester.pumpAndSettle();
      expect(backend.calls, contains('GET /api/download/zip'));
      expect(saved.keys, contains('291.zip'));
    },
  );

  testWidgets('USER: เดือนที่ยังไม่มีไฟล์ ปุ่มดาวน์โหลดรวมกดไม่ได้', (
    tester,
  ) async {
    await start(tester, 'user291');
    await tapText(tester, 'ดาวน์โหลดไฟล์');
    await tester.tap(find.byKey(const ValueKey('period-month')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('สิงหาคม').last);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('ยังไม่มีไฟล์ของหน่วยงานในเดือน สิงหาคม'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('ดาวน์โหลดรวม (291.zip)'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('UPLOAD: อัปโหลด → ตัด → เผยแพร่ → เลือกลบ PDF รวม', (
    tester,
  ) async {
    await start(tester, 'uploader');
    expect(find.text('อัปโหลดไฟล์'), findsOneWidget);
    // ผู้อัปโหลดมีเมนูดาวน์โหลดด้วย ไว้ตรวจไฟล์ของหน่วยงานต่าง ๆ
    expect(find.text('ดาวน์โหลดไฟล์'), findsOneWidget);
    await tapText(tester, 'อัปโหลดไฟล์');

    // สองส่วนในหน้าเดียว และค่าเริ่มต้นประเภท G1
    expect(find.text('รายละเอียดการจ่ายเงินประจำเดือน'), findsOneWidget);
    expect(find.text('ไฟล์ประกอบการรายงาน'), findsOneWidget);
    expect(
      find.textContaining('$year${mm}G1.pdf', findRichText: true),
      findsOneWidget,
    );

    await tapText(tester, 'ข้าราชการส่วนภูมิภาค (G2)');
    final expected = '$year${mm}G2.pdf';
    expect(find.textContaining(expected, findRichText: true), findsOneWidget);

    // เลือกไฟล์ชื่อผิด: แจ้งทันที ไม่ส่งขึ้น backend
    FilePick.override = (_) async =>
        (name: 'salary.pdf', bytes: Uint8List.fromList([1, 2, 3]));
    await tapText(tester, 'เลือกไฟล์ PDF และอัปโหลด');
    expect(find.textContaining('ไฟล์ที่เลือกชื่อ salary.pdf'), findsOneWidget);
    expect(backend.calls, isNot(contains('POST /api/upload/payroll')));

    FilePick.override = (_) async =>
        (name: expected, bytes: Uint8List.fromList([1, 2, 3]));
    await tapText(tester, 'เลือกไฟล์ PDF และอัปโหลด');
    expect(backend.calls, contains('POST /api/upload/payroll'));
    expect(find.text('รอเผยแพร่'), findsOneWidget);
    expect(
      find.textContaining('ตัดได้ 2 หน่วยงาน รวม 21 หน้า'),
      findsOneWidget,
    );

    await tapText(tester, 'ดูสรุปการตัดไฟล์');
    expect(find.text('291  ศูนย์สร้างทางลำปาง'), findsOneWidget);
    expect(find.text('หน้า 10-21 (12 หน้า)'), findsOneWidget);
    await tapText(tester, 'ปิด');

    await tapText(tester, 'เผยแพร่');
    expect(find.textContaining('ให้ผู้ใช้ดาวน์โหลด'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'เผยแพร่').last);
    await tester.pumpAndSettle();
    expect(backend.calls, contains('POST /api/upload/payroll/b1/publish'));

    // หลังเผยแพร่ถามว่าจะลบ PDF รวมหรือไม่
    expect(find.text('ลบไฟล์ PDF รวมหรือไม่'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'ลบไฟล์ PDF รวม'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('DELETE /api/upload/payroll/b1/source'));
    expect(find.text('เผยแพร่แล้ว'), findsOneWidget);
    expect(find.text('PDF รวมถูกลบแล้ว'), findsOneWidget);
    expect(find.text('ลบ PDF รวม'), findsNothing);
  });

  testWidgets('UPLOAD: เลือกเก็บ PDF รวมไว้ แล้วยกเลิกชุดที่อัปโหลดซ้ำ', (
    tester,
  ) async {
    await start(tester, 'uploader');
    await tapText(tester, 'อัปโหลดไฟล์');
    final expected = '$year${mm}G1.pdf';
    FilePick.override = (_) async =>
        (name: expected, bytes: Uint8List.fromList([1]));
    await tapText(tester, 'เลือกไฟล์ PDF และอัปโหลด');
    await tapText(tester, 'เผยแพร่');
    await tester.tap(find.widgetWithText(FilledButton, 'เผยแพร่').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'เก็บไว้'));
    await tester.pumpAndSettle();
    expect(
      backend.calls,
      isNot(contains('DELETE /api/upload/payroll/b1/source')),
    );
    expect(find.text('PDF รวมยังเก็บอยู่ในระบบ'), findsOneWidget);
    expect(find.text('ลบ PDF รวม'), findsOneWidget);

    // อัปโหลดซ้ำ: มีสองชุด ชุดใหม่รอเผยแพร่ ชุดเก่ายังเผยแพร่อยู่
    await tapText(tester, 'เลือกไฟล์ PDF และอัปโหลด');
    expect(find.text('รอเผยแพร่'), findsOneWidget);
    expect(find.text('เผยแพร่แล้ว'), findsOneWidget);
    await tapText(tester, 'ยกเลิกชุดนี้');
    await tester.tap(find.widgetWithText(FilledButton, 'ยกเลิกชุดนี้'));
    await tester.pumpAndSettle();
    expect(backend.calls, contains('POST /api/upload/payroll/b2/cancel'));
    expect(find.text('รอเผยแพร่'), findsNothing);
    expect(find.text('เผยแพร่แล้ว'), findsOneWidget);
  });

  testWidgets('UPLOAD: ไฟล์ประกอบ ชื่อซ้ำถามก่อนแทนที่ และลบได้', (
    tester,
  ) async {
    await start(tester, 'uploader');
    await tapText(tester, 'อัปโหลดไฟล์');
    expect(find.text('ประกาศ.docx'), findsOneWidget);

    FilePick.overrideMany = (_) async => [
      (name: 'ประกาศ.docx', bytes: Uint8List.fromList(List.filled(2048, 7))),
    ];
    await tapText(tester, 'เลือกไฟล์ประกอบและอัปโหลด');
    expect(find.text('มีไฟล์ชื่อนี้อยู่แล้ว'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'แทนที่'));
    await tester.pumpAndSettle();
    expect(backend.common['ประกาศ.docx'], 2048);
    expect(find.text('2.0 KB'), findsOneWidget);

    FilePick.overrideMany = (_) async => [
      (name: 'ตาราง.xlsx', bytes: Uint8List.fromList([1, 2])),
    ];
    await tapText(tester, 'เลือกไฟล์ประกอบและอัปโหลด');
    expect(find.text('ตาราง.xlsx'), findsOneWidget);
    expect(find.byIcon(Icons.table_chart_rounded), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('ลบไฟล์ ตาราง.xlsx'));
    await tester.tap(find.byTooltip('ลบไฟล์ ตาราง.xlsx'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'ลบไฟล์'));
    await tester.pumpAndSettle();
    expect(backend.common.containsKey('ตาราง.xlsx'), isFalse);
    expect(find.text('ตาราง.xlsx'), findsNothing);
  });

  testWidgets(
    'UPLOAD: ไฟล์ประกอบเลือกหลายไฟล์พร้อมกัน ซ้ำถามครั้งเดียว ไฟล์ที่ไม่ผ่านแจ้งท้ายสุด',
    (tester) async {
      await start(tester, 'uploader');
      await tapText(tester, 'อัปโหลดไฟล์');
      expect(find.textContaining('เลือกได้หลายไฟล์พร้อมกัน'), findsOneWidget);

      FilePick.overrideMany = (_) async => [
        (name: 'หนังสือเวียน.pdf', bytes: Uint8List.fromList([1, 2, 3])),
        (name: 'ประกาศ.docx', bytes: Uint8List.fromList(List.filled(1024, 1))),
        (name: 'ตาราง.xlsx', bytes: Uint8List.fromList([4, 5])),
        (name: 'ใหญ่เกิน.pdf', bytes: Uint8List(20 * 1024 * 1024 + 1)),
      ];
      await tapText(tester, 'เลือกไฟล์ประกอบและอัปโหลด');

      // ไฟล์ซ้ำ 1 ไฟล์: ถามก่อนแทนที่ ระหว่างนี้ไฟล์ที่ไม่ซ้ำขึ้นไปแล้ว
      expect(find.text('มีไฟล์ชื่อนี้อยู่แล้ว'), findsOneWidget);
      expect(
        backend.common.keys,
        containsAll(['หนังสือเวียน.pdf', 'ตาราง.xlsx']),
      );
      expect(backend.common['ประกาศ.docx'], 20480);
      await tester.tap(find.widgetWithText(FilledButton, 'แทนที่'));
      await tester.pumpAndSettle();
      expect(backend.common['ประกาศ.docx'], 1024);

      // สรุป: 3 จาก 4 ไฟล์ และบอกไฟล์ที่ไม่ผ่านพร้อมเหตุผล
      expect(find.text('อัปโหลดได้ 3 จาก 4 ไฟล์'), findsOneWidget);
      expect(
        find.textContaining('ใหญ่เกิน.pdf: ขนาดเกิน 20 MB'),
        findsOneWidget,
      );
      expect(backend.common.containsKey('ใหญ่เกิน.pdf'), isFalse);
      await tester.tap(find.widgetWithText(FilledButton, 'รับทราบ'));
      await tester.pumpAndSettle();
      expect(find.text('หนังสือเวียน.pdf'), findsOneWidget);
      expect(find.text('ตาราง.xlsx'), findsOneWidget);
    },
  );

  testWidgets('UPLOAD: หลายไฟล์ เลือกข้ามไฟล์ที่ซ้ำ ไฟล์เดิมไม่ถูกแตะ', (
    tester,
  ) async {
    await start(tester, 'uploader');
    await tapText(tester, 'อัปโหลดไฟล์');
    FilePick.overrideMany = (_) async => [
      (name: 'ประกาศ.docx', bytes: Uint8List.fromList([9])),
      (name: 'ใหม่.txt', bytes: Uint8List.fromList([1])),
    ];
    await tapText(tester, 'เลือกไฟล์ประกอบและอัปโหลด');
    await tester.tap(find.widgetWithText(TextButton, 'ข้ามไฟล์ที่ซ้ำ'));
    await tester.pumpAndSettle();
    expect(backend.common['ประกาศ.docx'], 20480);
    expect(backend.common.containsKey('ใหม่.txt'), isTrue);
  });

  testWidgets(
    'UPLOAD/ADMIN: หน้าดาวน์โหลดเริ่มที่ทุกหน่วยงาน แล้วเลือกดูทีละหน่วยงานได้',
    (tester) async {
      await start(tester, 'uploader');
      await tapText(tester, 'ดาวน์โหลดไฟล์');

      // ค่าเริ่มต้น = ทุกหน่วยงาน
      final field = find.byKey(const ValueKey('download-div'));
      expect(tester.widget<TextField>(field).controller!.text, 'ทุกหน่วยงาน');
      expect(backend.lastDownloadQuery['all'], true);
      expect(backend.lastDownloadQuery.containsKey('div'), isFalse);
      expect(
        find.text('หน่วยงาน ทุกหน่วยงาน (มีไฟล์ 2 หน่วยงาน)'),
        findsOneWidget,
      );
      expect(find.text('291_256910G2.pdf'), findsOneWidget);
      expect(find.text('293_256910G2.pdf'), findsOneWidget);
      // แต่ละแถวบอกว่าเป็นไฟล์ของหน่วยงานไหน
      expect(
        find.text('293 ศูนย์สร้างทางขอนแก่น  ·  ข้าราชการส่วนภูมิภาค'),
        findsOneWidget,
      );
      expect(
        find.text('ดาวน์โหลดรวม (ทุกหน่วยงาน_256910.zip)'),
        findsOneWidget,
      );

      // ลิงก์ของแถวหน่วยงาน 293 ต้องขอไฟล์ของ 293
      await tester.tap(find.text('ดาวน์โหลด').at(1));
      await tester.pumpAndSettle();
      expect(backend.lastDownloadQuery['div'], '293');
      expect(saved.keys, contains('293_256910G2.pdf'));

      await tester.tap(find.text('ดาวน์โหลดรวม (ทุกหน่วยงาน_256910.zip)'));
      await tester.pumpAndSettle();
      expect(backend.lastDownloadQuery['all'], true);
      expect(saved.keys, contains('ทุกหน่วยงาน_256910.zip'));

      // เลือกดูหน่วยงานเดียว
      await tester.enterText(field, 'ขอนแก่น');
      await tester.pumpAndSettle();
      await tester.tap(find.text('293 ศูนย์สร้างทางขอนแก่น').last);
      await tester.pumpAndSettle();
      expect(backend.lastDownloadQuery['div'], '293');
      expect(backend.lastDownloadQuery.containsKey('all'), isFalse);
      expect(find.text('หน่วยงาน 293 ศูนย์สร้างทางขอนแก่น'), findsOneWidget);
      expect(find.text('291_256910G2.pdf'), findsNothing);
      expect(find.text('ดาวน์โหลดรวม (293.zip)'), findsOneWidget);

      // กลับไปดูทุกหน่วยงานได้จากรายการเดียวกัน
      await tester.enterText(field, 'ทุก');
      await tester.pumpAndSettle();
      await tester.tap(find.text('ทุกหน่วยงาน').last);
      await tester.pumpAndSettle();
      expect(backend.lastDownloadQuery['all'], true);
      expect(find.text('291_256910G2.pdf'), findsOneWidget);
    },
  );

  testWidgets(
    'ดาวน์โหลด: เปิดมาที่เดือนล่าสุดที่มีไฟล์ และมีปุ่มลัดเดือนที่มีไฟล์',
    (tester) async {
      FakeFiles.periods = [
        {'year': 2569, 'month': 9},
        {'year': 2569, 'month': 7},
      ];
      await start(tester, 'user291');
      await tapText(tester, 'ดาวน์โหลดไฟล์');

      expect(backend.calls, contains('GET /api/download/periods'));
      // ไม่ต้องเลือกเอง: ไปเดือนล่าสุดที่มีไฟล์ (ก.ย. 2569) ทันที
      expect(backend.lastDownloadQuery['year'], 2569);
      expect(backend.lastDownloadQuery['month'], 9);
      expect(
        find.textContaining('ดาวน์โหลดรวมทุกไฟล์ของเดือน กันยายน 2569'),
        findsOneWidget,
      );
      expect(find.text('เดือนที่มีไฟล์:'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'กันยายน 2569'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'กรกฎาคม 2569'));
      await tester.pumpAndSettle();
      expect(backend.lastDownloadQuery['month'], 7);
      expect(
        find.textContaining('ดาวน์โหลดรวมทุกไฟล์ของเดือน กรกฎาคม 2569'),
        findsOneWidget,
      );
    },
  );

  testWidgets('ดาวน์โหลด: ยังไม่มีเดือนไหนมีไฟล์ บอกผู้ใช้ตรง ๆ', (
    tester,
  ) async {
    await start(tester, 'user291');
    await tapText(tester, 'ดาวน์โหลดไฟล์');
    expect(find.text('ยังไม่มีเดือนที่มีไฟล์ให้ดาวน์โหลด'), findsOneWidget);
  });

  testWidgets(
    'อัปโหลด: สถานะการดาวน์โหลดของหน่วยงาน กรองยังไม่ดาวน์โหลด/ดาวน์โหลดแล้ว',
    (tester) async {
      await start(tester, 'uploader');
      await tapText(tester, 'อัปโหลดไฟล์');

      expect(find.text('สถานะการดาวน์โหลดของหน่วยงาน'), findsOneWidget);
      expect(
        find.textContaining(
          'ดาวน์โหลดแล้ว 1 จาก 3 หน่วยงาน (ยังไม่ดาวน์โหลด 2)',
        ),
        findsOneWidget,
      );
      // ค่าเริ่มต้นแสดงหน่วยงานที่ยังไม่ดาวน์โหลด (กลุ่มที่ต้องตาม)
      expect(find.text('293 ศูนย์สร้างทางขอนแก่น'), findsOneWidget);
      expect(find.text('294 ศูนย์สร้างทางหล่มสัก'), findsOneWidget);
      expect(find.text('291 ศูนย์สร้างทางลำปาง'), findsNothing);
      expect(find.text('G2, E'), findsOneWidget);

      await tapText(tester, 'ดาวน์โหลดแล้ว');
      expect(find.text('291 ศูนย์สร้างทางลำปาง'), findsOneWidget);
      expect(find.text('293 ศูนย์สร้างทางขอนแก่น'), findsNothing);
      expect(find.textContaining('โดย 291 (2 ครั้ง)'), findsOneWidget);

      await tapText(tester, 'ทั้งหมด');
      expect(find.text('291 ศูนย์สร้างทางลำปาง'), findsOneWidget);
      expect(find.text('294 ศูนย์สร้างทางหล่มสัก'), findsOneWidget);
    },
  );

  testWidgets(
    'ปิดส่วนไฟล์ประกอบ (ค่าเริ่มต้น): หน้าอัปโหลดไม่มีส่วนไฟล์ประกอบ',
    (tester) async {
      AppFeatures.commonFiles = false;
      await start(tester, 'uploader');
      expect(find.textContaining('ไฟล์ประกอบ'), findsNothing);
      await tapText(tester, 'อัปโหลดไฟล์');
      expect(find.text('รายละเอียดการจ่ายเงินประจำเดือน'), findsOneWidget);
      expect(find.textContaining('ไฟล์ประกอบ'), findsNothing);
    },
  );

  testWidgets(
    'ปิดส่วนไฟล์ประกอบ (ค่าเริ่มต้น): หน้าดาวน์โหลดไม่มีตารางไฟล์ประกอบ',
    (tester) async {
      AppFeatures.commonFiles = false;
      await start(tester, 'user291');
      await tapText(tester, 'ดาวน์โหลดไฟล์');
      expect(find.textContaining('ดาวน์โหลดรวมทุกไฟล์'), findsOneWidget);
      expect(find.textContaining('ไฟล์ประกอบ'), findsNothing);
    },
  );

  testWidgets('ปิดส่วนไฟล์ประกอบ (ค่าเริ่มต้น): หน้าประวัติเหลือสองแท็บ', (
    tester,
  ) async {
    AppFeatures.commonFiles = false;
    await start(tester, 'admin');
    await tapText(tester, 'ประวัติการใช้งาน');
    expect(find.text('อัปโหลดรายละเอียดการจ่ายเงิน'), findsOneWidget);
    expect(find.textContaining('ไฟล์ประกอบ'), findsNothing);
  });

  testWidgets('ADMIN: หน้าประวัติการใช้งาน สามแท็บและค้นหา', (tester) async {
    await start(tester, 'admin');
    await tapText(tester, 'ประวัติการใช้งาน');

    // แท็บแรก: การดาวน์โหลด
    expect(backend.lastHistoryQuery['kind'], 'downloads');
    expect(find.text('291_256909G2.pdf'), findsOneWidget);
    expect(find.text('5 ตุลาคม 2569 09:15'), findsOneWidget);

    await tapText(tester, 'อัปโหลดรายละเอียดการจ่ายเงิน');
    expect(backend.lastHistoryQuery['kind'], 'payroll');
    expect(find.text('256909G2.pdf'), findsOneWidget);
    expect(find.text('เผยแพร่อยู่'), findsOneWidget);
    expect(find.textContaining('030 / admin'), findsOneWidget);

    await tapText(tester, 'อัปโหลด/ลบไฟล์ประกอบ');
    expect(backend.lastHistoryQuery['kind'], 'common');
    expect(find.text('แทนที่ไฟล์เดิม'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'ค้นหา'), '030');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(backend.lastHistoryQuery['keyword'], '030');
  });

  testWidgets(
    'ประวัติการใช้งาน: ผู้อัปโหลดเห็นและเปิดได้ ผู้ใช้ทั่วไปไม่เห็น',
    (tester) async {
      await start(tester, 'uploader');
      await tapText(tester, 'ประวัติการใช้งาน');
      expect(backend.lastHistoryQuery['kind'], 'downloads');
      expect(find.text('291_256909G2.pdf'), findsOneWidget);
    },
  );

  testWidgets('ผู้ใช้ทั่วไปไม่มีเมนูประวัติการใช้งาน', (tester) async {
    await start(tester, 'user291');
    expect(find.text('ประวัติการใช้งาน'), findsNothing);
  });
}
