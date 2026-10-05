import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sal/config/theme.dart';
import 'package:sal/widgets/file_widgets.dart';

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

  Future<void> pump(WidgetTester tester, int count) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(null),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: FileTable(
              emptyText: 'ไม่มีไฟล์',
              rows: [
                for (var i = 1; i <= count; i++)
                  FileRow(
                    name: 'ไฟล์$i.pdf',
                    size: i * 1024,
                    onDownload: () {},
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ตารางไฟล์แบ่งหน้า ค่าเริ่มต้นหน้าละ 10 แถว', (tester) async {
    await pump(tester, 23);
    expect(find.text('ไฟล์1.pdf'), findsOneWidget);
    expect(find.text('ไฟล์10.pdf'), findsOneWidget);
    expect(find.text('ไฟล์11.pdf'), findsNothing);
    expect(find.textContaining('แสดง 1-10 จาก 23 รายการ'), findsOneWidget);

    await tester.tap(find.byTooltip('ถัดไป'));
    await tester.pumpAndSettle();
    expect(find.text('ไฟล์11.pdf'), findsOneWidget);
    expect(find.text('ไฟล์1.pdf'), findsNothing);

    await tester.tap(find.byTooltip('หน้าสุดท้าย'));
    await tester.pumpAndSettle();
    expect(find.textContaining('แสดง 21-23 จาก 23 รายการ'), findsOneWidget);
    expect(find.text('ไฟล์23.pdf'), findsOneWidget);
    expect(find.text('ดาวน์โหลด'), findsNWidgets(3));

    // กดเลขหน้าได้โดยตรง
    await tester.tap(find.widgetWithText(TextButton, '2'));
    await tester.pumpAndSettle();
    expect(find.textContaining('แสดง 11-20 จาก 23 รายการ'), findsOneWidget);
  });

  testWidgets('เปลี่ยนแถวต่อหน้าเป็น 20 แล้วกลับไปหน้าแรก', (tester) async {
    await pump(tester, 23);
    await tester.tap(find.byTooltip('ถัดไป'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('แสดง 1-20 จาก 23 รายการ'), findsOneWidget);
    expect(find.text('ไฟล์20.pdf'), findsOneWidget);
    expect(find.text('ไฟล์21.pdf'), findsNothing);
  });

  testWidgets('ไม่เกิน 5 แถวไม่แสดงตัวแบ่งหน้า', (tester) async {
    await pump(tester, 5);
    expect(find.text('ไฟล์5.pdf'), findsOneWidget);
    expect(find.textContaining('แถวต่อหน้า'), findsNothing);
  });
}
