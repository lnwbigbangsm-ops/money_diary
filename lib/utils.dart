import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// ไอคอนที่เลือกใช้กับหมวดหมู่ได้ (เก็บเป็น key เพื่อให้ build release ได้)
const Map<String, IconData> kCategoryIcons = {
  'food': Icons.restaurant,
  'coffee': Icons.local_cafe,
  'grocery': Icons.local_grocery_store,
  'transport': Icons.directions_car,
  'fuel': Icons.local_gas_station,
  'shopping': Icons.shopping_bag,
  'bill': Icons.receipt_long,
  'home': Icons.home,
  'phone': Icons.phone_android,
  'health': Icons.local_hospital,
  'education': Icons.school,
  'fun': Icons.movie,
  'travel': Icons.flight,
  'gift': Icons.card_giftcard,
  'pet': Icons.pets,
  'kid': Icons.child_care,
  'sport': Icons.fitness_center,
  'salary': Icons.work,
  'money': Icons.payments,
  'bonus': Icons.emoji_events,
  'sale': Icons.storefront,
  'invest': Icons.trending_up,
  'saving': Icons.savings,
  'other': Icons.category,
};

IconData iconOf(String key) => kCategoryIcons[key] ?? Icons.category;

const List<int> kCategoryColors = [
  0xFFE53935,
  0xFFD81B60,
  0xFF8E24AA,
  0xFF5E35B1,
  0xFF3949AB,
  0xFF1E88E5,
  0xFF039BE5,
  0xFF00897B,
  0xFF43A047,
  0xFF7CB342,
  0xFFFDD835,
  0xFFFB8C00,
  0xFFF4511E,
  0xFF6D4C41,
  0xFF546E7A,
];

const kIncomeColor = Color(0xFF2E7D32);
const kExpenseColor = Color(0xFFC62828);

final NumberFormat _money = NumberFormat('#,##0.00');
String fmtMoney(double v) => _money.format(v);
String fmtSigned(double v) => '${v >= 0 ? '+' : '-'}${_money.format(v.abs())}';

const _thMonths = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];
const _thMonthsFull = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];
const _thWeekdays = [
  'จันทร์',
  'อังคาร',
  'พุธ',
  'พฤหัสฯ',
  'ศุกร์',
  'เสาร์',
  'อาทิตย์'
];

/// เช่น "ศุกร์ 21 พ.ย. 2569"
String thaiDate(DateTime d) =>
    '${_thWeekdays[d.weekday - 1]} ${d.day} ${_thMonths[d.month - 1]} ${d.year + 543}';

/// เช่น "21 พ.ย. 69"
String thaiShortDate(DateTime d) =>
    '${d.day} ${_thMonths[d.month - 1]} ${(d.year + 543) % 100}';

/// เช่น "พฤศจิกายน 2569"
String thaiMonthYear(int year, int month) =>
    '${_thMonthsFull[month - 1]} ${year + 543}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

/// คำนวณนิพจน์ในช่องจำนวนเงิน เช่น "45+30*2" หรือ "(120-20)/4"
/// รองรับ + - * / × ÷ x วงเล็บ และเครื่องหมายจุลภาค คืนค่า null ถ้าไม่ถูกต้อง
double? evalExpression(String input) {
  final s = input
      .replaceAll(',', '')
      .replaceAll(' ', '')
      .replaceAll('×', '*')
      .replaceAll('x', '*')
      .replaceAll('X', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-');
  if (s.isEmpty) return null;
  final p = _Parser(s);
  try {
    final v = p.expr();
    if (p.pos != s.length || v.isNaN || v.isInfinite) return null;
    return v;
  } on FormatException {
    return null;
  }
}

bool hasOperator(String s) =>
    RegExp(r'[+\-*/×÷x()−]').hasMatch(s.replaceFirst(RegExp(r'^\s*-'), ''));

class _Parser {
  final String s;
  int pos = 0;
  _Parser(this.s);

  String? get _c => pos < s.length ? s[pos] : null;

  double expr() {
    var v = term();
    while (_c == '+' || _c == '-') {
      final op = s[pos++];
      final r = term();
      v = op == '+' ? v + r : v - r;
    }
    return v;
  }

  double term() {
    var v = factor();
    while (_c == '*' || _c == '/') {
      final op = s[pos++];
      final r = factor();
      v = op == '*' ? v * r : v / r;
    }
    return v;
  }

  double factor() {
    if (_c == '-') {
      pos++;
      return -factor();
    }
    if (_c == '+') {
      pos++;
      return factor();
    }
    if (_c == '(') {
      pos++;
      final v = expr();
      if (_c != ')') throw const FormatException('missing )');
      pos++;
      return v;
    }
    final start = pos;
    while (_c != null && '0123456789.'.contains(_c!)) {
      pos++;
    }
    if (start == pos) throw const FormatException('number expected');
    final n = double.tryParse(s.substring(start, pos));
    if (n == null) throw const FormatException('bad number');
    return n;
  }
}

/// แสดงจำนวนเงินแบบไม่มีทศนิยมเกินจำเป็น สำหรับใส่กลับในช่องกรอก
String plainAmount(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
