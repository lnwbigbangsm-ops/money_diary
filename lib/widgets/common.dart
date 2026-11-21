import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';

String baht(double v) => '${v < 0 ? '−' : ''}฿${fmtMoney(v.abs())}';

/// การ์ดหลัก: ยอดคงเหลือตัวใหญ่ + รายรับ/รายจ่าย + บรรทัดเสริม
class BalanceHero extends StatelessWidget {
  final String label;
  final Totals totals;
  final List<Widget> footer;

  const BalanceHero({
    super.key,
    required this.label,
    required this.totals,
    this.footer = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = colors.onPrimaryContainer;

    Widget subtotal(String text, double value, IconData icon) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: ink.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 13, color: ink),
                ),
                const SizedBox(width: 6),
                Text(text,
                    style: TextStyle(color: ink.withAlpha(200), fontSize: 13)),
              ]),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child:
                    Text(fmtMoney(value), style: amountStyle(context, 18, ink)),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(color: ink.withAlpha(200), fontSize: 13)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(baht(totals.balance),
                style: amountStyle(context, 36, ink)),
          ),
          const SizedBox(height: 16),
          Row(children: [
            subtotal('รายรับ', totals.income, Icons.south_west_rounded),
            const SizedBox(width: 12),
            subtotal('รายจ่าย', totals.expense, Icons.north_east_rounded),
          ]),
          if (footer.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, color: ink.withAlpha(40)),
            ),
            DefaultTextStyle.merge(
              style: TextStyle(color: ink, fontSize: 13),
              child: Column(children: footer),
            ),
          ],
        ],
      ),
    );
  }
}

/// บรรทัด "ป้าย ........ ค่า" ใช้ใต้การ์ดหลัก
class HeroFooterRow extends StatelessWidget {
  final String label;
  final String value;
  const HeroFooterRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onPrimaryContainer;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(
            child: Text(label, style: TextStyle(color: ink.withAlpha(200)))),
        Text(value,
            style: amountStyle(context, 14, ink, weight: FontWeight.w600)),
      ]),
    );
  }
}

/// แถบเลื่อนวัน/เดือน
class StepperBar extends StatelessWidget {
  final String label;
  final String? caption;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback? onTapLabel;

  const StepperBar({
    super.key,
    required this.label,
    this.caption,
    required this.onPrev,
    required this.onNext,
    this.onTapLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget arrow(IconData icon, VoidCallback onTap) => IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: colors.surfaceContainerLow,
            foregroundColor: colors.onSurface,
            minimumSize: const Size(44, 44),
          ),
          onPressed: onTap,
          icon: Icon(icon),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          arrow(Icons.chevron_left_rounded, onPrev),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTapLabel,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    if (caption != null)
                      Text(caption!,
                          style: TextStyle(
                              fontSize: 12,
                              color: colors.primary,
                              fontWeight: FontWeight.w600)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(label,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        if (onTapLabel != null) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more_rounded,
                              size: 20, color: colors.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          arrow(Icons.chevron_right_rounded, onNext),
        ],
      ),
    );
  }
}

/// ไอคอนหมวดแบบสี่เหลี่ยมมุมมน
class CategoryAvatar extends StatelessWidget {
  final Category? category;
  final double size;
  const CategoryAvatar({super.key, required this.category, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final color = category != null ? Color(category!.color) : Colors.grey;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(dark ? 55 : 32),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(iconOf(category?.iconKey ?? 'other'),
          color: dark ? Color.lerp(color, Colors.white, 0.35) : color,
          size: size * 0.5),
    );
  }
}

/// พื้นที่จัดกลุ่ม (พาเนลขาวมุมมน มีเส้นคั่นระหว่างแถว)
class Panel extends StatelessWidget {
  final List<Widget> children;
  final double dividerIndent;
  final EdgeInsetsGeometry padding;

  const Panel({
    super.key,
    required this.children,
    this.dividerIndent = 68,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: padding,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(indent: dividerIndent, height: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// หัวข้อของแต่ละส่วน
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailingText;
  final Widget? trailing;
  const SectionHeader(this.title,
      {super.key, this.trailingText, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          if (trailingText != null)
            Text(trailingText!, style: theme.textTheme.bodySmall),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// แถวรายการ 1 รายการ
class EntryRow extends StatelessWidget {
  final Entry entry;
  final VoidCallback? onTap;
  final bool showDate;

  const EntryRow(
      {super.key, required this.entry, this.onTap, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = StoreScope.of(context).categoryById(entry.categoryId);
    final income = entry.type == TxType.income;
    final sub = [
      if (showDate) thaiShortDate(entry.date),
      if (entry.note.isNotEmpty) entry.note,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              CategoryAvatar(category: cat),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat?.name ?? 'ไม่ระบุหมวด',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 15)),
                    if (sub.isNotEmpty)
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${income ? '+' : '−'}${fmtMoney(entry.amount)}',
                style: amountStyle(
                  context,
                  16,
                  income ? context.incomeColor : theme.colorScheme.onSurface,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// สถานะว่างแบบกะทัดรัด
class EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const EmptyHint({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 24, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// ถามก่อนออกจากฟอร์มที่ยังไม่ได้บันทึก
/// คืนค่า true = ออกโดยไม่บันทึก, false = อยู่หน้าเดิมเพื่อกดบันทึก
Future<bool> confirmLeaveUnsaved(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.edit_note_rounded),
      title: const Text('ยังไม่ได้บันทึก'),
      content: const Text('ต้องการบันทึกข้อมูลที่กรอกไว้ก่อนไหม?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('ไม่บันทึก')),
        FilledButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('บันทึกก่อน')),
      ],
    ),
  );
  return leave ?? false;
}
