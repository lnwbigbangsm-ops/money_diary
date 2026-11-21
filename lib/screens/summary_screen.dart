import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/export_sheet.dart';
import '../widgets/month_calendar.dart';

/// หน้ารายเดือน: ยอดรวม ปฏิทิน สถิติ แยกตามหมวด และส่งออกรายงาน
class SummaryScreen extends StatefulWidget {
  final ValueChanged<DateTime> onOpenDay;
  const SummaryScreen({super.key, required this.onOpenDay});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late int _year;
  late int _month;
  TxType _breakType = TxType.expense;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = now.year;
    _month = now.month;
  }

  void _shift(int delta) {
    final d = DateTime(_year, _month + delta);
    setState(() {
      _year = d.year;
      _month = d.month;
    });
  }

  /// จำนวนวันที่ใช้หาค่าเฉลี่ย (เดือนปัจจุบันนับถึงวันนี้)
  int _daysForAverage() {
    final now = DateTime.now();
    if (_year == now.year && _month == now.month) return now.day;
    if (DateTime(_year, _month).isAfter(now)) return 0;
    return daysInMonth(_year, _month);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.entriesInMonth(_year, _month);
    final totals = Totals.of(list);
    final nDays = daysInMonth(_year, _month);
    final daily = List<Totals>.generate(
        nDays, (i) => Totals.of(list.where((e) => e.date.day == i + 1)));
    final avgDays = _daysForAverage();
    final avgExpense = avgDays == 0 ? 0.0 : totals.expense / avgDays;
    final savingRate =
        totals.income > 0 ? totals.balance / totals.income * 100 : null;
    final endBalance = store.balanceUntil(DateTime(_year, _month, nDays));

    int? topDay;
    for (var i = 0; i < nDays; i++) {
      if (daily[i].expense > 0 &&
          (topDay == null || daily[i].expense > daily[topDay].expense)) {
        topDay = i;
      }
    }
    final expenses = list.where((e) => e.type == TxType.expense).toList();
    final biggest = expenses.isEmpty
        ? null
        : expenses.reduce((a, b) => a.amount >= b.amount ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายเดือน'),
        actions: [
          IconButton(
            tooltip: 'ส่งออกรายงาน',
            onPressed: () => showExportSheet(context, _year, _month),
            icon: const Icon(Icons.ios_share_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          StepperBar(
            label: thaiMonthYear(_year, _month),
            onPrev: () => _shift(-1),
            onNext: () => _shift(1),
          ),
          BalanceHero(
            label: 'คงเหลือเดือนนี้',
            totals: totals,
            footer: [
              if (savingRate != null)
                HeroFooterRow(
                    label: 'อัตราการออม',
                    value: '${savingRate.toStringAsFixed(1)}%'),
              HeroFooterRow(
                  label: 'ยอดสะสม ณ สิ้นเดือน', value: baht(endBalance)),
            ],
          ),
          const SectionHeader('ปฏิทิน', trailingText: 'แตะวันเพื่อดูรายการ'),
          Panel(
            padding: const EdgeInsets.all(10),
            children: [
              MonthCalendar(
                year: _year,
                month: _month,
                daily: daily,
                onTapDay: widget.onOpenDay,
              ),
            ],
          ),
          const SectionHeader('สถิติ'),
          _StatsPanel(items: [
            ('รายจ่ายเฉลี่ย/วัน', fmtMoney(avgExpense)),
            ('จำนวนรายการ', '${list.length}'),
            (
              'วันที่จ่ายมากสุด',
              topDay == null
                  ? '-'
                  : 'วันที่ ${topDay + 1} · ${fmtMoney(daily[topDay].expense)}'
            ),
            (
              'จ่ายก้อนใหญ่สุด',
              biggest == null ? '-' : fmtMoney(biggest.amount)
            ),
          ]),
          SectionHeader(
            'แยกตามหมวด',
            trailing: SegmentedButton<TxType>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(value: TxType.expense, label: Text('รายจ่าย')),
                ButtonSegment(value: TxType.income, label: Text('รายรับ')),
              ],
              selected: {_breakType},
              onSelectionChanged: (s) => setState(() => _breakType = s.first),
            ),
          ),
          _CategoryBreakdown(entries: list, type: _breakType),
          const SizedBox(height: 24),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => showExportSheet(context, _year, _month),
            icon: const Icon(Icons.ios_share_rounded),
            label: Text('ส่งออกรายงาน ${thaiMonthYear(_year, _month)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final List<(String, String)> items;
  const _StatsPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget cell((String, String) s) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.$1, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(s.$2,
                    style: amountStyle(context, 16, theme.colorScheme.onSurface,
                        weight: FontWeight.w600)),
              ],
            ),
          ),
        );
    return Panel(
      dividerIndent: 14,
      children: [
        for (var i = 0; i < items.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cell(items[i]),
                VerticalDivider(
                    width: 1, color: theme.colorScheme.outlineVariant),
                if (i + 1 < items.length)
                  cell(items[i + 1])
                else
                  const Spacer(),
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final List<Entry> entries;
  final TxType type;
  const _CategoryBreakdown({required this.entries, required this.type});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final theme = Theme.of(context);
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final e in entries.where((e) => e.type == type)) {
      sums[e.categoryId] = (sums[e.categoryId] ?? 0) + e.amount;
      counts[e.categoryId] = (counts[e.categoryId] ?? 0) + 1;
    }
    final total = sums.values.fold<double>(0, (a, b) => a + b);
    if (total == 0) {
      return EmptyHint(
          icon: Icons.donut_large_rounded,
          text: 'ยังไม่มี${type.label}ในเดือนนี้');
    }
    final sorted = sums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Panel(
      children: [
        for (final s in sorted)
          Builder(builder: (context) {
            final cat = store.categoryById(s.key);
            final color = cat != null ? Color(cat.color) : Colors.grey;
            final pct = s.value / total;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CategoryAvatar(category: cat),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                            child: Text(cat?.name ?? 'ไม่ระบุหมวด',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                          ),
                          Text(fmtMoney(s.value),
                              style: amountStyle(
                                  context, 15, theme.colorScheme.onSurface,
                                  weight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            color: color,
                            backgroundColor: color.withAlpha(30),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            '${counts[s.key]} รายการ · ${(pct * 100).toStringAsFixed(1)}%',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Text('รวม${type.label}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(baht(total),
                style: amountStyle(
                    context,
                    16,
                    type == TxType.income
                        ? context.incomeColor
                        : context.expenseColor)),
          ]),
        ),
      ],
    );
  }
}
