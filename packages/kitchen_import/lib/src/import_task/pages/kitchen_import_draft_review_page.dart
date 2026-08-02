import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_import_domain/kitchen_import_domain.dart';

import '../../shared/providers/kitchen_import_dependencies.dart';

class ImportDraftReviewPage extends ConsumerWidget {
  const ImportDraftReviewPage({
    super.key,
    required this.taskId,
    required this.onContinue,
    required this.categories,
    required this.tags,
    required this.difficulties,
  });

  final String taskId;
  final Future<void> Function(RecipeDraftEntity draft) onContinue;
  final List<String> categories;
  final List<String> tags;
  final List<String> difficulties;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(importTaskProvider(taskId));
    return task.when(
      data: (value) {
        if (value == null) return const _MessagePage(message: '导入任务不存在或已删除');
        final draft = value.draft;
        if (draft == null) {
          return const _MessagePage(message: '草稿尚未准备好，请返回后重试');
        }
        return _ReviewForm(
          taskId: taskId,
          draft: draft,
          onContinue: onContinue,
          categories: categories,
          tags: tags,
          difficulties: difficulties,
        );
      },
      error: (_, _) => const _MessagePage(message: '草稿加载失败，请稍后重试'),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _ReviewForm extends ConsumerStatefulWidget {
  const _ReviewForm({
    required this.taskId,
    required this.draft,
    required this.onContinue,
    required this.categories,
    required this.tags,
    required this.difficulties,
  });

  final String taskId;
  final RecipeDraftEntity draft;
  final Future<void> Function(RecipeDraftEntity draft) onContinue;
  final List<String> categories;
  final List<String> tags;
  final List<String> difficulties;

  @override
  ConsumerState<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends ConsumerState<_ReviewForm> {
  late final TextEditingController _title;
  late final TextEditingController _summary;
  late final TextEditingController _category;
  late final TextEditingController _servings;
  late final TextEditingController _prepMinutes;
  late final TextEditingController _cookMinutes;
  late final TextEditingController _difficulty;
  late List<String> _tags;
  late List<String> _ingredients;
  late List<String> _preparations;
  late List<String> _steps;
  final _edited = <String>{};
  final _confirmed = <String>{};
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _title = TextEditingController(text: draft.title.value);
    _summary = TextEditingController(text: draft.summary.value);
    _category = TextEditingController(
      text: _normalizedOption(draft.category.value, widget.categories),
    );
    _servings = TextEditingController(
      text: _boundedNumberText(draft.servings.value, minimum: 1, maximum: 10),
    );
    _prepMinutes = TextEditingController(
      text: _boundedNumberText(
        draft.prepMinutes.value,
        minimum: 1,
        maximum: 120,
      ),
    );
    _cookMinutes = TextEditingController(
      text: _boundedNumberText(
        draft.cookMinutes.value,
        minimum: 1,
        maximum: 120,
      ),
    );
    _difficulty = TextEditingController(
      text: _normalizedOption(draft.difficulty.value, widget.difficulties),
    );
    _tags = [...draft.tags.value];
    _ingredients = [...draft.ingredients.value];
    _preparations = [...draft.preparations.value];
    _steps = [...draft.steps.value];
    for (final entry in <String, DraftFieldOrigin>{
      'title': draft.title.origin,
      'summary': draft.summary.origin,
      'category': draft.category.origin,
      'servings': draft.servings.origin,
      'prepMinutes': draft.prepMinutes.origin,
      'cookMinutes': draft.cookMinutes.origin,
      'difficulty': draft.difficulty.origin,
      'tags': draft.tags.origin,
      'ingredients': draft.ingredients.origin,
      'preparations': draft.preparations.origin,
      'steps': draft.steps.origin,
    }.entries) {
      if (entry.value == DraftFieldOrigin.userEdited) _edited.add(entry.key);
      if (entry.value == DraftFieldOrigin.userConfirmed) {
        _confirmed.add(entry.key);
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _summary,
      _category,
      _servings,
      _prepMinutes,
      _cookMinutes,
      _difficulty,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _ReviewForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Drift 会在流水线继续整理或自动暂存后发出新的任务快照。只同步用户尚未
    // 编辑或确认的字段，既修复首次打开时持有半成品草稿的问题，也守住用户值。
    final draft = widget.draft;
    _syncText('title', _title, draft.title.value);
    _syncText('summary', _summary, draft.summary.value);
    _syncText(
      'category',
      _category,
      _normalizedOption(draft.category.value, widget.categories),
    );
    _syncText(
      'servings',
      _servings,
      _boundedNumberText(draft.servings.value, minimum: 1, maximum: 10),
    );
    _syncText(
      'prepMinutes',
      _prepMinutes,
      _boundedNumberText(draft.prepMinutes.value, minimum: 1, maximum: 120),
    );
    _syncText(
      'cookMinutes',
      _cookMinutes,
      _boundedNumberText(draft.cookMinutes.value, minimum: 1, maximum: 120),
    );
    _syncText(
      'difficulty',
      _difficulty,
      _normalizedOption(draft.difficulty.value, widget.difficulties),
    );
    if (!_isProtected('tags')) _tags = [...draft.tags.value];
    if (!_isProtected('ingredients')) {
      _ingredients = [...draft.ingredients.value];
    }
    if (!_isProtected('preparations')) {
      _preparations = [...draft.preparations.value];
    }
    if (!_isProtected('steps')) _steps = [...draft.steps.value];
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Scaffold(
      appBar: AppBar(title: const Text('确认导入草稿')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          _IssuesCard(draft: draft),
          _field(
            keyName: 'title',
            label: '基础信息 · 菜名',
            field: draft.title,
            child: TextField(
              controller: _title,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (_) => _changed('title'),
            ),
          ),
          _field(
            keyName: 'summary',
            label: '基础信息 · 简介',
            field: draft.summary,
            child: TextField(
              controller: _summary,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (_) => _changed('summary'),
            ),
          ),
          _field(
            keyName: 'category',
            label: '分类',
            field: draft.category,
            child: DropdownButtonFormField<String>(
              key: ValueKey('category-${_category.text}'),
              isExpanded: true,
              initialValue: _selectedValue(_category.text, widget.categories),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _optionsWithCurrent(widget.categories, _category.text)
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                _category.text = value;
                _changed('category');
              },
            ),
          ),
          _field(
            keyName: 'tags',
            label: '标签',
            field: draft.tags,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey('tags-${_tags.join('|')}'),
                  isExpanded: true,
                  initialValue: null,
                  hint: const Text('选择并添加标签'),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: widget.tags
                      .where((tag) => !_tags.contains(tag))
                      .map(
                        (tag) => DropdownMenuItem(value: tag, child: Text(tag)),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _tags.add(value));
                    _changed('tags');
                  },
                ),
                if (_tags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Wrap(
                    spacing: AppSpacing.s8,
                    runSpacing: AppSpacing.s8,
                    children: [
                      for (final tag in _tags)
                        InputChip(
                          label: Text(tag),
                          tooltip: '移除标签 $tag',
                          onDeleted: () {
                            setState(() => _tags.remove(tag));
                            _changed('tags');
                          },
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          _numberRow(draft),
          _field(
            keyName: 'difficulty',
            label: '难度',
            field: draft.difficulty,
            child: DropdownButtonFormField<String>(
              key: ValueKey('difficulty-${_difficulty.text}'),
              isExpanded: true,
              initialValue: _selectedValue(
                _difficulty.text,
                widget.difficulties,
              ),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _optionsWithCurrent(widget.difficulties, _difficulty.text)
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                _difficulty.text = value;
                _changed('difficulty');
              },
            ),
          ),
          _listField(
            keyName: 'ingredients',
            label: '食材',
            field: draft.ingredients,
            values: _ingredients,
          ),
          _listField(
            keyName: 'preparations',
            label: '准备工作',
            field: draft.preparations,
            values: _preparations,
          ),
          _listField(
            keyName: 'steps',
            label: '步骤',
            field: draft.steps,
            values: _steps,
          ),
          _SourceCard(source: draft.sourceSnapshot),
          const SizedBox(height: AppSpacing.s16),
          OutlinedButton.icon(
            onPressed: _saving ? null : _confirmAll,
            icon: const Icon(Icons.verified_outlined),
            label: const Text('确认当前全部内容'),
          ),
          FilledButton.icon(
            onPressed: _saving ? null : _continue,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('继续保存菜谱'),
          ),
          const SizedBox(height: AppSpacing.s24),
        ],
      ),
    );
  }

  Widget _numberRow(RecipeDraftEntity draft) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        SizedBox(
          width: 180,
          child: _field(
            keyName: 'servings',
            label: '份量（人）',
            field: draft.servings,
            child: _numberPicker(
              controller: _servings,
              keyName: 'servings',
              values: List<int>.generate(10, (index) => index + 1),
              valueLabel: (value) => '$value 人',
            ),
          ),
        ),
        SizedBox(
          width: 180,
          child: _field(
            keyName: 'prepMinutes',
            label: '准备时间',
            field: draft.prepMinutes,
            child: _durationPicker(
              controller: _prepMinutes,
              keyName: 'prepMinutes',
            ),
          ),
        ),
        SizedBox(
          width: 180,
          child: _field(
            keyName: 'cookMinutes',
            label: '制作时间',
            field: draft.cookMinutes,
            child: _durationPicker(
              controller: _cookMinutes,
              keyName: 'cookMinutes',
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberPicker({
    required TextEditingController controller,
    required String keyName,
    required List<int> values,
    required String Function(int value) valueLabel,
  }) {
    final current = int.tryParse(controller.text);
    return DropdownButtonFormField<int>(
      key: ValueKey('$keyName-${controller.text}'),
      isExpanded: true,
      initialValue: current != null && values.contains(current)
          ? current
          : null,
      hint: const Text('待选择'),
      decoration: const InputDecoration(border: OutlineInputBorder()),
      menuMaxHeight: 360,
      items: values
          .map(
            (value) =>
                DropdownMenuItem(value: value, child: Text(valueLabel(value))),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) return;
        controller.text = value.toString();
        _changed(keyName);
      },
    );
  }

  Widget _durationPicker({
    required TextEditingController controller,
    required String keyName,
  }) {
    final current = int.tryParse(controller.text);
    return Semantics(
      button: true,
      label: keyName == 'prepMinutes' ? '选择准备时间' : '选择制作时间',
      child: InkWell(
        key: ValueKey('$keyName-${controller.text}'),
        onTap: () async {
          final selection = await showModalBottomSheet<_DurationSelection>(
            context: context,
            showDragHandle: true,
            builder: (_) => _DurationPickerSheet(initialMinutes: current),
          );
          if (selection == null) return;
          setState(() {
            controller.text = selection.minutes?.toString() ?? '';
          });
          _changed(keyName);
        },
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.unfold_more_rounded),
          ),
          child: Text(current == null ? '待选择' : _durationLabel(current)),
        ),
      ),
    );
  }

  Widget _field<T>({
    required String keyName,
    required String label,
    required DraftFieldValue<T> field,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MetaChip(field: field),
                IconButton(
                  onPressed: field.evidence.isEmpty
                      ? null
                      : () => _showEvidence(label, field.evidence),
                  tooltip: field.evidence.isEmpty ? '暂无证据' : '查看来源证据',
                  icon: const Icon(Icons.source_outlined),
                ),
                IconButton(
                  onPressed: () => _toggleConfirmed(keyName),
                  tooltip: _confirmed.contains(keyName) ? '取消确认' : '确认该字段',
                  icon: Icon(
                    _confirmed.contains(keyName)
                        ? Icons.verified_rounded
                        : Icons.verified_outlined,
                  ),
                ),
              ],
            ),
            child,
            if (field.conflictCandidate != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                '新识别候选：${field.conflictCandidate}',
                style: TextStyle(color: Theme.of(context).colorScheme.tertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _listField({
    required String keyName,
    required String label,
    required DraftFieldValue<List<String>> field,
    required List<String> values,
  }) {
    return _field(
      keyName: keyName,
      label: label,
      field: field,
      child: Column(
        children: [
          if (values.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('待补充，仍可保存为待完善菜谱。'),
            ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: values.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(
                () => values.insert(newIndex, values.removeAt(oldIndex)),
              );
              _changed(keyName);
            },
            itemBuilder: (context, index) => Row(
              key: ValueKey('$keyName-$index-${values[index]}'),
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_indicator_rounded),
                ),
                Expanded(
                  child: TextFormField(
                    initialValue: values[index],
                    minLines: 1,
                    maxLines: 4,
                    onChanged: (value) {
                      values[index] = value;
                      _changed(keyName);
                    },
                  ),
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: () {
                    setState(() => values.removeAt(index));
                    _changed(keyName);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() => values.add(''));
                _changed(keyName);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加一项'),
            ),
          ),
        ],
      ),
    );
  }

  void _changed(String keyName) {
    _edited.add(keyName);
    _confirmed.remove(keyName);
    _persist();
  }

  void _toggleConfirmed(String keyName) {
    setState(() {
      if (!_confirmed.add(keyName)) _confirmed.remove(keyName);
    });
    _persist();
  }

  void _confirmAll() {
    setState(() => _confirmed.addAll(_allFieldKeys));
    _persist();
  }

  Future<void> _continue() async {
    setState(() => _saving = true);
    try {
      final draft = _currentDraft();
      await ref
          .read(importDependenciesProvider)
          .repository
          .saveReviewDraft(widget.taskId, draft);
      await widget.onContinue(draft);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _persist() {
    unawaited(
      ref
          .read(importDependenciesProvider)
          .repository
          .saveReviewDraft(widget.taskId, _currentDraft()),
    );
  }

  RecipeDraftEntity _currentDraft() {
    final draft = widget.draft;
    return RecipeDraftEntity(
      schemaVersion: 2,
      quality: draft.quality,
      warnings: draft.warnings,
      title: _value('title', _title.text.trim(), draft.title),
      summary: _value('summary', _summary.text.trim(), draft.summary),
      category: _value('category', _category.text.trim(), draft.category),
      servings: _value(
        'servings',
        int.tryParse(_servings.text.trim()),
        draft.servings,
      ),
      prepMinutes: _value(
        'prepMinutes',
        int.tryParse(_prepMinutes.text.trim()),
        draft.prepMinutes,
      ),
      cookMinutes: _value(
        'cookMinutes',
        int.tryParse(_cookMinutes.text.trim()),
        draft.cookMinutes,
      ),
      difficulty: _value(
        'difficulty',
        _difficulty.text.trim(),
        draft.difficulty,
      ),
      tags: _value('tags', List<String>.unmodifiable(_tags), draft.tags),
      ingredients: _value(
        'ingredients',
        _clean(_ingredients),
        draft.ingredients,
      ),
      preparations: _value(
        'preparations',
        _clean(_preparations),
        draft.preparations,
      ),
      steps: _value('steps', _clean(_steps), draft.steps),
      sourceSnapshot: draft.sourceSnapshot,
    );
  }

  bool _isProtected(String keyName) =>
      _edited.contains(keyName) || _confirmed.contains(keyName);

  void _syncText(
    String keyName,
    TextEditingController controller,
    String value,
  ) {
    if (!_isProtected(keyName) && controller.text != value) {
      controller.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
    }
  }

  DraftFieldValue<T> _value<T>(
    String keyName,
    T value,
    DraftFieldValue<T> original,
  ) {
    final origin = _confirmed.contains(keyName)
        ? DraftFieldOrigin.userConfirmed
        : _edited.contains(keyName)
        ? DraftFieldOrigin.userEdited
        : original.origin;
    return DraftFieldValue<T>(
      value: value,
      origin: origin,
      needsConfirmation: origin != DraftFieldOrigin.userConfirmed,
      confidence: original.confidence,
      evidence: original.evidence,
      conflictCandidate: original.conflictCandidate,
    );
  }

  Future<void> _showEvidence(String label, List<DraftFieldEvidence> evidence) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$label · 来源证据'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final item in evidence)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${item.pageIndex + 1}')),
                  title: Text(item.excerpt),
                  subtitle: Text('第 ${item.pageIndex + 1} 张 · ${item.lineId}'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.field});

  final DraftFieldValue<Object?> field;

  @override
  Widget build(BuildContext context) {
    final text = switch (field.origin) {
      DraftFieldOrigin.source => '原文',
      DraftFieldOrigin.inferred => '推断',
      DraftFieldOrigin.userEdited => '已编辑',
      DraftFieldOrigin.userConfirmed => '已确认',
    };
    final confidence = switch (field.confidence) {
      DraftConfidenceLevel.high => '高',
      DraftConfidenceLevel.medium => '中',
      DraftConfidenceLevel.low => '低',
    };
    return Tooltip(
      message: '来源：$text，可信等级：$confidence',
      child: Chip(label: Text('$text · $confidence')),
    );
  }
}

class _IssuesCard extends StatelessWidget {
  const _IssuesCard({required this.draft});

  final RecipeDraftEntity draft;

  @override
  Widget build(BuildContext context) {
    final issues = [
      ...draft.warnings,
      if (draft.ingredients.value.isEmpty) '尚未识别到食材',
      if (draft.steps.value.isEmpty) '尚未识别到步骤',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('问题摘要', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s8),
            if (issues.isEmpty) const Text('未发现明显问题，仍请核对自动字段。'),
            for (final issue in issues) Text('• $issue'),
          ],
        ),
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({required this.source});

  final SourceSnapshot source;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        title: const Text('来源'),
        subtitle: Text(
          source.sourceTitle ?? source.publicUrl?.host ?? '本地图片/文字',
        ),
        childrenPadding: const EdgeInsets.all(AppSpacing.s12),
        children: [
          SelectableText(
            source.originalText.isEmpty ? '无额外原文' : source.originalText,
          ),
        ],
      ),
    );
  }
}

class _MessagePage extends StatelessWidget {
  const _MessagePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('确认导入草稿')),
      body: Center(child: Text(message)),
    );
  }
}

const _allFieldKeys = <String>{
  'title',
  'summary',
  'category',
  'servings',
  'prepMinutes',
  'cookMinutes',
  'difficulty',
  'tags',
  'ingredients',
  'preparations',
  'steps',
};

List<String> _clean(List<String> values) => values
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList(growable: false);

String _normalizedOption(String value, List<String> options) {
  if (value.isNotEmpty) return value;
  return options.isEmpty ? '' : options.first;
}

String? _selectedValue(String value, List<String> options) =>
    value.isEmpty ? null : value;

List<String> _optionsWithCurrent(List<String> options, String current) => [
  ...options,
  if (current.isNotEmpty && !options.contains(current)) current,
];

String _durationLabel(int minutes) {
  if (minutes < 60) return '$minutes 分钟';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours 小时' : '$hours 小时 $remainder 分钟';
}

String _boundedNumberText(
  int? value, {
  required int minimum,
  required int maximum,
}) {
  if (value == null || value < minimum || value > maximum) return '';
  return value.toString();
}

class _DurationSelection {
  const _DurationSelection(this.minutes);

  final int? minutes;
}

class _DurationPickerSheet extends StatefulWidget {
  const _DurationPickerSheet({this.initialMinutes});

  final int? initialMinutes;

  @override
  State<_DurationPickerSheet> createState() => _DurationPickerSheetState();
}

class _DurationPickerSheetState extends State<_DurationPickerSheet> {
  late int _hours;
  late int _minutes;
  late final FixedExtentScrollController _hourController;
  late final FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    final total = (widget.initialMinutes ?? 0).clamp(0, 120);
    _hours = total ~/ 60;
    _minutes = total % 60;
    _hourController = FixedExtentScrollController(initialItem: _hours);
    // 分钟使用无界 builder，并从中段开始，向任意方向滚动都无需滑过长列表。
    _minuteController = FixedExtentScrollController(
      initialItem: 6000 + _minutes,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _selectHour(int value) {
    setState(() {
      _hours = value;
      if (_hours == 2) _minutes = 0;
    });
    if (_hours == 2) {
      _minuteController.animateToItem(
        6000,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  void _selectMinute(int index) {
    final value = index % 60;
    if (_hours == 2 && value != 0) {
      _minuteController.animateToItem(
        index - value,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() => _minutes = value);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: 320,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, const _DurationSelection(null)),
                    child: const Text('清除'),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _DurationSelection(
                        _hours == 0 && _minutes == 0
                            ? null
                            : _hours * 60 + _minutes,
                      ),
                    ),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.s1),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoPicker(
                      key: const ValueKey('duration-hours-picker'),
                      scrollController: _hourController,
                      itemExtent: 44,
                      onSelectedItemChanged: _selectHour,
                      children: const [
                        Text('0 小时'),
                        Text('1 小时'),
                        Text('2 小时'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoPicker.builder(
                      key: const ValueKey('duration-minutes-picker'),
                      scrollController: _minuteController,
                      itemExtent: 44,
                      onSelectedItemChanged: _selectMinute,
                      itemBuilder: (context, index) =>
                          Center(child: Text('${index % 60} 分钟')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
