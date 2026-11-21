import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../utils.dart';

/// ย่อจำนวนเงินให้พอดีช่องปฏิทิน เช่น 850, 1.2k, 15k, 1.3M
String compactMoney(double v) {
  final a = v.abs();
  if (a < 1000) return a.toStringAsFixed(0);
  if (a < 10000) return '${(a / 1000).toStringAsFixed(1)}k';
  if (a < 1000000) return '${(a / 1000).toStringAsFixed(0)}k';
  return '${(a / 1000000).toStringAsFixed(1)}M';
}

/// ปฏิทินรายเดือน: แต่ละวันแสดงรายรับ/รายจ่าย สีพื้นเข้มตามยอดจ่าย
class MonthCalendar extends StatelessWidget {
  final int year;
  final int month;

  /// index 0 = วันที่ 1
  final List<Totals> daily;
  final ValueChanged<DateTime> onTapDay;

  const MonthCalendar({
    super.key,
    required this.year,
    required this.month,
    required this.daily,
    required this.onTapDay,
  });

  static const _weekdays = ['อา', 'จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส'];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final expenseColor = context.expenseColor;
    final incomeColor = context.incomeColor;
    final nDays = daily.length;
    final leading = DateTime(year, month, 1).weekday % 7; // อาทิตย์ = 0
    final cells = leading + nDays;
    final rows = (cells / 7).ceil();
    final maxExpense =
        daily.fold<double>(0, (m, t) => t.expense > m ? t.expense : m);
    final today = DateTime.now();

    Widget dayCell(int day) {
      final t = daily[day - 1];
      final isToday = sameDay(DateTime(year, month, day), today);
      final intensity = maxExpense == 0 ? 0.0 : t.expense / maxExpense;
      final hasData = t.income > 0 || t.expense > 0;
      return Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: t.expense > 0
              ? expenseColor.withAlpha((18 + 60 * intensity).round())
              : (hasData ? incomeColor.withAlpha(22) : Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: isToday
                ? BorderSide(color: colors.primary, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onTapDay(DateTime(year, month, day)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? colors.primary : colors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (t.income > 0)
                    _amount(context, '+${compactMoney(t.income)}', incomeColor),
                  if (t.expense > 0)
                    _amount(
                        context, '−${compactMoney(t.expense)}', expenseColor),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _weekdays[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: i == 0 ? expenseColor : colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var r = 0; r < rows; r++)
          SizedBox(
            height: 62,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: () {
                      final day = r * 7 + c - leading + 1;
                      if (day < 1 || day > nDays) return const SizedBox();
                      return dayCell(day);
                    }(),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(context, incomeColor, 'รายรับ'),
            const SizedBox(width: 16),
            _legend(context, expenseColor, 'รายจ่าย (สียิ่งเข้ม = จ่ายมาก)'),
          ],
        ),
      ],
    );
  }

  Widget _amount(BuildContext context, String text, Color color) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: amountStyle(context, 11, color, weight: FontWeight.w600)),
      );

  Widget _legend(BuildContext context, Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 6),
          Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 11)),
        ],
      );
}
