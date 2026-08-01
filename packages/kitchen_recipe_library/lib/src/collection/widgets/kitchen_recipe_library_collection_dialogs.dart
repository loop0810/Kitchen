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
          child: recipes.isEmpty
              ? const Text('还没有可添加的菜谱')
              : ListView(
                  shrinkWrap: true,
                  children: recipes
                      .map(
                        (item) => CheckboxListTile(
                          value: selected.contains(item.recipe.id),
                          title: Text(item.recipe.title),
                          subtitle: Text(item.recipe.category),
                          onChanged: (value) => setState(() {
                            value == true
                                ? selected.add(item.recipe.id)
                                : selected.remove(item.recipe.id);
                          }),
                        ),
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('保存'),
          ),
        ],
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
                child: available.isEmpty
                    ? const Text('还没有菜谱集，可以先新建一个')
                    : ListView(
                        shrinkWrap: true,
                        children: available
                            .map(
                              (item) => CheckboxListTile(
                                value: selected.contains(item.id),
                                title: Text(item.name),
                                subtitle: Text('${item.memberCount} 道菜谱'),
                                onChanged: (value) => setState(() {
                                  value == true
                                      ? selected.add(item.id)
                                      : selected.remove(item.id);
                                }),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text('保存'),
          ),
        ],
      ),
    ),
  );
}
