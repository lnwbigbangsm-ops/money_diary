import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/entry_form.dart';

/// หน้าบันทึกรายวัน: ยอดของวัน + รายการทั้งหมดของวันนั้น
class DailyScreen extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;

  const DailyScreen(
      {super.key, required this.date, required this.onDateChanged});

  Future<void> _pickDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) onDateChanged(d);
  }

  Widget _group(
      BuildContext context, String title, List<Entry> list, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title,
            trailingText: '${list.length} รายการ · ${fmtMoney(total)}'),
        Panel(children: [
          for (final e in list)
            Dismissible(
              key: ValueKey(e.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Theme.of(context).colorScheme.errorContainer,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 24),
                child: Icon(Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.onErrorContainer),
              ),
              onDismissed: (_) {
                final s = StoreScope.read(context);
                s.deleteEntry(e);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: const Text('ลบรายการแล้ว'),
                    action: SnackBarAction(
                        label: 'เลิกทำ', onPressed: () => s.addEntry(e)),
                  ));
              },
              child: EntryRow(
                  entry: e, onTap: () => showEntryForm(context, existing: e)),
            ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.entriesOn(date);
    final totals = Totals.of(list);
    final cumulative = store.balanceUntil(date);
    final isToday = sameDay(date, DateTime.now());
    final expenses = list.where((e) => e.type == TxType.expense).toList();
    final incomes = list.where((e) => e.type == TxType.income).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายวัน'),
        actions: [
          if (!isToday)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => onDateChanged(DateTime.now()),
                icon: const Icon(Icons.today_rounded, size: 18),
                label: const Text('วันนี้'),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 112),
        children: [
          StepperBar(
            caption: isToday ? 'วันนี้' : null,
            label: thaiDate(date),
            onPrev: () => onDateChanged(date.subtract(const Duration(days: 1))),
            onNext: () => onDateChanged(date.add(const Duration(days: 1))),
            onTapLabel: () => _pickDate(context),
          ),
          BalanceHero(
            label: 'คงเหลือวันนี้',
            totals: totals,
            footer: [
              HeroFooterRow(label: 'ยอดสะสมถึงวันนี้', value: baht(cumulative))
            ],
          ),
          if (list.isEmpty) ...[
            const SizedBox(height: 16),
            const EmptyHint(
              icon: Icons.receipt_long_outlined,
              text: 'ยังไม่มีรายการในวันนี้',
            ),
          ] else ...[
            if (expenses.isNotEmpty)
              _group(context, 'รายจ่าย', expenses, totals.expense),
            if (incomes.isNotEmpty)
              _group(context, 'รายรับ', incomes, totals.income),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'แตะเพื่อแก้ไข · ปัดซ้ายเพื่อลบ',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showEntryForm(context, initialDate: date),
        icon: const Icon(Icons.add_rounded),
        label: const Text('เพิ่มรายการ',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
