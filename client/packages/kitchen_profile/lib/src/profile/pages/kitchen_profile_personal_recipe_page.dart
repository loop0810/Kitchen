import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import '../providers/kitchen_profile_personal_recipe_config_provider.dart';

class PersonalRecipePage extends ConsumerWidget {
  const PersonalRecipePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(personalRecipeConfigProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('个性化食谱')),
      body: config.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('配置读取失败，请稍后重试')),
        data: (value) => ListView(
          padding: const EdgeInsets.all(AppSpacing.s16),
          children: [
            if (value.syncPending)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.s12),
                child: Text('已保存到本机，将在服务可用时同步'),
              ),
            _ManagementTile(
              icon: Icons.category_outlined,
              title: '管理分类',
              count: value.categories.length,
              kind: PersonalRecipeOptionKind.category,
            ),
            const SizedBox(height: AppSpacing.s8),
            _ManagementTile(
              icon: Icons.sell_outlined,
              title: '管理标签',
              count: value.tags.length,
              kind: PersonalRecipeOptionKind.tag,
            ),
            const SizedBox(height: AppSpacing.s8),
            _ManagementTile(
              icon: Icons.signal_cellular_alt_rounded,
              title: '管理难度',
              count: value.difficulties.length,
              kind: PersonalRecipeOptionKind.difficulty,
            ),
          ],
        ),
      ),
    );
  }
}

class _ManagementTile extends StatelessWidget {
  const _ManagementTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.kind,
  });

  final IconData icon;
  final String title;
  final int count;
  final PersonalRecipeOptionKind kind;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text('$count 项'),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => PersonalRecipeOptionListPage(kind: kind),
          ),
        ),
      ),
    );
  }
}

enum PersonalRecipeOptionKind { category, tag, difficulty }

class PersonalRecipeOptionListPage extends ConsumerWidget {
  const PersonalRecipeOptionListPage({required this.kind, super.key});

  final PersonalRecipeOptionKind kind;

  String get _title => switch (kind) {
    PersonalRecipeOptionKind.category => '分类',
    PersonalRecipeOptionKind.tag => '标签',
    PersonalRecipeOptionKind.difficulty => '难度',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(personalRecipeConfigProvider);
    return Scaffold(
      appBar: AppBar(title: Text('管理$_title')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text('新增$_title'),
      ),
      body: config.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('配置读取失败，请稍后重试')),
        data: (value) {
          final options = _options(value);
          if (options.isEmpty) {
            return Center(child: Text('还没有$_title'));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s8,
              AppSpacing.s16,
              AppSpacing.s120,
            ),
            itemCount: options.length,
            onReorderItem: (oldIndex, newIndex) {
              final reordered = [...options];
              final item = reordered.removeAt(oldIndex);
              reordered.insert(newIndex, item);
              _save(ref, value, reordered);
            },
            itemBuilder: (context, index) {
              final option = options[index];
              return Card(
                key: ValueKey(option),
                child: ListTile(
                  title: Text(option),
                  trailing: Wrap(
                    spacing: AppSpacing.s4,
                    children: [
                      IconButton(
                        tooltip: '重命名$option',
                        onPressed: () => _edit(context, ref, original: option),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: '删除$option',
                        onPressed: () => _delete(context, ref, option),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                      const Icon(Icons.drag_handle_rounded),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<String> _options(PersonalRecipeConfigEntity config) => switch (kind) {
    PersonalRecipeOptionKind.category => config.categories,
    PersonalRecipeOptionKind.tag => config.tags,
    PersonalRecipeOptionKind.difficulty => config.difficulties,
  };

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, {
    String? original,
  }) async {
    var draft = original ?? '';
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(original == null ? '新增$_title' : '重命名$_title'),
        content: TextFormField(
          initialValue: draft,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(labelText: '$_title名称'),
          onChanged: (value) => draft = value,
          onFieldSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, draft),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (value == null || !context.mounted) return;
    final normalized = value.trim();
    final config = ref.read(personalRecipeConfigProvider).value;
    if (config == null || normalized.isEmpty) return;
    final options = [..._options(config)];
    if (options.contains(normalized) && normalized != original) {
      showKitchenMessage(context, '“$normalized”已存在');
      return;
    }
    if (original == null) {
      options.add(normalized);
    } else {
      options[options.indexOf(original)] = normalized;
    }
    await _save(ref, config, options);
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    String option,
  ) async {
    final config = ref.read(personalRecipeConfigProvider).value;
    if (config == null) return;
    final options = [..._options(config)];
    if (kind != PersonalRecipeOptionKind.tag && options.length == 1) {
      showKitchenMessage(context, '至少保留一个$_title');
      return;
    }
    final confirmed = await showKitchenConfirmDialog(
      context,
      title: '删除“$option”？',
      message: '已有菜谱中的原值会保留。',
      confirmLabel: '删除',
    );
    if (!confirmed) return;
    options.remove(option);
    await _save(ref, config, options);
  }

  Future<void> _save(
    WidgetRef ref,
    PersonalRecipeConfigEntity config,
    List<String> options,
  ) {
    final updated = switch (kind) {
      PersonalRecipeOptionKind.category => config.copyWith(categories: options),
      PersonalRecipeOptionKind.tag => config.copyWith(tags: options),
      PersonalRecipeOptionKind.difficulty => config.copyWith(
        difficulties: options,
      ),
    };
    return ref
        .read(profileDependenciesProvider)
        .personalRecipeConfigRepository
        .save(updated);
  }
}
