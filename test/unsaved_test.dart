import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_diary/store.dart';
import 'package:money_diary/widgets/entry_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppStore store;

  Future<void> openForm(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore();
    await store.load();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(StoreScope(
      store: store,
      child: MaterialApp(
        home: Builder(
          builder: (c) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => showEntryForm(c), child: const Text('open')),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('เพิ่มรายการ'), findsOneWidget);
  }

  Future<void> typeAmount(WidgetTester tester) async {
    await tester.tap(find.text('4').last);
    await tester.tap(find.text('5').last);
    await tester.pump();
  }

  testWidgets('ยังไม่ได้กรอกอะไร กดปิดแล้วออกเลย ไม่ถาม', (tester) async {
    await openForm(tester);
    await tester.tap(find.byTooltip('ปิด'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่ได้บันทึก'), findsNothing);
    expect(find.text('เพิ่มรายการ'), findsNothing);
  });

  testWidgets('กรอกแล้วกดย้อนกลับ ถาม → "บันทึกก่อน" อยู่หน้าเดิม', (tester) async {
    await openForm(tester);
    await typeAmount(tester);
    await tester.binding.handlePopRoute(); // ปุ่มย้อนกลับของ Android
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่ได้บันทึก'), findsOneWidget);
    await tester.tap(find.text('บันทึกก่อน'));
    await tester.pumpAndSettle();
    expect(find.text('เพิ่มรายการ'), findsOneWidget); // ยังอยู่ในฟอร์ม
    expect(find.text('ยังไม่ได้บันทึก'), findsNothing);
    expect(store.entries, isEmpty);
  });

  testWidgets('กรอกแล้วกดปิด → "ไม่บันทึก" ออกโดยไม่บันทึก', (tester) async {
    await openForm(tester);
    await typeAmount(tester);
    await tester.tap(find.byTooltip('ปิด'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ไม่บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('เพิ่มรายการ'), findsNothing);
    expect(store.entries, isEmpty);
  });

  testWidgets('กดบันทึกปกติ ไม่ถาม และบันทึกจริง', (tester) async {
    await openForm(tester);
    await typeAmount(tester);
    await tester.tap(find.textContaining('บันทึกรายจ่าย'));
    await tester.pumpAndSettle();
    expect(find.text('ยังไม่ได้บันทึก'), findsNothing);
    expect(store.entries.single.amount, 45);
  });
}
