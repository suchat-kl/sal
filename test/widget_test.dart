import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sal/main.dart';
import 'package:sal/widgets/sidebar_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// โหลดฟอนต์ไทยจริงให้เทสต์ ไม่งั้นเทสต์ใช้ฟอนต์สี่เหลี่ยมที่กว้างกว่าจริงมาก layout จะล้นทั้งที่ในเบราว์เซอร์ไม่ล้น
Future<void> _loadFonts() async {
  for (final family in ['Sarabun', 'Kanit']) {
    final loader = FontLoader(family);
    for (final w in ['Regular', 'Medium', 'Bold']) {
      loader.addFont(rootBundle.load('assets/fonts/$family-$w.ttf'));
    }
    await loader.load();
  }
}

/// ข้อความนี้อยู่ในเมนูข้างไหม (หน้าแรกก็มีการ์ดชื่อเดียวกัน จึงต้องค้นเฉพาะในเมนู)
Finder _inMenu(String text) => find.descendant(of: find.byType(SidebarMenu), matching: find.text(text));

void main() {
  setUpAll(_loadFonts);

  testWidgets('หน้าแรกแสดงชื่อระบบและข้อความอธิบายสองส่วน', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SalApp(prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.text('ผู้ใช้งานระบบประกอบด้วย'), findsOneWidget);
    expect(find.text('สอบถามปัญหาเพิ่มเติม'), findsOneWidget);
    // จอกว้าง เมนูตรึงไว้เหลือแต่ไอคอน จึงไม่มีปุ่มเปิดเมนูที่แถบหัว
    expect(find.byTooltip('เมนู'), findsNothing);
    expect(find.byTooltip('ขยายเมนู'), findsOneWidget);
  });

  testWidgets('กดขยายเมนูแล้วเห็นชื่อเมนู กดย่อแล้วกลับเป็นไอคอน', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SalApp(prefs: prefs));
    await tester.pumpAndSettle();
    expect(_inMenu('หักหนี้ (ข้าราชการ/ลูกจ้างประจำ)'), findsNothing);

    await tester.tap(find.byTooltip('ขยายเมนู'));
    await tester.pumpAndSettle();
    expect(_inMenu('หักหนี้ (ข้าราชการ/ลูกจ้างประจำ)'), findsOneWidget);

    await tester.tap(find.byTooltip('ย่อเมนูเหลือแต่ไอคอน'));
    await tester.pumpAndSettle();
    expect(_inMenu('หักหนี้ (ข้าราชการ/ลูกจ้างประจำ)'), findsNothing);
  });

  testWidgets('จอแคบใช้เมนูเลื่อนออก', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(SalApp(prefs: prefs));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('เมนู'));
    await tester.pumpAndSettle();
    expect(_inMenu('ใบรับรองภาษีกรมทางหลวง/สลิป'), findsOneWidget);
  });

  testWidgets('การ์ดแสดงข้อความครบ ไม่ล้น ที่จอ 720 และ 1000 (การ์ดแคบที่สุด)', (tester) async {
    for (final w in [720.0, 1000.0]) {
      tester.view.physicalSize = Size(w, 1600);
      tester.view.devicePixelRatio = 1;
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(SalApp(prefs: prefs));
      await tester.pumpAndSettle();
      // pumpAndSettle จะล้มเองถ้ามี RenderFlex overflow
      expect(find.textContaining('ข้าราชการ/ลูกจ้างประจำ/พนักงานราชการ'), findsOneWidget);
    }
    tester.view.reset();
  });
}
