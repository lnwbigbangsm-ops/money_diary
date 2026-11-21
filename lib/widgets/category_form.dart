import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../utils.dart';
import 'common.dart';

/// เปิดหน้าต่างเพิ่ม/แก้ไขหมวดหมู่ คืนค่าหมวดที่บันทึก (หรือ null ถ้ายกเลิก)
Future<Category?> showCategoryForm(BuildContext context,
    {Category? existing, TxType type = TxType.expense}) {
  return showDialog<Category>(
    context: context,
    builder: (_) =>
        CategoryFormDialog(existing: existing, type: existing?.type ?? type),
  );
}

class CategoryFormDialog extends StatefulWidget {
  final Category? existing;
  final TxType type;
  const CategoryFormDialog({super.key, this.existing, required this.type});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  late final TextEditingController _name;
  late TxType _type;
  late String _icon;
  late int _color;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _type = widget.type;
    _icon = e?.iconKey ?? (_type == TxType.income ? 'money' : 'other');
    _color = e?.color ?? kCategoryColors[7];
    _initialSig; // จำค่าเริ่มต้นไว้เทียบ
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  late final String _initialSig = _sig;
  String get _sig => '${_name.text.trim()}|$_icon|$_color';

  Future<void> _onLeave() async {
    if (_sig == _initialSig) {
      Navigator.pop(context);
      return;
    }
    final leave = await confirmLeaveUnsaved(context);
    if (leave && mounted) Navigator.pop(context);
  }

  void _save() {
    final store = StoreScope.read(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'กรุณาใส่ชื่อหมวด');
      return;
    }
    final dup = store.categoriesOf(_type).any((c) =>
        c.id != widget.existing?.id &&
        c.name.toLowerCase() == name.toLowerCase());
    if (dup) {
      setState(() => _error = 'มีหมวด "$name" อยู่แล้ว');
      return;
    }
    Category result;
    if (widget.existing != null) {
      store.updateCategory(widget.existing!,
          name: name, iconKey: _icon, color: _color);
      result = widget.existing!;
    } else {
      result = store.addCategory(
          name: name, iconKey: _icon, color: _color, type: _type);
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final color = Color(_color);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onLeave();
      },
      child: AlertDialog(
        title: Text(isEdit ? 'แก้ไขหมวด' : 'เพิ่มหมวดใหม่'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ตัวอย่างหมวดแบบสด
                Center(
                  child: Column(children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: color.withAlpha(40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(iconOf(_icon), color: color, size: 32),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _name.text.trim().isEmpty
                          ? 'ชื่อหมวด'
                          : _name.text.trim(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                if (!isEdit) ...[
                  SegmentedButton<TxType>(
                    segments: const [
                      ButtonSegment(
                          value: TxType.expense, label: Text('รายจ่าย')),
                      ButtonSegment(
                          value: TxType.income, label: Text('รายรับ')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _name,
                  autofocus: !isEdit,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                  onChanged: (_) => setState(() => _error = null),
                  decoration: InputDecoration(
                    hintText: 'ชื่อหมวด เช่น ค่าขนม, ค่าหอ, งานเสริม',
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('ไอคอน'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final k in kCategoryIcons.keys)
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => setState(() => _icon = k),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _icon == k ? color : color.withAlpha(28),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(kCategoryIcons[k],
                              size: 22,
                              color: _icon == k ? Colors.white : color),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('สี'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in kCategoryColors)
                      InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => setState(() => _color = c),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Color(c),
                          child: _color == c
                              ? const Icon(Icons.check,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.maybePop(context),
              child: const Text('ยกเลิก')),
          FilledButton(onPressed: _save, child: const Text('บันทึก')),
        ],
      ),
    );
  }
}
