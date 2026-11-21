import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'utils.dart';

final _rand = Random();
String newId() =>
    '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}${_rand.nextInt(0x7fffffff).toRadixString(36)}';

/// เก็บข้อมูลทั้งหมดของแอป และบันทึกลงเครื่องอัตโนมัติ
class AppStore extends ChangeNotifier {
  static const _kCategories = 'categories_v1';
  static const _kEntries = 'entries_v1';

  late SharedPreferences _prefs;
  final List<Category> categories = [];
  final List<Entry> entries = [];

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final c = _prefs.getString(_kCategories);
    final e = _prefs.getString(_kEntries);
    if (c != null) {
      categories.addAll(await _decodeList(_kCategories, c, Category.fromJson));
    }
    if (categories.isEmpty) categories.addAll(_defaultCategories());
    if (e != null) {
      entries.addAll(await _decodeList(_kEntries, e, Entry.fromJson));
    }
  }

  /// อ่านรายการจาก JSON แบบไม่ให้แอปพัง: ข้ามรายการที่เสีย
  /// และถ้ามีส่วนไหนเสีย เก็บข้อมูลดิบไว้ที่คีย์ `<key>_corrupt_<เวลา>` ก่อนจะถูกบันทึกทับ
  Future<List<T>> _decodeList<T>(String key, String raw,
      T Function(Map<String, dynamic>) fromJson) async {
    final result = <T>[];
    var damaged = false;
    try {
      for (final x in jsonDecode(raw) as List) {
        try {
          result.add(fromJson(x as Map<String, dynamic>));
        } catch (_) {
          damaged = true;
        }
      }
    } catch (_) {
      damaged = true;
    }
    if (damaged) {
      try {
        await _prefs.setString(
            '${key}_corrupt_${DateTime.now().millisecondsSinceEpoch}', raw);
      } catch (_) {}
    }
    return result;
  }

  Future<void> _save() async {
    notifyListeners();
    await _prefs.setString(
        _kCategories, jsonEncode(categories.map((c) => c.toJson()).toList()));
    await _prefs.setString(
        _kEntries, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  /// กู้คืนจากไฟล์สำรอง: replace = แทนที่ทั้งหมด, ไม่งั้นรวมเฉพาะที่ยังไม่มี (เทียบด้วย id)
  /// คืนค่า (จำนวนหมวดที่เพิ่ม, จำนวนรายการที่เพิ่ม)
  Future<(int, int)> restore(List<Category> cats, List<Entry> items,
      {required bool replace}) async {
    var addedCats = 0, addedEntries = 0;
    if (replace) {
      categories
        ..clear()
        ..addAll(cats);
      entries
        ..clear()
        ..addAll(items);
      addedCats = cats.length;
      addedEntries = items.length;
    } else {
      final catIds = categories.map((c) => c.id).toSet();
      for (final c in cats) {
        if (catIds.add(c.id)) {
          categories.add(c);
          addedCats++;
        }
      }
      final entryIds = entries.map((e) => e.id).toSet();
      for (final e in items) {
        if (entryIds.add(e.id)) {
          entries.add(e);
          addedEntries++;
        }
      }
    }
    await _save();
    return (addedCats, addedEntries);
  }

  List<Category> _defaultCategories() {
    Category c(String name, String icon, int color, TxType t) =>
        Category(id: newId(), name: name, iconKey: icon, color: color, type: t);
    return [
      c('อาหาร', 'food', 0xFFFB8C00, TxType.expense),
      c('เครื่องดื่ม/กาแฟ', 'coffee', 0xFF6D4C41, TxType.expense),
      c('เดินทาง', 'transport', 0xFF1E88E5, TxType.expense),
      c('ช้อปปิ้ง', 'shopping', 0xFFD81B60, TxType.expense),
      c('ค่าน้ำ/ไฟ/บิล', 'bill', 0xFF5E35B1, TxType.expense),
      c('สุขภาพ', 'health', 0xFFE53935, TxType.expense),
      c('บันเทิง', 'fun', 0xFF8E24AA, TxType.expense),
      c('อื่นๆ', 'other', 0xFF546E7A, TxType.expense),
      c('เงินเดือน', 'salary', 0xFF43A047, TxType.income),
      c('ขายของ', 'sale', 0xFF00897B, TxType.income),
      c('โบนัส', 'bonus', 0xFFFDD835, TxType.income),
      c('อื่นๆ', 'money', 0xFF7CB342, TxType.income),
    ];
  }

  // ---------- หมวดหมู่ ----------
  List<Category> categoriesOf(TxType t) =>
      categories.where((c) => c.type == t).toList();

  Category? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  int usageCount(String categoryId) =>
      entries.where((e) => e.categoryId == categoryId).length;

  Category addCategory(
      {required String name,
      required String iconKey,
      required int color,
      required TxType type}) {
    final c = Category(
        id: newId(), name: name, iconKey: iconKey, color: color, type: type);
    categories.add(c);
    _save();
    return c;
  }

  void updateCategory(Category c,
      {required String name, required String iconKey, required int color}) {
    c
      ..name = name
      ..iconKey = iconKey
      ..color = color;
    _save();
  }

  /// ลบหมวด ถ้ามีรายการใช้อยู่จะย้ายไปหมวด [moveTo]
  void deleteCategory(Category c, {Category? moveTo}) {
    if (moveTo != null) {
      for (final e in entries) {
        if (e.categoryId == c.id) e.categoryId = moveTo.id;
      }
    }
    categories.removeWhere((x) => x.id == c.id);
    _save();
  }

  void moveCategory(TxType type, int oldIndex, int newIndex) {
    // newIndex ถูกปรับตำแหน่งแล้วโดย onReorderItem
    final list = categoriesOf(type);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    categories
      ..removeWhere((c) => c.type == type)
      ..addAll(list);
    _save();
  }

  // ---------- รายการ ----------
  void addEntry(Entry e) {
    entries.add(e);
    _save();
  }

  void saveEntry(Entry e) {
    final i = entries.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      entries[i] = e;
    } else {
      entries.add(e);
    }
    _save();
  }

  void deleteEntry(Entry e) {
    entries.removeWhere((x) => x.id == e.id);
    _save();
  }

  List<Entry> entriesOn(DateTime day) {
    final list = entries.where((e) => sameDay(e.date, day)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<Entry> entriesInMonth(int year, int month) {
    final list = entries
        .where((e) => e.date.year == year && e.date.month == month)
        .toList()
      ..sort((a, b) {
        final d = b.date.compareTo(a.date);
        return d != 0 ? d : b.createdAt.compareTo(a.createdAt);
      });
    return list;
  }

  /// ยอดคงเหลือสะสมตั้งแต่เริ่มบันทึกจนถึงสิ้นวัน [day]
  double balanceUntil(DateTime day) {
    final end = dateOnly(day);
    return Totals.of(entries.where((e) => !e.date.isAfter(end))).balance;
  }

  /// ข้อมูลเดือนนั้นในรูปแบบ CSV (เปิดใน Excel/Google Sheets ได้)
  String monthCsv(int year, int month) {
    String q(String s) => '"${s.replaceAll('"', '""')}"';
    final rows = <String>['วันที่,ประเภท,หมวด,จำนวนเงิน,หมายเหตุ'];
    final list = entriesInMonth(year, month).reversed;
    for (final e in list) {
      final d = e.date;
      final date =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      rows.add([
        date,
        e.type.label,
        q(categoryById(e.categoryId)?.name ?? '-'),
        e.amount.toStringAsFixed(2),
        q(e.note),
      ].join(','));
    }
    return rows.join('\n');
  }
}

/// ให้ทุกหน้าจอเข้าถึง [AppStore] ได้ และ rebuild เมื่อข้อมูลเปลี่ยน
class StoreScope extends InheritedNotifier<AppStore> {
  const StoreScope({super.key, required AppStore store, required super.child})
      : super(notifier: store);

  /// ใช้ใน build (จะ rebuild เมื่อข้อมูลเปลี่ยน)
  static AppStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;

  /// ใช้ใน callback (ไม่ subscribe)
  static AppStore read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}
