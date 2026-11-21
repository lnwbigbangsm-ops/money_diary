import 'package:flutter_test/flutter_test.dart';
import 'package:money_diary/models.dart';
import 'package:money_diary/report.dart';
import 'package:money_diary/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('รายงานรายเดือนมียอดรวม หมวด และ escape หมายเหตุ', () async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    await store.load();
    final food = store.categoriesOf(TxType.expense).first;
    final salary = store.categoriesOf(TxType.income).first;
    Entry e(TxType t, String cat, double amount, int day, String note) => Entry(
          id: '$day$amount',
          type: t,
          categoryId: cat,
          amount: amount,
          note: note,
          date: DateTime(2026, 10, day),
          createdAt: DateTime(2026, 10, day),
        );
    store.addEntry(e(TxType.income, salary.id, 20000, 1, 'เงินเดือน'));
    store.addEntry(e(TxType.expense, food.id, 150, 2, '<script>x</script>'));
    store.addEntry(e(TxType.expense, food.id, 350, 5, 'ข้าวเย็น'));

    final html = buildMonthlyReportHtml(store, 2026, 10);
    expect(html, contains('ตุลาคม 2569'));
    expect(html, contains('20,000.00'));
    expect(html, contains('500.00')); // รายจ่ายรวม
    expect(html, contains('19,500.00')); // คงเหลือ
    expect(html, contains(food.name));
    expect(html, isNot(contains('<script>')));
    expect(html, contains('&lt;script&gt;'));

    final empty = buildMonthlyReportHtml(store, 2026, 9);
    expect(empty, contains('เดือนนี้ยังไม่มีรายการ'));
  });
}
