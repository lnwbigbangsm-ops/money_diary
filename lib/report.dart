import 'dart:convert';

import 'models.dart';
import 'store.dart';
import 'utils.dart';

String buildMonthlyReportHtml(AppStore store, int year, int month) {
  final now = DateTime.now();
  final first = DateTime(year, month);
  final monthDays = daysInMonth(year, month);
  final last = DateTime(year, month, monthDays);
  final previous = DateTime(year, month - 1);
  final current = DateTime(now.year, now.month);
  final int elapsedDays;
  if (first.isBefore(current)) {
    elapsedDays = monthDays;
  } else if (first == current) {
    elapsedDays = now.day;
  } else {
    elapsedDays = 0;
  }

  final entries = store.entriesInMonth(year, month);
  final totals = Totals.of(entries);
  final prior = Totals.of(store.entriesInMonth(previous.year, previous.month));
  final closing = store.balanceUntil(last);
  final average = elapsedDays == 0 ? 0.0 : totals.expense / elapsedDays;
  final savingRate =
      totals.income == 0 ? '-' : _percent(totals.balance / totals.income * 100);
  final categories = {
    for (final category in store.categories) category.id: category
  };
  final byDay = <int, List<Entry>>{};
  final spendingDays = <int>{};
  Entry? biggestExpense;

  for (final entry in entries) {
    byDay.putIfAbsent(entry.date.day, () => <Entry>[]).add(entry);
    if (entry.type == TxType.expense && entry.amount > 0) {
      spendingDays.add(entry.date.day);
      if (biggestExpense == null || entry.amount > biggestExpense.amount) {
        biggestExpense = entry;
      }
    }
  }

  final days = byDay.keys.toList()..sort();
  final daily = {for (final day in days) day: Totals.of(byDay[day]!)};
  final expenseGroups = _groupCategories(entries, TxType.expense, categories);
  final incomeGroups = _groupCategories(entries, TxType.income, categories);
  final monthLabel = thaiMonthYear(year, month);
  final generated = '${thaiDate(now)} เวลา ${_twoDigits(now.hour)}:'
      '${_twoDigits(now.minute)} น.';
  final html = StringBuffer('''
<!doctype html>
<html lang="th">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>รายงานรายรับรายจ่ายประจำเดือน $monthLabel</title>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Noto+Sans+Thai:wght@400;600;700&amp;display=swap">
<style>
  :root { color-scheme: light; --teal: #006B56; --line: #dce7e3; }
  * { box-sizing: border-box; }
  body { margin: 0; background: #f3f7f5; color: #17332c; line-height: 1.55;
    font: 400 14px/1.55 "Noto Sans Thai", system-ui, Tahoma, sans-serif;
    font-variant-numeric: tabular-nums; }
  main { max-width: 960px; margin: auto; padding: clamp(12px, 4vw, 32px); }
  header { padding: 0 0 16px; border-bottom: 3px solid var(--teal); }
  h1, h2, h3, p { margin: 0; }
  h1 { color: var(--teal); font-size: clamp(1.4rem, 4vw, 2rem); }
  h2 { color: var(--teal); font-size: 1.12rem; margin-bottom: 8px; }
  h3 { font-size: 1rem; margin: 12px 0 4px; }
  .month { font-size: 1.2rem; font-weight: 700; }
  .muted { color: #4a6159; }
  .income { color: #08724B; }
  .expense { color: #A33343; }
  .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
    gap: 8px; }
  .metric, .card, .panel { padding: 12px; border: 1px solid var(--line);
    border-radius: 12px; background: #fff; }
  .metric { background: #f6faf8; }
  .metric strong { display: block; font-size: 1.15rem; overflow-wrap: anywhere; }
  section { margin-top: 16px; }
  ul { margin: 0; padding-inline-start: 22px; }
  li { margin-block: 3px; }
  table { width: 100%; border-collapse: collapse; }
  th, td { padding: 6px 5px; text-align: start; vertical-align: top;
    border-bottom: 1px solid var(--line); overflow-wrap: anywhere; }
  thead th, tfoot th, tfoot td { color: var(--teal); background: #edf5f1; }
  .num { text-align: end; white-space: nowrap; }
  .note { white-space: pre-wrap; overflow-wrap: anywhere; }
  .track { display: block; margin-top: 5px; height: 5px; border-radius: 5px;
    background: #e5eeea; overflow: hidden; }
  .track span { display: block; height: 100%; border-radius: inherit; }
  .table-wrap { overflow-x: auto; }
  @page { size: A4 portrait; margin: 12mm; }
  @media print {
    body { background: #fff; font-size: 10pt; }
    main { max-width: none; padding: 0; }
    header, .card, .metric, tr, li { page-break-inside: avoid; break-inside: avoid; }
    h2, h3 { page-break-after: avoid; break-after: avoid; }
    thead { display: table-header-group; }
    tfoot { display: table-row-group; }
    .table-wrap { overflow: visible; }
    .track { print-color-adjust: exact; -webkit-print-color-adjust: exact; }
    .transactions tr:first-child { break-before: avoid; }
  }
</style>
</head>
<body>
<main>
<header>
  <h1>รายงานรายรับรายจ่ายประจำเดือน</h1>
  <p class="month">$monthLabel</p>
  <p class="muted">สร้างรายงานเมื่อ $generated</p>
</header>

<section class="card">
  <h2>สรุปประจำเดือน</h2>
  <div class="grid">
    ${_metric('รายรับ', _baht(totals.income), 'income')}
    ${_metric('รายจ่าย', _baht(totals.expense), 'expense')}
    ${_metric('คงเหลือ', _baht(totals.balance), _balanceClass(totals.balance))}
    ${_metric('อัตราการออม', savingRate)}
    ${_metric('รายจ่ายเฉลี่ยต่อวัน', _baht(average))}
    ${_metric('จำนวนรายการ', '${entries.length} รายการ')}
    ${_metric('ยอดสะสม ณ สิ้นเดือน', _baht(closing), _balanceClass(closing))}
  </div>
  <p class="muted">รายจ่ายเฉลี่ยคำนวณจาก $elapsedDays วัน</p>
</section>
''');

  if (entries.isEmpty) {
    html.write('''
<section class="card">
  <h2>รายการเดือนนี้</h2>
  <p>เดือนนี้ยังไม่มีรายการรายรับหรือรายจ่าย เมื่อบันทึกรายการแล้ว รายละเอียดจะแสดงในรายงานนี้</p>
</section>
''');
  }

  html.write('''
<section class="card table-wrap">
  <h2>เทียบกับเดือนก่อน</h2>
  <table>
    <thead><tr><th scope="col">ยอดรวม (บาท)</th>
      <th scope="col" class="num">${thaiMonthYear(previous.year, previous.month)}</th>
      <th scope="col" class="num">เดือนนี้</th>
      <th scope="col" class="num">เปลี่ยนแปลง</th>
      <th scope="col" class="num">ร้อยละ</th></tr></thead>
    <tbody>
      ${_comparisonRow('รายรับ', totals.income, prior.income)}
      ${_comparisonRow('รายจ่าย', totals.expense, prior.expense)}
      ${_comparisonRow('คงเหลือ', totals.balance, prior.balance)}
    </tbody>
  </table>
</section>
''');

  if (entries.isNotEmpty) {
    html.write(
        _categorySection('รายจ่ายตามหมวดหมู่', expenseGroups, totals.expense));
    html.write(
        _categorySection('รายรับตามหมวดหมู่', incomeGroups, totals.income));

    final highlights = <String>[];
    var highestDay = 0;
    var highestExpense = 0.0;
    for (final day in days) {
      final expense = daily[day]!.expense;
      if (expense > highestExpense) {
        highestDay = day;
        highestExpense = expense;
      }
    }
    if (highestDay != 0) {
      final label = thaiDate(DateTime(year, month, highestDay));
      highlights
          .add('วันที่ใช้จ่ายสูงสุดคือวัน$label รวม ${_baht(highestExpense)}');
    }
    if (biggestExpense != null) {
      final category = _categoryName(categories[biggestExpense.categoryId]);
      final note = biggestExpense.note.trim();
      final detail = note.isEmpty ? '' : ' (${_escape(note)})';
      highlights.add('รายจ่ายรายการใหญ่ที่สุดอยู่ในหมวด $category$detail '
          'จำนวน ${_baht(biggestExpense.amount)}');
    }
    if (totals.expense > 0 && expenseGroups.isNotEmpty) {
      final top = expenseGroups.first;
      final share = _percent(top.amount / totals.expense * 100);
      highlights.add('หมวด${_categoryName(top.category)}มีรายจ่ายสูงสุด '
          'คิดเป็น $share ของรายจ่ายทั้งหมด');
    }
    if (elapsedDays > 0) {
      final noSpending =
          elapsedDays - spendingDays.where((day) => day <= elapsedDays).length;
      highlights.add(
          'ในช่วง $elapsedDays วันที่นำมานับ มี $noSpending วันที่ไม่มีรายจ่าย');
    }
    if (totals.balance != 0) {
      final direction = totals.balance > 0 ? 'เป็นบวก' : 'ติดลบ';
      final period =
          first.isBefore(current) ? 'สิ้นเดือน' : 'ตามรายการที่บันทึก';
      highlights
          .add('ยอดคงเหลือ$period$direction ${_baht(totals.balance.abs())}');
    }
    if (highlights.isNotEmpty) {
      html.write('<section class="card"><h2>เรื่องสำคัญเดือนนี้</h2><ul>');
      for (final highlight in highlights) {
        html.write('<li>$highlight</li>');
      }
      html.write('</ul></section>');
    }

    html.write('''
<section class="panel table-wrap">
  <h2>สรุปรายวัน</h2>
  <table>
    <thead><tr><th scope="col">วันที่</th><th scope="col" class="num">รายรับ</th>
      <th scope="col" class="num">รายจ่าย</th><th scope="col" class="num">สุทธิ</th>
      <th scope="col" class="num">ยอดสะสม</th></tr></thead>
    <tbody>
''');
    for (final day in days) {
      final date = DateTime(year, month, day);
      final sum = daily[day]!;
      html.write('<tr><th scope="row">${thaiShortDate(date)}</th>'
          '${_amountCell(sum.income, 'income')}${_amountCell(sum.expense, 'expense')}'
          '${_amountCell(sum.balance, _balanceClass(sum.balance))}'
          '${_amountCell(store.balanceUntil(date))}</tr>');
    }
    html.write('''
    </tbody><tfoot><tr><th scope="row">รวมเดือน (บาท)</th>
      ${_amountCell(totals.income, 'income')}${_amountCell(totals.expense, 'expense')}
      ${_amountCell(totals.balance, _balanceClass(totals.balance))}${_amountCell(closing)}
    </tr></tfoot>
  </table>
</section>

<section class="panel">
  <h2>รายการทั้งหมด</h2>
''');
    for (final day in days) {
      html.write('''
  <h3>${thaiDate(DateTime(year, month, day))}</h3>
  <div class="table-wrap"><table class="transactions">
    <thead><tr><th scope="col">ประเภท</th><th scope="col">หมวดหมู่</th>
      <th scope="col">หมายเหตุ</th><th scope="col" class="num">จำนวน (บาท)</th>
    </tr></thead><tbody>
''');
      for (final entry in byDay[day]!) {
        final income = entry.type == TxType.income;
        final color = income ? 'income' : 'expense';
        final sign = income ? '+' : '−';
        final note = entry.note.trim().isEmpty ? '-' : _escape(entry.note);
        html.write(
            '<tr><td class="$color">${income ? 'รายรับ' : 'รายจ่าย'}</td>'
            '<td>${_categoryName(categories[entry.categoryId])}</td>'
            '<td class="note">$note</td>'
            '<td class="num $color">$sign${fmtMoney(entry.amount)}</td></tr>');
      }
      html.write('</tbody></table></div>');
    }
    html.write('</section>');
  }

  html.write('</main></body></html>');
  return html.toString();
}

String _escape(String value) => const HtmlEscape().convert(value);
String _twoDigits(int value) => value.toString().padLeft(2, '0');
String _baht(double value) => '${fmtMoney(value)} บาท';
String _percent(double value) => '${value.toStringAsFixed(1)}%';
String _balanceClass(double value) => value < 0 ? 'expense' : 'income';
String _categoryName(Category? category) =>
    _escape(category?.name ?? 'ไม่ระบุหมวดหมู่');

String _metric(String label, String value, [String valueClass = '']) =>
    '<div class="metric"><span>$label</span><strong class="$valueClass">'
    '$value</strong></div>';

String _amountCell(double value, [String valueClass = '']) =>
    '<td class="num $valueClass">${fmtMoney(value)}</td>';

String _comparisonRow(String label, double value, double previous) {
  final change = value - previous;
  final amount = change > 0 ? '+${fmtMoney(change)}' : fmtMoney(change);
  final percent = previous == 0
      ? '-'
      : '${change > 0 ? '+' : ''}${_percent(change / previous.abs() * 100)}';
  return '<tr><th scope="row">$label</th>${_amountCell(previous)}'
      '${_amountCell(value)}<td class="num">$amount</td>'
      '<td class="num">$percent</td></tr>';
}

class _CategoryGroup {
  _CategoryGroup(this.category);

  final Category? category;
  int count = 0;
  double amount = 0;
}

List<_CategoryGroup> _groupCategories(
  List<Entry> entries,
  TxType type,
  Map<String, Category> categories,
) {
  final groups = <String?, _CategoryGroup>{};
  for (final entry in entries) {
    if (entry.type != type) continue;
    final category = categories[entry.categoryId];
    final group =
        groups.putIfAbsent(category?.id, () => _CategoryGroup(category));
    group.count++;
    group.amount += entry.amount;
  }
  return groups.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
}

String _categorySection(
    String title, List<_CategoryGroup> groups, double total) {
  final html = StringBuffer('<section class="panel"><h2>$title</h2>');
  if (groups.isEmpty) {
    html.write('<p class="muted">เดือนนี้ไม่มีรายการประเภทนี้</p>');
  } else {
    html.write('''
<div class="table-wrap"><table>
  <thead><tr><th scope="col">หมวดหมู่</th><th scope="col" class="num">รายการ</th>
    <th scope="col" class="num">จำนวน (บาท)</th>
    <th scope="col" class="num">สัดส่วน</th></tr></thead><tbody>
''');
    for (final group in groups) {
      final share = total == 0 ? 0.0 : group.amount / total * 100;
      final width = share.clamp(0.0, 100.0).toStringAsFixed(2);
      final rgb = ((group.category?.color ?? 0xFF546E7A) & 0xFFFFFF)
          .toRadixString(16)
          .padLeft(6, '0');
      html.write('<tr><th scope="row">${_categoryName(group.category)}'
          '<span class="track" aria-hidden="true"><span '
          'style="width:$width%;background:#$rgb"></span></span></th>'
          '<td class="num">${group.count}</td>${_amountCell(group.amount)}'
          '<td class="num">${_percent(share)}</td></tr>');
    }
    html.write('</tbody></table></div>');
  }
  html.write('</section>');
  return html.toString();
}
