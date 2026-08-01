import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import 'kitchen_recipe_library_collection_dialogs.dart';
import 'kitchen_recipe_library_collection_editor_dialog.dart';
import 'kitchen_recipe_library_dependencies.dart';
import 'kitchen_recipe_library_recipe_card_widget.dart';

enum _LibrarySection { recipes, collections }

enum _LibraryMenuAction { trash }

enum _RecipeCardAction { edit, collections, trash }

enum _CollectionAction { edit, members, delete }

class RecipeLibraryPage extends ConsumerStatefulWidget {
  const RecipeLibraryPage({super.key});

  @override
  ConsumerState<RecipeLibraryPage> createState() => _RecipeLibraryPageState();
}

class _RecipeLibraryPageState extends ConsumerState<RecipeLibraryPage> {
  final _searchController = TextEditingController();
  final _pageController = PageController();
  final _recipeScrollController = ScrollController();
  final _collectionScrollController = ScrollController();
  var _query = '';
  var _filter = RecipeStatusFilter.all;
  var _sortOrder = RecipeSortOrder.recentlyUpdated;
  var _section = _LibrarySection.recipes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final getter = ref
          .read(recipeLibraryDependenciesProvider)
          .getSortPreference;
      if (getter == null) return;
      final saved = await getter();
      if (mounted) setState(() => _sortOrder = saved);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageController.dispose();
    _recipeScrollController.dispose();
    _collectionScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(
      recipesProvider(
        RecipeQuery(text: _query, statusFilter: _filter, sortOrder: _sortOrder),
      ),
    );
    final collections = ref.watch(recipeCollectionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的菜谱'),
        actions: [
          PopupMenuButton<_LibraryMenuAction>(
            tooltip: '菜谱库菜单',
            onSelected: (_) => context.pushRecipeTrash(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _LibraryMenuAction.trash,
                child: ListTile(
                  leading: Icon(Icons.delete_outline_rounded),
                  title: Text('回收站'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: _section == _LibrarySection.recipes ? '创建菜谱' : '创建菜谱集',
            onPressed: _section == _LibrarySection.recipes
                ? context.showRecipeCreationOptions
                : _createCollection,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: AppSpacing.s8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: SegmentedButton<_LibrarySection>(
              segments: const [
                ButtonSegment(
                  value: _LibrarySection.recipes,
                  label: Text('菜谱'),
                ),
                ButtonSegment(
                  value: _LibrarySection.collections,
                  label: Text('菜谱集'),
                ),
              ],
              selected: {_section},
              onSelectionChanged: (value) {
                final section = value.single;
                _pageController.animateToPage(
                  section.index,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) =>
                  setState(() => _section = _LibrarySection.values[index]),
              children: [
                _buildRecipeSection(recipes),
                _buildCollectionSection(collections),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSection(
    AsyncValue<List<RecipeJournalSummaryEntity>> recipes,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: '搜索我的菜谱',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: '菜谱排序',
                onPressed: _chooseSortOrder,
                icon: const Icon(Icons.sort_rounded),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s8,
            AppSpacing.s16,
            AppSpacing.s4,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '排序：${_sortOrderLabel(_sortOrder)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        SizedBox(
          height: AppSize.filterBarHeight,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
            scrollDirection: Axis.horizontal,
            children: RecipeStatusFilter.values
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(filter)),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Expanded(
          child: recipes.when(
            data: (items) => items.isEmpty
                ? _EmptyLibrary(
                    hasFilter:
                        _query.isNotEmpty || _filter != RecipeStatusFilter.all,
                    onCreate: context.showRecipeCreationOptions,
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final columns =
                          constraints.maxWidth < 320 || textScale > 1.3 ? 1 : 2;
                      return GridView.builder(
                        key: const PageStorageKey('recipe-library-grid'),
                        controller: _recipeScrollController,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.s16,
                          AppSpacing.s8,
                          AppSpacing.s16,
                          AppSpacing.s24,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppSpacing.s12,
                          mainAxisSpacing: AppSpacing.s12,
                          childAspectRatio: AppSize.recipeCardAspectRatio,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final summary = items[index];
                          return RecipeCardWidget(
                            recipe: summary,
                            onTap: () =>
                                context.pushRecipeDetail(summary.recipe.id),
                            onFavorite: () => ref
                                .read(recipeLibraryDependenciesProvider)
                                .setFavorite(
                                  recipeId: summary.recipe.id,
                                  isFavorite: !summary.recipe.isFavorite,
                                ),
                            onLongPress: (position) =>
                                _showRecipeActions(summary, position),
                          );
                        },
                      );
                    },
                  ),
            error: (_, _) => const Center(child: Text('菜谱加载失败，请稍后重试')),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectionSection(
    AsyncValue<List<RecipeCollectionEntity>> value,
  ) {
    return value.when(
      data: (items) {
        if (items.isEmpty) {
          return _EmptyCollections(onCreate: _createCollection);
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final textScale = MediaQuery.textScalerOf(context).scale(1);
            final columns = constraints.maxWidth < 320 || textScale > 1.3
                ? 1
                : 2;
            return GridView.builder(
              key: const PageStorageKey('recipe-collection-grid'),
              controller: _collectionScrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s16,
                AppSpacing.s24,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: AppSpacing.s16,
                mainAxisSpacing: AppSpacing.s20,
                childAspectRatio: columns == 1 ? 0.9 : 0.7,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final collection = items[index];
                return _CollectionBookCard(
                  key: ValueKey(collection.id),
                  collection: collection,
                  onTap: () => collection.memberCount == 0
                      ? context.pushRecipeCollection<void>(collection.id)
                      : context.pushRecipeCollectionReader<void>(collection.id),
                  onLongPress: (position) =>
                      _showCollectionActions(collection, position),
                );
              },
            );
          },
        );
      },
      error: (_, _) => const Center(child: Text('菜谱集加载失败，请稍后重试')),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _createCollection() async {
    final result = await showCollectionEditorDialog(context, title: '创建菜谱集');
    if (result == null || !mounted) return;
    await ref
        .read(recipeLibraryDependenciesProvider)
        .createCollection
        ?.call(name: result.name, coverBytes: result.coverChange.bytes);
  }

  Future<void> _showCollectionActions(
    RecipeCollectionEntity collection,
    Offset globalPosition,
  ) async {
    unawaited(HapticFeedback.mediumImpact());
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<_CollectionAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: const [
        PopupMenuItem(value: _CollectionAction.edit, child: Text('编辑')),
        PopupMenuItem(value: _CollectionAction.members, child: Text('管理成员')),
        PopupMenuItem(value: _CollectionAction.delete, child: Text('删除菜谱集')),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _CollectionAction.edit:
        await _editCollection(collection);
      case _CollectionAction.members:
        await context.pushRecipeCollection<void>(collection.id);
      case _CollectionAction.delete:
        await _deleteCollection(collection);
    }
  }

  Future<void> _editCollection(RecipeCollectionEntity collection) async {
    final result = await showCollectionEditorDialog(
      context,
      title: '编辑菜谱集',
      initialName: collection.name,
      initialCoverBytes: collection.coverBytes,
    );
    if (result == null || !mounted) return;
    await ref
        .read(recipeLibraryDependenciesProvider)
        .updateCollection
        ?.call(
          collectionId: collection.id,
          name: result.name,
          coverChange: result.coverChange,
        );
  }

  Future<void> _deleteCollection(RecipeCollectionEntity collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除菜谱集？'),
        content: Text('只会删除“${collection.name}”及其成员关系，不会删除其中的菜谱。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(recipeLibraryDependenciesProvider)
        .deleteCollection
        ?.call(collection.id);
  }

  Future<void> _chooseSortOrder() async {
    final chosen = await showModalBottomSheet<RecipeSortOrder>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RecipeSortOrder.values
              .map(
                (order) => ListTile(
                  leading: Icon(
                    order == _sortOrder
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                  ),
                  title: Text(_sortOrderLabel(order)),
                  onTap: () => Navigator.pop(context, order),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() => _sortOrder = chosen);
    await ref
        .read(recipeLibraryDependenciesProvider)
        .setSortPreference
        ?.call(chosen);
  }

  Future<void> _showRecipeActions(
    RecipeJournalSummaryEntity summary,
    Offset globalPosition,
  ) async {
    // 触觉反馈不应阻塞浮层出现；某些测试环境或系统设置不会返回实际反馈。
    unawaited(HapticFeedback.mediumImpact());
    if (!mounted) return;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<_RecipeCardAction>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      items: const [
        PopupMenuItem(
          value: _RecipeCardAction.edit,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_outlined),
            title: Text('编辑菜谱'),
          ),
        ),
        PopupMenuItem(
          value: _RecipeCardAction.collections,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.collections_bookmark_outlined),
            title: Text('管理菜谱集'),
          ),
        ),
        PopupMenuItem(
          value: _RecipeCardAction.trash,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline_rounded),
            title: Text('移入回收站'),
          ),
        ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _RecipeCardAction.edit:
        await context.pushEditRecipe<void>(summary.recipe.id);
      case _RecipeCardAction.collections:
        await _manageRecipeCollections(summary.recipe.id);
      case _RecipeCardAction.trash:
        await _moveRecipeToTrash(summary.recipe);
    }
  }

  Future<void> _manageRecipeCollections(String recipeId) async {
    final dependencies = ref.read(recipeLibraryDependenciesProvider);
    final watchCollections = dependencies.watchCollections;
    final getIds = dependencies.getCollectionIdsForRecipe;
    if (watchCollections == null || getIds == null) return;
    final collections = await watchCollections().first;
    final selectedIds = await getIds(recipeId);
    if (!mounted) return;
    final selected = await showCollectionSelectionDialog(
      context,
      collections: collections,
      selectedIds: selectedIds,
      onCreate: () async {
        final name = await showCollectionNameDialog(context, title: '新建菜谱集');
        if (name == null) return null;
        final id = await dependencies.createCollection?.call(name: name);
        if (id == null) return null;
        final now = DateTime.now();
        return RecipeCollectionEntity(
          id: id,
          name: name,
          memberCount: 0,
          coverBytes: null,
          createdAt: now,
          updatedAt: now,
        );
      },
    );
    if (selected == null || !mounted) return;
    await dependencies.setCollectionsForRecipe?.call(
      recipeId: recipeId,
      collectionIds: selected,
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('菜谱集已更新')));
    }
  }

  Future<void> _moveRecipeToTrash(RecipeEntity recipe) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移入回收站？'),
        content: Text('“${recipe.title}”会保留 30 天，期间可以从回收站恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('移入回收站'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(recipeLibraryDependenciesProvider)
        .moveToTrash
        ?.call(recipe.id);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('菜谱已移入回收站')));
    }
  }
}

class _CollectionBookCard extends StatelessWidget {
  const _CollectionBookCard({
    super.key,
    required this.collection,
    required this.onTap,
    required this.onLongPress,
  });
  final RecipeCollectionEntity collection;
  final VoidCallback onTap;
  final ValueChanged<Offset> onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = _bookColors(collection.id);
    return Semantics(
      button: true,
      label: collection.memberCount == 0
          ? '${collection.name}，空菜谱集，点击添加菜谱，长按管理'
          : '${collection.name}，${collection.memberCount} 道菜谱，点击翻阅，长按管理',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPressStart: (details) => onLongPress(details.globalPosition),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x30000000),
                        blurRadius: 10,
                        offset: Offset(4, 6),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        left: AppSpacing.s8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColor.paper,
                            borderRadius: BorderRadius.circular(AppRadius.r12),
                            border: Border.all(color: colors.$2, width: 2),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        right: AppSpacing.s6,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.r12),
                          child: collection.coverBytes == null
                              ? _DefaultBookCover(
                                  name: collection.name,
                                  colors: colors,
                                )
                              : Image.memory(
                                  collection.coverBytes!,
                                  fit: BoxFit.cover,
                                  cacheWidth: 450,
                                  errorBuilder: (_, _, _) => _DefaultBookCover(
                                    name: collection.name,
                                    colors: colors,
                                  ),
                                ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: AppSpacing.s12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colors.$2,
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(AppRadius.r12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              collection.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            Text(
              '${collection.memberCount} 道菜谱',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DefaultBookCover extends StatelessWidget {
  const _DefaultBookCover({required this.name, required this.colors});
  final String name;
  final (Color, Color) colors;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: colors.$1,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: AppSpacing.s16,
          right: AppSpacing.s12,
          child: Icon(Icons.local_florist_outlined, color: colors.$2),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colors.$2),
              borderRadius: BorderRadius.circular(AppRadius.r18),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s12),
                child: Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.$2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: AppSpacing.s16,
          child: Icon(Icons.restaurant_menu_rounded, color: colors.$2),
        ),
      ],
    ),
  );
}

(Color, Color) _bookColors(String id) {
  const palettes = [
    (Color(0xFFF3D9D2), Color(0xFF8D4D43)),
    (Color(0xFFDDE7D6), Color(0xFF4F6948)),
    (Color(0xFFE6DDF0), Color(0xFF66507A)),
    (Color(0xFFF0E2BE), Color(0xFF786137)),
  ];
  return palettes[id.hashCode.abs() % palettes.length];
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.hasFilter, required this.onCreate});
  final bool hasFilter;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasFilter ? Icons.search_off_rounded : Icons.menu_book_rounded,
          size: AppSize.icon54,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.s16),
        Text(hasFilter ? '没有找到符合条件的菜谱' : '开始建立你的菜谱本'),
        if (!hasFilter) ...[
          const SizedBox(height: AppSpacing.s16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('创建第一道菜谱'),
          ),
        ],
      ],
    ),
  );
}

class _EmptyCollections extends StatelessWidget {
  const _EmptyCollections({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.collections_bookmark_outlined, size: AppSize.icon54),
        const SizedBox(height: AppSpacing.s16),
        const Text('把常做的菜整理进菜谱集'),
        const SizedBox(height: AppSpacing.s16),
        FilledButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add_rounded),
          label: const Text('创建菜谱集'),
        ),
      ],
    ),
  );
}

String _filterLabel(RecipeStatusFilter filter) => switch (filter) {
  RecipeStatusFilter.all => '全部',
  RecipeStatusFilter.favorite => '收藏',
  RecipeStatusFilter.cooked => '做过',
  RecipeStatusFilter.incomplete => '待完善',
};

String _sortOrderLabel(RecipeSortOrder order) => switch (order) {
  RecipeSortOrder.recentlyUpdated => '最近更新',
  RecipeSortOrder.recentlySaved => '最近保存',
  RecipeSortOrder.recentlyCooked => '最近做过',
  RecipeSortOrder.mostCooked => '最常制作',
  RecipeSortOrder.title => '菜名',
};
