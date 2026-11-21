import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../report.dart';
import '../services/file_saver.dart';
import '../store.dart';
import '../utils.dart';
import 'common.dart';

enum _ExportKind { report, csv, copyCsv }

/// แผ่นเมนูส่งออกข้อมูลของเดือนที่เลือก (ใช้ทั้งหน้าหลักและหน้ารายเดือน)
void showExportSheet(BuildContext context, int year, int month) {
  final stem = 'รายรับรายจ่าย-$year-${month.toString().padLeft(2, '0')}';

  Future<void> run(_ExportKind kind) async {
    final store = StoreScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      switch (kind) {
        case _ExportKind.report:
          await saveTextFile('$stem.html',
              buildMonthlyReportHtml(store, year, month), 'text/html');
          messenger.showSnackBar(const SnackBar(
              content: Text(
                  'ส่งออกรายงานแล้ว เปิดไฟล์ในเบราว์เซอร์แล้วสั่งพิมพ์เป็น PDF ได้')));
        case _ExportKind.csv:
          // ใส่ BOM เพื่อให้ Excel อ่านภาษาไทยถูก
          await saveTextFile(
              '$stem.csv', '﻿${store.monthCsv(year, month)}', 'text/csv');
          messenger.showSnackBar(
              const SnackBar(content: Text('ส่งออกไฟล์ CSV แล้ว')));
        case _ExportKind.copyCsv:
          await Clipboard.setData(
              ClipboardData(text: store.monthCsv(year, month)));
          messenger.showSnackBar(const SnackBar(
              content: Text('คัดลอกแล้ว วางใน Excel/Google Sheets ได้เลย')));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('ส่งออกไม่สำเร็จ: $e')));
    }
  }

  Widget tile(BuildContext c, IconData icon, String title, String sub,
      _ExportKind kind) {
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
        run(kind);
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
            Text('ส่งออก ${thaiMonthYear(year, month)}',
                style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 12),
            Panel(dividerIndent: 56, children: [
              tile(
                  c,
                  Icons.description_outlined,
                  'รายงานสรุปประจำเดือน',
                  'สรุปยอด เปรียบเทียบเดือนก่อน แยกหมวด รายการทั้งหมด (.html พิมพ์เป็น PDF ได้)',
                  _ExportKind.report),
              tile(c, Icons.table_chart_outlined, 'ข้อมูลดิบ (.csv)',
                  'เปิดด้วย Excel หรือ Google Sheets', _ExportKind.csv),
              tile(c, Icons.copy_all_rounded, 'คัดลอกข้อมูล',
                  'วางลงตารางได้ทันที', _ExportKind.copyCsv),
            ]),
          ],
        ),
      ),
    ),
  );
}
