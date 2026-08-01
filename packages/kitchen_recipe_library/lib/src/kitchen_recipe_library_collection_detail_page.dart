import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_library_collection_dialogs.dart';
import 'kitchen_recipe_library_dependencies.dart';

/// 仅用于维护菜谱集成员的页面，从菜谱集长按菜单进入。
class RecipeCollectionDetailPage extends ConsumerWidget {
  const RecipeCollectionDetailPage({super.key, required this.collectionId});

  /// 当前维护的菜谱集 ID。
  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(recipeCollectionDetailProvider(collectionId));
    return detail.when(
      data: (value) => value == null
          ? const Scaffold(body: Center(child: Text('菜谱集不存在或已被删除')))
          : _CollectionMemberContent(detail: value),
      error: (_, _) =>
          const Scaffold(body: Center(child: Text('菜谱集加载失败，请稍后重试'))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _CollectionMemberContent extends ConsumerStatefulWidget {
  const _CollectionMemberContent({required this.detail});

  final RecipeCollectionDetailEntity detail;

  @override
  ConsumerState<_CollectionMemberContent> createState() =>
      _CollectionMemberContentState();
}

class _CollectionMemberContentState
    extends ConsumerState<_CollectionMemberContent> {
  late List<RecipeCollectionMemberEntity> _members;

  @override
  void initState() {
    super.initState();
    _members = [...widget.detail.members];
  }

  @override
  void didUpdateWidget(covariant _CollectionMemberContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.members != widget.detail.members) {
      _members = [...widget.detail.members];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('管理“${widget.detail.collection.name}”'),
        actions: [
          IconButton(
            tooltip: '添加菜谱',
            onPressed: _addMembers,
            icon: const Icon(Icons.playlist_add_rounded),
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: _members.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.playlist_add_rounded, size: AppSize.icon54),
                  const SizedBox(height: AppSpacing.s16),
                  const Text('这个菜谱集还没有菜谱'),
                  const SizedBox(height: AppSpacing.s16),
                  FilledButton.icon(
                    onPressed: _addMembers,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('添加菜谱'),
                  ),
                ],
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(AppSpacing.s16),
              buildDefaultDragHandles: false,
              itemCount: _members.length,
              onReorderItem: _reorder,
              itemBuilder: (context, index) {
                final member = _members[index];
                final recipe = member.recipe.recipe;
                return Padding(
                  key: ValueKey(recipe.id),
                  padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                  child: Slidable(
                    key: ValueKey('member-${recipe.id}'),
                    endActionPane: ActionPane(
                      motion: const DrawerMotion(),
                      extentRatio: 0.3,
                      children: [
                        SlidableAction(
                          onPressed: (_) => _removeMember(member),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                          icon: Icons.remove_circle_outline_rounded,
                          label: '移除',
                        ),
                      ],
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(recipe.coverColor),
                          child: const Icon(Icons.restaurant_menu_rounded),
                        ),
                        title: Text(recipe.title),
                        subtitle: Text(recipe.category),
                        onTap: () => context.pushRecipeDetail(recipe.id),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Tooltip(
                            message: '长按拖动排序',
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.s12),
                              child: Icon(Icons.drag_handle_rounded),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _members.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _addMembers,
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('添加菜谱'),
            ),
    );
  }

  Future<void> _addMembers() async {
    final dependencies = ref.read(recipeLibraryDependenciesProvider);
    final allRecipes = await dependencies
        .watchRecipes(const RecipeQuery())
        .first;
    final existing = _members.map((item) => item.recipe.recipe.id).toSet();
    final candidates = allRecipes
        .where((item) => !existing.contains(item.recipe.id))
        .toList(growable: false);
    if (!mounted) return;
    final selected = await showRecipeSelectionDialog(
      context,
      title: '添加菜谱',
      recipes: candidates,
      selectedIds: const {},
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    await dependencies.appendRecipesToCollection?.call(
      collectionId: widget.detail.collection.id,
      orderedRecipeIds: selected.toList(growable: false),
    );
    ref.invalidate(recipeCollectionDetailProvider(widget.detail.collection.id));
  }

  Future<void> _removeMember(RecipeCollectionMemberEntity member) async {
    final dependencies = ref.read(recipeLibraryDependenciesProvider);
    final recipeId = member.recipe.recipe.id;
    final index = _members.indexWhere(
      (item) => item.recipe.recipe.id == recipeId,
    );
    if (index < 0) return;
    setState(() => _members.removeAt(index));
    try {
      final originalPosition =
          await dependencies.removeRecipeFromCollection?.call(
            collectionId: widget.detail.collection.id,
            recipeId: recipeId,
          ) ??
          member.position;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已从菜谱集移除“${member.recipe.recipe.title}”'),
          action: SnackBarAction(
            label: '撤销',
            onPressed: () async {
              await dependencies.restoreRecipeToCollection?.call(
                collectionId: widget.detail.collection.id,
                recipeId: recipeId,
                position: originalPosition,
              );
              ref.invalidate(
                recipeCollectionDetailProvider(widget.detail.collection.id),
              );
            },
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _members.insert(index, member));
    }
  }

  Future<void> _reorder(int oldIndex, int newIndex) async {
    final previous = [..._members];
    setState(() {
      final moved = _members.removeAt(oldIndex);
      _members.insert(newIndex, moved);
    });
    try {
      await ref
          .read(recipeLibraryDependenciesProvider)
          .reorderCollectionMembers
          ?.call(
            collectionId: widget.detail.collection.id,
            orderedRecipeIds: _members
                .map((item) => item.recipe.recipe.id)
                .toList(growable: false),
          );
    } catch (_) {
      if (mounted) setState(() => _members = previous);
    }
  }
}
