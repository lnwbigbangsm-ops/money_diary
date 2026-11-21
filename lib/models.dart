enum TxType { income, expense }

extension TxTypeLabel on TxType {
  String get label => this == TxType.income ? 'รายรับ' : 'รายจ่าย';
}

/// หมวดหมู่ (เมนู) ที่ผู้ใช้เพิ่ม/แก้ไขเองได้
class Category {
  final String id;
  String name;
  String iconKey;
  int color;
  TxType type;

  Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.color,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': iconKey,
        'color': color,
        'type': type.name,
      };

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as String,
        name: j['name'] as String,
        iconKey: (j['icon'] as String?) ?? 'other',
        color: (j['color'] as int?) ?? 0xFF546E7A,
        type: TxType.values.byName(j['type'] as String),
      );
}

/// รายการรายรับ/รายจ่าย 1 รายการ
class Entry {
  final String id;
  TxType type;
  String categoryId;
  double amount;
  String note;
  DateTime date; // เก็บเฉพาะวันที่
  final DateTime createdAt;

  Entry({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.amount,
    required this.note,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'categoryId': categoryId,
        'amount': amount,
        'note': note,
        'date': date.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
        id: j['id'] as String,
        type: TxType.values.byName(j['type'] as String),
        categoryId: j['categoryId'] as String,
        amount: (j['amount'] as num).toDouble(),
        note: (j['note'] as String?) ?? '',
        date: DateTime.parse(j['date'] as String),
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

/// ผลรวมรายรับ รายจ่าย และคงเหลือ
class Totals {
  final double income;
  final double expense;
  const Totals(this.income, this.expense);

  double get balance => income - expense;

  factory Totals.of(Iterable<Entry> entries) {
    double inc = 0, exp = 0;
    for (final e in entries) {
      if (e.type == TxType.income) {
        inc += e.amount;
      } else {
        exp += e.amount;
      }
    }
    return Totals(inc, exp);
  }
}
