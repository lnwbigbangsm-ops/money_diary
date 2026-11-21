import 'dart:convert';

import 'models.dart';
import 'store.dart';

const _kApp = 'money_diary';
const _kVersion = 1;

/// ข้อมูลที่อ่านได้จากไฟล์สำรอง
class BackupData {
  final List<Category> categories;
  final List<Entry> entries;
  final DateTime? exportedAt;
  const BackupData(this.categories, this.entries, this.exportedAt);
}

/// สร้างไฟล์สำรองข้อมูลทั้งหมด (JSON)
String buildBackupJson(AppStore store, {DateTime? now}) {
  return const JsonEncoder.withIndent(' ').convert({
    'app': _kApp,
    'version': _kVersion,
    'exportedAt': (now ?? DateTime.now()).toIso8601String(),
    'categories': store.categories.map((c) => c.toJson()).toList(),
    'entries': store.entries.map((e) => e.toJson()).toList(),
  });
}

String backupFileName(DateTime now) {
  String p(int v) => v.toString().padLeft(2, '0');
  return 'สำรองรายรับรายจ่าย-${now.year}-${p(now.month)}-${p(now.day)}.json';
}

/// อ่านไฟล์สำรอง ถ้าไฟล์ไม่ถูกต้องจะโยน FormatException พร้อมข้อความภาษาไทย
BackupData parseBackup(String text) {
  Object? root;
  try {
    root = jsonDecode(text.startsWith('﻿') ? text.substring(1) : text);
  } catch (_) {
    throw const FormatException(
        'ไฟล์นี้ไม่ใช่ไฟล์สำรองข้อมูล (อ่าน JSON ไม่ได้)');
  }
  if (root is! Map<String, dynamic> || root['app'] != _kApp) {
    throw const FormatException('ไฟล์นี้ไม่ใช่ไฟล์สำรองของแอปรายรับรายจ่าย');
  }
  final version = root['version'];
  if (version is! int || version > _kVersion) {
    throw const FormatException(
        'ไฟล์สำรองมาจากแอปเวอร์ชันใหม่กว่า กรุณาอัปเดตแอปก่อน');
  }
  try {
    final cats = (root['categories'] as List)
        .map((x) => Category.fromJson(x as Map<String, dynamic>))
        .toList();
    final items = (root['entries'] as List)
        .map((x) => Entry.fromJson(x as Map<String, dynamic>))
        .toList();
    if (cats.isEmpty) throw const FormatException('');
    // รายการที่อ้างถึงหมวดที่ไม่มีในไฟล์ ถือว่าไฟล์เสีย
    final ids = cats.map((c) => c.id).toSet();
    if (items.any((e) => !ids.contains(e.categoryId)))
      throw const FormatException('');
    return BackupData(cats, items, DateTime.tryParse('${root['exportedAt']}'));
  } catch (_) {
    throw const FormatException('ไฟล์สำรองเสียหายหรือข้อมูลไม่ครบ');
  }
}
