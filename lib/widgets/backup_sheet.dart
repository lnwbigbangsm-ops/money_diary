import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../backup.dart';
import '../services/file_saver.dart';
import '../store.dart';
import '../utils.dart';
import 'common.dart';

/// แผ่นเมนู สำรองข้อมูล / กู้คืนข้อมูล
void showBackupSheet(BuildContext context) {
  final store = StoreScope.read(context);
  final messenger = ScaffoldMessenger.of(context);

  Future<void> backup() async {
    final now = DateTime.now();
    try {
      await saveTextFile(backupFileName(now), buildBackupJson(store, now: now),
          'application/json');
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'สำรองข้อมูลแล้ว เก็บไฟล์ไว้ในที่ปลอดภัย เช่น Google Drive')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('สำรองไม่สำเร็จ: $e')));
    }
  }

  Future<void> restore() async {
    final BackupData data;
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'เลือกไฟล์สำรองข้อมูล (.json)',
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      if (file == null) return; // ผู้ใช้กดยกเลิก
      data = parseBackup(
          utf8.decode(await file.readAsBytes(), allowMalformed: true));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('เปิดไฟล์ไม่สำเร็จ: $e')));
      return;
    }
    if (!context.mounted) return;

    final when = data.exportedAt == null
        ? ''
        : ' (สำรองเมื่อ ${thaiDate(data.exportedAt!.toLocal())})';
    final mode = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('กู้คืนข้อมูล'),
        content: Text(
          'ไฟล์นี้มี ${data.entries.length} รายการ ${data.categories.length} หมวด$when\n\n'
          '• รวมกับข้อมูลเดิม: เพิ่มเฉพาะรายการที่ยังไม่มี ข้อมูลเดิมอยู่ครบ\n'
          '• แทนที่ทั้งหมด: ลบข้อมูลในเครื่องตอนนี้ แล้วใช้ข้อมูลจากไฟล์แทน',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('ยกเลิก')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('แทนที่ทั้งหมด')),
          FilledButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('รวมกับข้อมูลเดิม')),
        ],
      ),
    );
    if (mode == null || !context.mounted) return;

    if (mode) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('แทนที่ข้อมูลทั้งหมด?'),
          content: Text(
              'ข้อมูลตอนนี้ ${store.entries.length} รายการ จะถูกลบและกู้คืนไม่ได้ '
              'ถ้ายังไม่แน่ใจ ให้กด "สำรองข้อมูล" เก็บไว้ก่อน'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('ยกเลิก')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(c).colorScheme.error),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('แทนที่'),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }

    final (cats, items) =
        await store.restore(data.categories, data.entries, replace: mode);
    messenger.showSnackBar(SnackBar(
      content: Text(mode
          ? 'กู้คืนแล้ว: $items รายการ $cats หมวด'
          : (items == 0 && cats == 0
              ? 'ไม่มีข้อมูลใหม่ ข้อมูลในไฟล์มีอยู่ในเครื่องแล้ว'
              : 'รวมข้อมูลแล้ว: เพิ่ม $items รายการ $cats หมวด')),
    ));
  }

  Widget tile(BuildContext c, IconData icon, String title, String sub,
      Future<void> Function() action) {
    final colors = Theme.of(c).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colors.onPrimaryContainer, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sub, style: Theme.of(c).textTheme.bodySmall),
      onTap: () {
        Navigator.pop(c);
        action();
      },
    );
  }

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('สำรอง / กู้คืนข้อมูล',
                style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
                'ตอนนี้มี ${store.entries.length} รายการ ${store.categories.length} หมวด',
                style:
                    TextStyle(color: Theme.of(c).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            Panel(dividerIndent: 56, children: [
              tile(
                  c,
                  Icons.cloud_upload_outlined,
                  'สำรองข้อมูล',
                  'บันทึกทุกอย่างเป็นไฟล์ .json เก็บไว้ หรือย้ายไปเครื่องอื่น',
                  backup),
              tile(c, Icons.settings_backup_restore_rounded, 'กู้คืนจากไฟล์',
                  'เลือกไฟล์ .json ที่เคยสำรองไว้', restore),
            ]),
          ],
        ),
      ),
    ),
  );
}
