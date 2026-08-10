import 'package:flutter/material.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

Future<String?> showCollectionNameDialog(
  BuildContext context, {
  required String title,
  String initialValue = '',
}) => showDialog<String>(
  context: context,
  builder: (context) =>
      _CollectionNameDialog(title: title, initialValue: initialValue),
);

class _CollectionNameDialog extends StatefulWidget {
  const _CollectionNameDialog({
    required this.title,
    required this.initialValue,
  });

  final String title;
  final String initialValue;

  @override
  State<_CollectionNameDialog> createState() => _CollectionNameDialogState();
}

class _CollectionNameDialogState extends State<_CollectionNameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _controller,
      autofocus: true,
      maxLength: 40,
      decoration: InputDecoration(labelText: '菜谱集名称', errorText: _errorText),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(onPressed: _submit, child: const Text('保存')),
    ],
  );

  void _submit() {
    try {
      Navigator.pop(context, normalizeRecipeCollectionName(_controller.text));
    } on ArgumentError catch (error) {
      setState(() => _errorText = error.message?.toString());
    }
  }
}

Future<Set<String>?> showRecipeSelectionDialog(
  BuildContext context, {
  required String title,
  required List<RecipeJournalSummaryEntity> recipes,
  required Set<String> selectedIds,
}) {
  final selected = {...selectedIds};
  return showDialog<Set<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: _SelectableList(
            emptyText: '还没有可添加的菜谱',
            entries: recipes
                .map(
                  (item) => _SelectableEntry(
                    id: item.recipe.id,
                    title: item.recipe.title,
                    subtitle: item.recipe.category,
                  ),
                )
                .toList(growable: false),
            selected: selected,
            onToggle: (id, isSelected) => setState(
              () => isSelected ? selected.add(id) : selected.remove(id),
            ),
          ),
        ),
        actions: _selectionDialogActions(context, selected),
      ),
    ),
  );
}

Future<Set<String>?> showCollectionSelectionDialog(
  BuildContext context, {
  required List<RecipeCollectionEntity> collections,
  required Set<String> selectedIds,
  required Future<RecipeCollectionEntity?> Function() onCreate,
}) {
  final selected = {...selectedIds};
  final available = [...collections];
  return showDialog<Set<String>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('管理菜谱集'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    final created = await onCreate();
                    if (created != null) {
                      setState(() {
                        available.add(created);
                        selected.add(created.id);
                      });
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('新建菜谱集'),
                ),
              ),
              Flexible(
                child: _SelectableList(
                  emptyText: '还没有菜谱集，可以先新建一个',
                  entries: available
                      .map(
                        (item) => _SelectableEntry(
                          id: item.id,
                          title: item.name,
                          subtitle: '${item.memberCount} 道菜谱',
                        ),
                      )
                      .toList(growable: false),
                  selected: selected,
                  onToggle: (id, isSelected) => setState(
                    () => isSelected ? selected.add(id) : selected.remove(id),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: _selectionDialogActions(context, selected),
      ),
    ),
  );
}

/// 多选弹窗共用的行模型，让菜谱与菜谱集两种实体共用同一套勾选列表。
class _SelectableEntry {
  const _SelectableEntry({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  /// 选中集合中使用的唯一标识。
  final String id;

  /// 列表主标题。
  final String title;

  /// 列表副标题，例如菜谱分类或菜谱集成员数。
  final String subtitle;
}

class _SelectableList extends StatelessWidget {
  const _SelectableList({
    required this.entries,
    required this.selected,
    required this.onToggle,
    required this.emptyText,
  });

  final List<_SelectableEntry> entries;
  final Set<String> selected;
  final void Function(String id, bool isSelected) onToggle;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return Text(emptyText);
    return ListView(
      shrinkWrap: true,
      children: entries
          .map(
            (entry) => CheckboxListTile(
              value: selected.contains(entry.id),
              title: Text(entry.title),
              subtitle: Text(entry.subtitle),
              onChanged: (value) => onToggle(entry.id, value == true),
            ),
          )
          .toList(growable: false),
    );
  }
}

/// 多选弹窗统一的底部按钮：取消返回 `null`，保存返回当前选中集合。
List<Widget> _selectionDialogActions(
  BuildContext context,
  Set<String> selected,
) => [
  TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
  FilledButton(
    onPressed: () => Navigator.pop(context, selected),
    child: const Text('保存'),
  ),
];
