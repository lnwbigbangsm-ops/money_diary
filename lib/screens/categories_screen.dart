import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../widgets/category_form.dart';
import '../widgets/common.dart';

/// หน้าจัดการหมวดหมู่: เพิ่ม แก้ไข ลบ และลากเรียงลำดับ
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: const Text('หมวดหมู่'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    labelColor: colors.onSurface,
                    unselectedLabelColor: colors.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: const [Tab(text: 'รายจ่าย'), Tab(text: 'รายรับ')],
                  ),
                ),
              ),
            ),
          ),
          body: const TabBarView(children: [
            _CategoryList(type: TxType.expense),
            _CategoryList(type: TxType.income),
          ]),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              final i = DefaultTabController.of(context).index;
              showCategoryForm(context,
                  type: i == 0 ? TxType.expense : TxType.income);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('เพิ่มหมวด',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      }),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final TxType type;
  const _CategoryList({required this.type});

  Future<void> _delete(BuildContext context, Category c) async {
    final store = StoreScope.read(context);
    final others = store.categoriesOf(type).where((x) => x.id != c.id).toList();
    if (others.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('ต้องมี${type.label}อย่างน้อย 1 หมวด'),
      ));
      return;
    }
    final used = store.usageCount(c.id);
    final target =
        others.firstWhere((x) => x.name == 'อื่นๆ', orElse: () => others.first);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('ลบหมวด "${c.name}"?'),
        content: Text(used == 0
            ? 'หมวดนี้ยังไม่มีรายการ'
            : 'มี $used รายการในหมวดนี้ จะถูกย้ายไปหมวด "${target.name}"'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(d, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok == true) store.deleteCategory(c, moveTo: used > 0 ? target : null);
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final cats = store.categoriesOf(type);
    final colors = Theme.of(context).colorScheme;
    if (cats.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: EmptyHint(icon: Icons.category_outlined, text: 'ยังไม่มีหมวด'),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
      buildDefaultDragHandles: false,
      itemCount: cats.length,
      onReorderItem: (o, n) => store.moveCategory(type, o, n),
      proxyDecorator: (child, _, __) => Material(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        elevation: 4,
        child: child,
      ),
      itemBuilder: (context, i) {
        final c = cats[i];
        final used = store.usageCount(c.id);
        final first = i == 0, last = i == cats.length - 1;
        return Container(
          key: ValueKey(c.id),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(first ? 20 : 0),
              bottom: Radius.circular(last ? 20 : 0),
            ),
            border: last
                ? null
                : Border(
                    bottom: BorderSide(color: colors.outlineVariant, width: 1)),
          ),
          child: InkWell(
            onTap: () => showCategoryForm(context, existing: c),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
              child: Row(
                children: [
                  CategoryAvatar(category: c),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 15)),
                        Text(
                            used == 0
                                ? 'ยังไม่มีรายการ'
                                : 'ใช้แล้ว $used รายการ',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    onSelected: (v) {
                      if (v == 'edit') showCategoryForm(context, existing: c);
                      if (v == 'delete') _delete(context, c);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                      PopupMenuItem(value: 'delete', child: Text('ลบ')),
                    ],
                  ),
                  ReorderableDragStartListener(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.drag_indicator_rounded,
                          color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
