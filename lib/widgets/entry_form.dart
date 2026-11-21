import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../utils.dart';
import 'category_form.dart';
import 'common.dart';

/// เปิดฟอร์มเพิ่ม/แก้ไขรายการ
Future<void> showEntryForm(BuildContext context,
    {Entry? existing, DateTime? initialDate, TxType? initialType}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // ปิดการปัดลงเพื่อปิด เพื่อให้ถามก่อนทิ้งข้อมูลที่ยังไม่บันทึกได้ทุกครั้ง
    enableDrag: false,
    builder: (_) => EntryForm(
      existing: existing,
      initialDate: initialDate ?? DateTime.now(),
      initialType: initialType ?? TxType.expense,
    ),
  );
}

class EntryForm extends StatefulWidget {
  final Entry? existing;
  final DateTime initialDate;
  final TxType initialType;

  const EntryForm({
    super.key,
    this.existing,
    required this.initialDate,
    required this.initialType,
  });

  @override
  State<EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<EntryForm> {
  late TxType _type;
  String? _catId;
  late DateTime _date;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  final _noteFocus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? widget.initialType;
    _catId = e?.categoryId;
    _date = dateOnly(e?.date ?? widget.initialDate);
    _amount =
        TextEditingController(text: e != null ? plainAmount(e.amount) : '');
    _note = TextEditingController(text: e?.note ?? '');
    _amount.addListener(() => setState(() => _error = null));
    _noteFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  double? get _value => evalExpression(_amount.text);

  /// มีข้อมูลที่กรอกไว้แต่ยังไม่ได้บันทึกหรือไม่
  bool get _dirty {
    final e = widget.existing;
    if (e == null) {
      return _amount.text.trim().isNotEmpty || _note.text.trim().isNotEmpty;
    }
    return _type != e.type ||
        _catId != e.categoryId ||
        !sameDay(_date, e.date) ||
        _amount.text != plainAmount(e.amount) ||
        _note.text.trim() != e.note;
  }

  /// เรียกเมื่อผู้ใช้จะออกจากฟอร์ม (แตะนอกฟอร์ม, ปุ่มย้อนกลับ, ปุ่มปิด)
  Future<void> _onLeave() async {
    if (!_dirty) {
      Navigator.pop(context);
      return;
    }
    _noteFocus.unfocus();
    final leave = await confirmLeaveUnsaved(context);
    if (leave && mounted) Navigator.pop(context);
  }

  void _insert(String s) {
    final t = _amount.text;
    final sel = _amount.selection;
    final start = sel.start < 0 ? t.length : sel.start;
    final end = sel.end < 0 ? t.length : sel.end;
    _amount.value = TextEditingValue(
      text: t.replaceRange(start, end, s),
      selection: TextSelection.collapsed(offset: start + s.length),
    );
  }

  void _backspace() {
    final t = _amount.text;
    final sel = _amount.selection;
    var start = sel.start < 0 ? t.length : sel.start;
    final end = sel.end < 0 ? t.length : sel.end;
    if (start == end) {
      if (start == 0) return;
      start -= 1;
    }
    _amount.value = TextEditingValue(
      text: t.replaceRange(start, end, ''),
      selection: TextSelection.collapsed(offset: start),
    );
  }

  /// กด "=" เพื่อแทนสูตรด้วยผลลัพธ์
  void _equals() {
    final v = _value;
    if (v != null) {
      _amount.value = TextEditingValue(
        text: plainAmount(v),
        selection: TextSelection.collapsed(offset: plainAmount(v).length),
      );
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = dateOnly(d));
  }

  Future<void> _addCategory() async {
    final c = await showCategoryForm(context, type: _type);
    if (c != null) {
      setState(() {
        _type = c.type;
        _catId = c.id;
      });
    }
  }

  void _save() {
    final store = StoreScope.read(context);
    final v = _value;
    if (v == null || v <= 0) {
      setState(() => _error = 'กรุณาใส่จำนวนเงินที่ถูกต้อง (มากกว่า 0)');
      return;
    }
    final cat = _catId == null ? null : store.categoryById(_catId!);
    if (cat == null || cat.type != _type) {
      setState(() => _error = 'กรุณาเลือกหมวด');
      return;
    }
    final e = widget.existing;
    store.saveEntry(Entry(
      id: e?.id ?? newId(),
      type: _type,
      categoryId: cat.id,
      amount: double.parse(v.toStringAsFixed(2)),
      note: _note.text.trim(),
      date: _date,
      createdAt: e?.createdAt ?? DateTime.now(),
    ));
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('ลบรายการนี้?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok == true && mounted) {
      StoreScope.read(context).deleteEntry(widget.existing!);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final store = StoreScope.of(context);
    final cats = store.categoriesOf(_type);
    if (_catId == null || !cats.any((c) => c.id == _catId)) {
      _catId = cats.isNotEmpty ? cats.first.id : null;
    }
    final typeColor =
        _type == TxType.income ? context.incomeColor : context.expenseColor;
    final v = _value;
    final isFormula = _amount.text.isNotEmpty && hasOperator(_amount.text);
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final showKeypad = !_noteFocus.hasFocus;

    final resultLine = _error ??
        (isFormula
            ? (v != null ? '= ${fmtMoney(v)} บาท' : 'สูตรยังไม่สมบูรณ์')
            : 'พิมพ์สูตรได้ เช่น 45+30×2');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onLeave();
      },
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                            widget.existing == null
                                ? 'เพิ่มรายการ'
                                : 'แก้ไขรายการ',
                            style: theme.textTheme.titleLarge),
                        const Spacer(),
                        if (widget.existing != null)
                          IconButton(
                            tooltip: 'ลบ',
                            onPressed: _delete,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        IconButton(
                          tooltip: 'ปิด',
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<TxType>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                            value: TxType.expense, label: Text('รายจ่าย')),
                        ButtonSegment(
                            value: TxType.income, label: Text('รายรับ')),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() {
                        _type = s.first;
                        _catId = null;
                      }),
                    ),
                    const SizedBox(height: 16),
                    // จำนวนเงินตัวใหญ่
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('฿',
                            style: amountStyle(
                                context, 26, typeColor.withAlpha(170))),
                        const SizedBox(width: 6),
                        Flexible(
                          child: IntrinsicWidth(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 32),
                              child: TextField(
                                controller: _amount,
                                autofocus: true,
                                keyboardType: TextInputType.none,
                                showCursor: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9.,+\-*/×÷() ]')),
                                ],
                                onSubmitted: (_) => _save(),
                                style: amountStyle(context, 40, typeColor),
                                decoration: InputDecoration(
                                  filled: false,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  hintText: '0',
                                  hintStyle: amountStyle(
                                      context, 40, colors.outlineVariant),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      resultLine,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: _error != null
                            ? colors.error
                            : (isFormula ? typeColor : colors.onSurfaceVariant),
                        fontWeight:
                            isFormula ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _CategoryStrip(
                      categories: cats,
                      selectedId: _catId,
                      onSelect: (id) => setState(() {
                        _catId = id;
                        _error = null;
                      }),
                      onAdd: _addCategory,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Material(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: _pickDate,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                              child: Row(children: [
                                Icon(Icons.event_rounded,
                                    size: 18, color: colors.primary),
                                const SizedBox(width: 6),
                                Text(thaiShortDate(_date)),
                              ]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _note,
                            focusNode: _noteFocus,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _noteFocus.unfocus(),
                            decoration: const InputDecoration(
                              hintText: 'หมายเหตุ (ไม่บังคับ)',
                              isDense: true,
                              prefixIcon: Icon(Icons.notes_rounded, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (showKeypad && !keyboardOpen) ...[
                      const SizedBox(height: 12),
                      _Keypad(
                        onKey: _insert,
                        onBackspace: _backspace,
                        onClear: () => _amount.clear(),
                        onEquals: _equals,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: typeColor,
                  foregroundColor: colors.surface,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _save,
                child: Text(
                  v != null && v > 0
                      ? 'บันทึก${_type.label}  ${baht(v)}'
                      : 'บันทึก',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// แถบเลือกหมวดแบบเลื่อนแนวนอน
class _CategoryStrip extends StatelessWidget {
  final List<Category> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAdd;

  const _CategoryStrip({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget tile(
        {required Widget icon,
        required String label,
        required bool selected,
        required VoidCallback onTap}) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? colors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colors.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                icon,
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 84,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final c in categories)
            tile(
              icon: CategoryAvatar(category: c, size: 40),
              label: c.name,
              selected: c.id == selectedId,
              onTap: () => onSelect(c.id),
            ),
          tile(
            icon: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant, width: 1.5),
              ),
              child: Icon(Icons.add_rounded, color: colors.primary),
            ),
            label: 'เพิ่มหมวด',
            selected: false,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}

/// แป้นตัวเลข + เครื่องคิดเลข
class _Keypad extends StatelessWidget {
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onEquals;

  const _Keypad({
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    required this.onEquals,
  });

  static const _rows = [
    ['C', '(', ')', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['.', '0', '⌫', '='],
  ];
  static const _tokens = {'−': '-', '×': '×', '÷': '÷'};
  static const _ops = {'÷', '×', '−', '+', '=', '(', ')', 'C'};

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (final row in _rows)
          Row(
            children: [
              for (final key in row)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: key == '='
                            ? colors.primary
                            : _ops.contains(key)
                                ? colors.primaryContainer
                                : colors.surfaceContainer,
                        foregroundColor: key == '='
                            ? colors.onPrimary
                            : _ops.contains(key)
                                ? colors.onPrimaryContainer
                                : colors.onSurface,
                        minimumSize: const Size(0, 48),
                        padding: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: switch (key) {
                        '⌫' => onBackspace,
                        'C' => onClear,
                        '=' => onEquals,
                        _ => () => onKey(_tokens[key] ?? key),
                      },
                      child: key == '⌫'
                          ? const Icon(Icons.backspace_outlined, size: 20)
                          : Text(key,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
