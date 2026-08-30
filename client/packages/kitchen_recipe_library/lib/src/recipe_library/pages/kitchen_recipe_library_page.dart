import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';

import '../../collection/widgets/kitchen_recipe_library_collection_dialogs.dart';
import '../../collection/widgets/kitchen_recipe_library_collection_editor_dialog.dart';
import '../providers/kitchen_recipe_library_dependencies.dart';
import '../widgets/kitchen_recipe_library_recipe_card_widget.dart';

enum _LibrarySection { recipes, collections }

const _recipeCollectionActionAssetPackage = 'kitchen_recipe_library';
const _recipeCollectionEditAsset =
    'assets/images/recipe_collection_action_edit.png';
const _recipeCollectionManageAsset =
    'assets/images/recipe_collection_action_manage.png';
const _recipeCollectionDeleteAsset =
    'assets/images/recipe_collection_action_delete.png';

class RecipeLibraryPage extends ConsumerStatefulWidget {
  const RecipeLibraryPage({super.key});

  @override
  ConsumerState<RecipeLibraryPage> createState() => _RecipeLibraryPageState();
}

class _RecipeLibraryPageState extends ConsumerState<RecipeLibraryPage> {
  final _searchController = TextEditingController();
  final _pageController = PageController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipes = ref.watch(
      recipesProvider(
        RecipeQuery(text: _query, statusFilter: _filter, sortOrder: _sortOrder),
      ),
    );
    final collections = ref.watch(recipeCollectionsSearchProvider(_query));
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            _buildPageHeader(),
            _buildControlsHeader(),
          ],
          body: PageView(
            key: const ValueKey('recipe-library-sections'),
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildRecipeSection(recipes),
              _buildCollectionSection(collections),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return AppSliverPageHeader(
      key: const ValueKey('recipe-library-page-header'),
      title: '菜谱库',
      subtitle: '12 道菜谱 · 慢慢做，认真吃',
      subtitleColor: AppColor.x60483A,
      action: IconButton(
        tooltip: '回收站',
        onPressed: () => context.pushRecipeTrash<void>(),
        icon: const Icon(Icons.delete_outline_rounded),
        color: AppColor.x60483A,
      ),
      // expandedDecoration: const _RecipeLibraryHeaderDecorations(),
    );
  }

  Widget _buildControlsHeader() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _LibraryControlsHeaderDelegate(
        section: _section,
        pageController: _pageController,
        controller: _searchController,
        filter: _filter,
        onSectionChanged: _selectSection,
        onQueryChanged: (value) => setState(() => _query = value),
        onFilterChanged: (value) => setState(() => _filter = value),
        onSortOrder: _chooseSortOrder,
        onImport: _section == _LibrarySection.recipes
            ? context.showRecipeCreationOptions
            : _createCollection,
      ),
    );
  }

  void _selectSection(_LibrarySection section) {
    if (_section == section) return;
    setState(() => _section = section);
    _pageController.animateToPage(
      section.index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    final section = _LibrarySection.values[index];
    if (_section == section) return;
    setState(() => _section = section);
  }

  Widget _buildRecipeSection(
    AsyncValue<List<RecipeJournalSummaryEntity>> recipes,
  ) {
    return _RecipeSection(
      recipes: recipes,
      hasFilter: _query.isNotEmpty || _filter != RecipeStatusFilter.all,
      onCreate: context.showRecipeCreationOptions,
      onTap: (summary) => context.pushRecipeDetail(summary.recipe.id),
      onFavorite: (summary) => ref
          .read(recipeLibraryDependenciesProvider)
          .setFavorite(
            recipeId: summary.recipe.id,
            isFavorite: !summary.recipe.isFavorite,
          ),
      onLongPress: _showRecipeActions,
    );
  }

  Widget _buildCollectionSection(
    AsyncValue<List<RecipeCollectionEntity>> collections,
  ) {
    return _CollectionSection(
      collections: collections,
      onTap: (collection) => collection.memberCount == 0
          ? context.pushRecipeCollection<void>(collection.id)
          : context.pushRecipeCollectionReader<void>(collection.id),
      onLongPress: _showCollectionActions,
    );
  }

  Future<void> _createCollection() async {
    final result = await showCollectionCreationDialog(context);
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
    await showAppContextMenu(
      context: context,
      anchorPosition: globalPosition,
      actions: [
        AppContextMenuAction(
          iconAsset: _recipeCollectionEditAsset,
          iconAssetPackage: _recipeCollectionActionAssetPackage,
          title: '编辑',
          onTap: () => _editCollection(collection),
        ),
        AppContextMenuAction(
          iconAsset: _recipeCollectionManageAsset,
          iconAssetPackage: _recipeCollectionActionAssetPackage,
          title: '管理成员',
          onTap: () => context.pushRecipeCollection<void>(collection.id),
        ),
        AppContextMenuAction(
          iconAsset: _recipeCollectionDeleteAsset,
          iconAssetPackage: _recipeCollectionActionAssetPackage,
          title: '删除菜谱集',
          onTap: () => _deleteCollection(collection),
        ),
      ],
    );
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
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: '确定删除这个菜谱集？',
      content: '删除菜谱集不会删除其中的菜谱。\n这里只会删除集合关系，不会删除菜谱库中的原始菜谱。',
      actions: [
        AppDialogAction(
          title: '取消',
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        AppDialogAction(
          title: '确认删除',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ],
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(recipeLibraryDependenciesProvider)
        .deleteCollection
        ?.call(collection.id);
  }

  Future<void> _chooseSortOrder() async {
    final chosen = await showAppSingleSelectSheet<RecipeSortOrder>(
      context: context,
      title: '选择排序方式',
      subtitle: '更容易找到这一刻想做的菜',
      selected: _sortOrder,
      options: const [
        AppSingleSelectSheetOption<RecipeSortOrder>(
          value: RecipeSortOrder.recentlyUpdated,
          title: '最近更新',
          subtitle: '刚添加的新灵感排在前面',
          icon: Icons.sync_rounded,
          iconBackgroundColor: AppColor.xF26A58,
          iconColor: AppColor.xFFFDF8,
        ),
        AppSingleSelectSheetOption<RecipeSortOrder>(
          value: RecipeSortOrder.recentlySaved,
          title: '最近保存',
          subtitle: '先看看你收藏的好味道',
          icon: Icons.bookmark_rounded,
          iconBackgroundColor: AppColor.xE6ECEA,
          iconColor: AppColor.x506E67,
        ),
        AppSingleSelectSheetOption<RecipeSortOrder>(
          value: RecipeSortOrder.title,
          title: '菜名',
          subtitle: '按名字顺序慢慢翻找',
          icon: Icons.title_rounded,
          iconBackgroundColor: AppColor.xF5D477,
          iconColor: AppColor.x60483A,
        ),
      ],
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
    await showAppContextMenu(
      context: context,
      anchorPosition: globalPosition,
      actions: [
        AppContextMenuAction(
          icon: Icons.edit_outlined,
          title: '编辑菜谱',
          onTap: () => context.pushEditRecipe<void>(summary.recipe.id),
        ),
        AppContextMenuAction(
          icon: Icons.collections_bookmark_outlined,
          title: '管理菜谱集',
          onTap: () => _manageRecipeCollections(summary.recipe.id),
        ),
        AppContextMenuAction(
          icon: Icons.delete_outline_rounded,
          title: '移入回收站',
          onTap: () => _moveRecipeToTrash(summary.recipe),
        ),
      ],
    );
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
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: '移入回收站？',
      content: '“${recipe.title}”会保留 30 天，期间可以从回收站恢复。',
      actions: [
        AppDialogAction(
          title: '取消',
          onPressed: () =>
              Navigator.of(context, rootNavigator: true).pop(false),
        ),
        AppDialogAction(
          title: '移入回收站',
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        ),
      ],
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

class _RecipeSection extends StatelessWidget {
  const _RecipeSection({
    required this.recipes,
    required this.hasFilter,
    required this.onCreate,
    required this.onTap,
    required this.onFavorite,
    required this.onLongPress,
  });

  final AsyncValue<List<RecipeJournalSummaryEntity>> recipes;
  final bool hasFilter;
  final VoidCallback onCreate;
  final ValueChanged<RecipeJournalSummaryEntity> onTap;
  final ValueChanged<RecipeJournalSummaryEntity> onFavorite;
  final void Function(RecipeJournalSummaryEntity, Offset) onLongPress;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('recipe-library-scroll'),
      slivers: [
        recipes.when(
          data: (items) => items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyLibrary(
                    hasFilter: hasFilter,
                    onCreate: onCreate,
                  ),
                )
              : SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final columns =
                        constraints.crossAxisExtent < 320 || textScale > 1.3
                        ? 1
                        : 2;
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s16,
                        AppSpacing.s10,
                        AppSpacing.s16,
                        AppSpacing.s24,
                      ),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final summary = items[index];
                          return RecipeCardWidget(
                            recipe: summary,
                            placeholder: true,
                            onTap: () => onTap(summary),
                            onFavorite: () => onFavorite(summary),
                            onLongPress: (position) =>
                                onLongPress(summary, position),
                          );
                        }, childCount: items.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppSpacing.s12,
                          mainAxisSpacing: AppSpacing.s12,
                          childAspectRatio: AppSize.recipeCardAspectRatio,
                        ),
                      ),
                    );
                  },
                ),
          error: (_, _) => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('菜谱加载失败，请稍后重试')),
          ),
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class _CollectionSection extends StatelessWidget {
  const _CollectionSection({
    required this.collections,
    required this.onTap,
    required this.onLongPress,
  });

  final AsyncValue<List<RecipeCollectionEntity>> collections;
  final ValueChanged<RecipeCollectionEntity> onTap;
  final void Function(RecipeCollectionEntity, Offset) onLongPress;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey('recipe-collection-scroll'),
      slivers: [
        collections.when(
          data: (items) => items.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: const _EmptyCollections(),
                )
              : SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final columns =
                        constraints.crossAxisExtent < 320 || textScale > 1.3
                        ? 1
                        : 2;
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.s16,
                        AppSpacing.s10,
                        AppSpacing.s16,
                        AppSpacing.s24,
                      ),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final collection = items[index];
                          return _CollectionBookCard(
                            key: ValueKey(collection.id),
                            collection: collection,
                            onTap: () => onTap(collection),
                            onLongPress: (position) =>
                                onLongPress(collection, position),
                          );
                        }, childCount: items.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppSpacing.s16,
                          mainAxisSpacing: AppSpacing.s20,
                          childAspectRatio: columns == 1 ? 0.9 : 0.7,
                        ),
                      ),
                    );
                  },
                ),
          error: (_, _) => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('菜谱集加载失败，请稍后重试')),
          ),
          loading: () => const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }
}

class _LibraryControlsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _LibraryControlsHeaderDelegate({
    required this.section,
    required this.pageController,
    required this.controller,
    required this.filter,
    required this.onSectionChanged,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onSortOrder,
    required this.onImport,
  });

  final _LibrarySection section;
  final PageController pageController;
  final TextEditingController controller;
  final RecipeStatusFilter filter;
  final ValueChanged<_LibrarySection> onSectionChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<RecipeStatusFilter> onFilterChanged;
  final VoidCallback onSortOrder;
  final VoidCallback onImport;

  static const _recipeControlsHeight = 149.0;
  static const _collectionControlsHeight = 106.0;

  double get _height => section == _LibrarySection.recipes
      ? _recipeControlsHeight
      : _collectionControlsHeight;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isRecipes = section == _LibrarySection.recipes;
    return Material(
      key: ValueKey('recipe-library-sticky-controls-${section.name}'),
      color: Theme.of(context).colorScheme.surface,
      elevation: overlapsContent ? 2 : 0,
      shadowColor: AppColor.x60483A.withValues(alpha: 0.14),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColor.xE8DAC1, width: 1)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s16,
            AppSpacing.s6,
            AppSpacing.s16,
            AppSpacing.s8,
          ),
          child: Column(
            children: [
              SizedBox(
                height: AppSize.librarySegmentHeight,
                child: _LibrarySectionSwitcher(
                  selected: section,
                  pageController: pageController,
                  onChanged: onSectionChanged,
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              if (isRecipes) ...[
                SizedBox(
                  height: AppSize.librarySearchHeight,
                  child: _buildSearchField(isRecipes: true),
                ),
                const SizedBox(height: AppSpacing.s7),
                SizedBox(
                  height: AppSize.libraryFilterHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: AppSegmentedButtonGroup<RecipeStatusFilter>(
                            options: [
                              for (final item in RecipeStatusFilter.values)
                                AppSegmentedButtonOption(
                                  value: item,
                                  label: _filterLabel(item),
                                ),
                            ],
                            selected: filter,
                            onChanged: onFilterChanged,
                            height: AppSize.libraryFilterHeight,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.s10,
                            ),
                            fontSize: AppText.label,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      _buildImportButton(label: '导入菜谱'),
                    ],
                  ),
                ),
              ] else
                SizedBox(
                  height: AppSize.librarySearchHeight,
                  child: Row(
                    children: [
                      Expanded(child: _buildSearchField(isRecipes: false)),
                      const SizedBox(width: AppSpacing.s8),
                      _buildImportButton(label: '创建菜谱集'),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField({required bool isRecipes}) {
    return TextField(
      key: const ValueKey('recipe-library-search-field'),
      controller: controller,
      onChanged: onQueryChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: isRecipes ? '搜索菜谱、食材或标签' : '搜索菜谱集或菜谱',
        prefixIcon: const Icon(Icons.search_rounded, size: AppSize.icon20),
        suffixIcon: isRecipes
            ? IconButton(
                tooltip: '菜谱排序',
                onPressed: onSortOrder,
                icon: const Icon(Icons.tune_rounded),
              )
            : const SizedBox(
                width: AppSize.librarySearchHeight,
                height: AppSize.librarySearchHeight,
              ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: AppSize.librarySearchHeight,
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: AppSize.librarySearchHeight,
          minHeight: AppSize.librarySearchHeight,
          maxHeight: AppSize.librarySearchHeight,
        ),
        isDense: true,
        filled: true,
        fillColor: AppColor.xFFFDF8,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          borderSide: const BorderSide(color: AppColor.x60483A, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
          borderSide: const BorderSide(color: AppColor.xF26A58, width: 1.8),
        ),
      ),
    );
  }

  Widget _buildImportButton({required String label}) {
    return SizedBox(
      height: AppSize.libraryFilterHeight,
      child: AppImportButton(
        onPressed: onImport,
        label: label,
        icon: Icons.add_circle_outline_rounded,
        height: AppSize.libraryFilterHeight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s10),
        iconSize: AppSize.icon17,
        fontSize: AppText.label,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LibraryControlsHeaderDelegate oldDelegate) {
    return true;
  }
}

class _LibrarySectionSwitcher extends StatelessWidget {
  const _LibrarySectionSwitcher({
    required this.selected,
    required this.pageController,
    required this.onChanged,
  });

  final _LibrarySection selected;
  final PageController pageController;
  final ValueChanged<_LibrarySection> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: ValueKey('recipe-library-section-switcher-${selected.name}'),
      decoration: BoxDecoration(
        color: AppColor.xF7ECD9,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        border: Border.all(color: AppColor.xEAD7BD, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColor.xEADCC3, offset: Offset(1, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: pageController,
                  builder: (context, child) => LayoutBuilder(
                    builder: (context, constraints) {
                      final halfWidth = constraints.maxWidth / 2;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Positioned(
                            left: halfWidth * _pageProgress,
                            top: 0,
                            bottom: 0,
                            width: halfWidth,
                            child: child!,
                          ),
                        ],
                      );
                    },
                  ),
                  child: DecoratedBox(
                    key: const ValueKey(
                      'recipe-library-section-selection-indicator',
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.xFFFDF6,
                      border: Border.all(color: AppColor.xEF6859, width: 2),
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColor.xD9A091,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _buildItem(_LibrarySection.recipes, '菜谱'),
                _buildItem(_LibrarySection.collections, '菜谱集'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double get _pageProgress {
    final page = pageController.hasClients
        ? pageController.page
        : selected.index.toDouble();
    return (page ?? selected.index.toDouble()).clamp(0.0, 1.0).toDouble();
  }

  Widget _buildItem(_LibrarySection section, String label) {
    final isSelected = selected == section;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(section),
            borderRadius: BorderRadius.circular(AppRadius.r12),
            child: DecoratedBox(
              key: ValueKey('recipe-library-section-option-${section.name}'),
              decoration: const BoxDecoration(),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColor.xA94B3F : AppColor.x60483A,
                    fontSize: AppText.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
                            color: AppColor.xFFFAF2,
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
  const _EmptyCollections();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.collections_bookmark_outlined, size: AppSize.icon54),
        const SizedBox(height: AppSpacing.s16),
        const Text('把常做的菜整理进菜谱集'),
      ],
    ),
  );
}

String _filterLabel(RecipeStatusFilter filter) => switch (filter) {
  RecipeStatusFilter.all => '全部',
  RecipeStatusFilter.favorite => '收藏',
  RecipeStatusFilter.incomplete => '待完善',
};
