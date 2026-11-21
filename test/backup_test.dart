import 'package:flutter_test/flutter_test.dart';
import 'package:money_diary/backup.dart';
import 'package:money_diary/models.dart';
import 'package:money_diary/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<AppStore> freshStore() async {
  SharedPreferences.setMockInitialValues({});
  final s = AppStore();
  await s.load();
  return s;
}

Entry entry(String id, String cat, double amount) => Entry(
      id: id,
      type: TxType.expense,
      categoryId: cat,
      amount: amount,
      note: 'โน้ต "$id"',
      date: DateTime(2026, 11, 3),
      createdAt: DateTime(2026, 11, 3, 9),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('สำรองแล้วกู้คืนแบบแทนที่ ได้ข้อมูลเหมือนเดิม', () async {
    final a = await freshStore();
    final food = a.categoriesOf(TxType.expense).first;
    a.addEntry(entry('e1', food.id, 120));
    a.addEntry(entry('e2', food.id, 45.5));
    final json = buildBackupJson(a);

    final b = await freshStore();
    final data = parseBackup(json);
    final (cats, items) = await b.restore(data.categories, data.entries, replace: true);
    expect(items, 2);
    expect(cats, a.categories.length);
    expect(b.entries.map((e) => e.toJson()), a.entries.map((e) => e.toJson()));
    expect(b.categories.map((c) => c.toJson()), a.categories.map((c) => c.toJson()));
  });

  test('กู้คืนแบบรวม เพิ่มเฉพาะที่ยังไม่มี', () async {
    final a = await freshStore();
    final cat = a.categoriesOf(TxType.expense).first;
    a.addEntry(entry('e1', cat.id, 100));
    a.addEntry(entry('e2', cat.id, 200));
    final data = parseBackup(buildBackupJson(a));

    // เครื่องปลายทางมี e1 อยู่แล้ว + มีรายการของตัวเอง
    final b = await freshStore();
    await b.restore(data.categories, [data.entries.first], replace: true);
    b.addEntry(entry('local', cat.id, 999));
    final (_, added) = await b.restore(data.categories, data.entries, replace: false);
    expect(added, 1); // เพิ่มแค่ e2
    expect(b.entries.map((e) => e.id).toSet(), {'e1', 'e2', 'local'});
    // กู้ซ้ำอีกรอบ ไม่เพิ่มซ้ำ
    final (c2, e2) = await b.restore(data.categories, data.entries, replace: false);
    expect((c2, e2), (0, 0));
  });

  test('ไฟล์ที่ไม่ถูกต้องแจ้งเป็นภาษาไทย', () {
    expect(() => parseBackup('ไม่ใช่ json'), throwsA(isA<FormatException>()));
    expect(() => parseBackup('{"app":"other","version":1}'), throwsA(isA<FormatException>()));
    expect(() => parseBackup('{"app":"money_diary","version":99,"categories":[],"entries":[]}'),
        throwsA(isA<FormatException>()));
    expect(() => parseBackup('{"app":"money_diary","version":1,"categories":[],"entries":[]}'),
        throwsA(isA<FormatException>()));
  });
}
