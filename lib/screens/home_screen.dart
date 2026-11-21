import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets/common.dart';
import '../widgets/entry_form.dart';
import '../widgets/backup_sheet.dart';
import '../widgets/export_sheet.dart';

/// หน้าหลัก: ภาพรวมเดือนนี้ ปุ่มเพิ่มด่วน เมนูหลัก และรายการล่าสุด
class HomeScreen extends StatelessWidget {
  /// เปิดแท็บ: 1 = รายวัน, 2 = รายเดือน, 3 = หมวดหมู่
  final ValueChanged<int> onOpenTab;
  const HomeScreen({super.key, required this.onOpenTab});

  String _greeting(DateTime now) {
    final h = now.hour;
    if (h < 5) return 'ดึกแล้ว พักผ่อนบ้างนะ';
    if (h < 12) return 'สวัสดีตอนเช้า';
    if (h < 17) return 'สวัสดีตอนบ่าย';
    return 'สวัสดีตอนเย็น';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final store = StoreScope.of(context);
    final now = DateTime.now();
    final today = dateOnly(now);

    final month = Totals.of(store.entriesInMonth(now.year, now.month));
    final todayList = store.entriesOn(today);
    final todayExpense = Totals.of(todayList).expense;
    final recent = [...store.entries]..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });

    final menus = [
      _MenuItem(
          Icons.today_rounded,
          'รายวัน',
          todayList.isEmpty
              ? 'วันนี้ยังไม่มีรายการ'
              : 'วันนี้ ${todayList.length} รายการ',
          colors.primaryContainer,
          colors.onPrimaryContainer,
          () => onOpenTab(1)),
      _MenuItem(
          Icons.calendar_month_rounded,
          'ปฏิทินรายเดือน',
          'สรุป ${thaiMonthYear(now.year, now.month)}',
          colors.tertiaryContainer,
          colors.onTertiaryContainer,
          () => onOpenTab(2)),
      _MenuItem(
          Icons.category_rounded,
          'หมวดหมู่',
          '${store.categories.length} หมวด เพิ่มเองได้',
          colors.secondaryContainer,
          colors.onSecondaryContainer,
          () => onOpenTab(3)),
      _MenuItem(
          Icons.ios_share_rounded,
          'ส่งออกรายงาน',
          'รายงาน / CSV ของเดือนนี้',
          colors.surfaceContainerHigh,
          colors.onSurface,
          () => showExportSheet(context, now.year, now.month)),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // หัวหน้า
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(now),
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 2),
                        Text(thaiDate(today),
                            style: TextStyle(color: colors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset('assets/icon/icon.png',
                        width: 44, height: 44),
                  ),
                ],
              ),
            ),

            BalanceHero(
              label: 'คงเหลือเดือน${thaiMonthYear(now.year, now.month)}',
              totals: month,
              footer: [
                HeroFooterRow(label: 'ใช้ไปวันนี้', value: baht(todayExpense)),
                HeroFooterRow(
                    label: 'ยอดสะสมทั้งหมด',
                    value: baht(store.balanceUntil(today))),
              ],
            ),
            const SizedBox(height: 12),

            // เพิ่มด่วน
            Row(children: [
              Expanded(
                child: _QuickAdd(
                  icon: Icons.remove_rounded,
                  label: 'จดรายจ่าย',
                  onTap: () => showEntryForm(context,
                      initialDate: today, initialType: TxType.expense),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAdd(
                  icon: Icons.add_rounded,
                  label: 'จดรายรับ',
                  onTap: () => showEntryForm(context,
                      initialDate: today, initialType: TxType.income),
                ),
              ),
            ]),

            const SectionHeader('เมนู'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [for (final m in menus) _MenuTile(item: m)],
            ),
            const SizedBox(height: 12),
            Panel(children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.backup_outlined,
                      color: colors.onPrimaryContainer),
                ),
                title: const Text('สำรอง / กู้คืนข้อมูล',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'เก็บข้อมูลเป็นไฟล์ กันหาย หรือย้ายไปเครื่องอื่น'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => showBackupSheet(context),
              ),
            ]),

            SectionHeader(
              'รายการล่าสุด',
              trailing: recent.isEmpty
                  ? null
                  : TextButton(
                      onPressed: () => onOpenTab(1),
                      child: const Text('ดูรายวัน')),
            ),
            if (recent.isEmpty)
              const EmptyHint(
                icon: Icons.receipt_long_outlined,
                text: 'ยังไม่มีรายการ ลองกด "จดรายจ่าย" ด้านบนดูสิ',
              )
            else
              Panel(children: [
                for (final e in recent.take(5))
                  EntryRow(
                    entry: e,
                    showDate: true,
                    onTap: () => showEntryForm(context, existing: e),
                  ),
              ]),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color background;
  final Color ink;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.title, this.subtitle, this.background,
      this.ink, this.onTap);
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final ink = item.ink;
    return Material(
      color: item.background,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ink.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: ink, size: 24),
              ),
              const Spacer(),
              Text(item.title,
                  style: TextStyle(
                      color: ink, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink.withAlpha(190), fontSize: 12.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAdd(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}
