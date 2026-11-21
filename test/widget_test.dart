import 'package:flutter_test/flutter_test.dart';
import 'package:money_diary/models.dart';
import 'package:money_diary/utils.dart';

void main() {
  group('evalExpression (เครื่องคิดเลขในช่องจำนวนเงิน)', () {
    test('ตัวเลขธรรมดา', () {
      expect(evalExpression('45'), 45);
      expect(evalExpression('1,250.50'), 1250.5);
    });
    test('ลำดับการคำนวณ', () {
      expect(evalExpression('45+30*2'), 105);
      expect(evalExpression('(120-20)/4'), 25);
      expect(evalExpression('50×3'), 150);
      expect(evalExpression('90÷3'), 30);
    });
    test('สูตรไม่ถูกต้อง', () {
      expect(evalExpression(''), isNull);
      expect(evalExpression('5+'), isNull);
      expect(evalExpression('(5'), isNull);
      expect(evalExpression('5/0'), isNull);
    });
  });

  test('Totals คำนวณรายรับ รายจ่าย คงเหลือ', () {
    Entry e(TxType t, double a) => Entry(
          id: '$a',
          type: t,
          categoryId: 'c',
          amount: a,
          note: '',
          date: DateTime(2026, 11, 21),
          createdAt: DateTime(2026, 11, 21),
        );
    final t = Totals.of([
      e(TxType.income, 1000),
      e(TxType.expense, 120),
      e(TxType.expense, 80),
    ]);
    expect(t.income, 1000);
    expect(t.expense, 200);
    expect(t.balance, 800);
  });
}
