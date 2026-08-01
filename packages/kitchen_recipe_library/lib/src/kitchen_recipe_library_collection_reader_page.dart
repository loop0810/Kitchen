import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_design_system/kitchen_design_system.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_template/kitchen_recipe_template.dart';

import 'kitchen_recipe_library_dependencies.dart';

/// 只读翻阅一个菜谱集手账摘要的全屏页面。
class RecipeCollectionReaderPage extends ConsumerWidget {
  const RecipeCollectionReaderPage({super.key, required this.collectionId});

  /// 本次阅读范围所属的菜谱集 ID。
  final String collectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(
      recipeCollectionReaderSnapshotProvider(collectionId),
    );
    return snapshot.when(
      data: (value) {
        if (value == null) {
          return const _ReaderMessagePage(message: '菜谱集不存在或已被删除');
        }
        if (value.entries.isEmpty) {
          return _ReaderEmptyPage(collection: value.collection);
        }
        return _ReaderContent(snapshot: value);
      },
      error: (_, _) => const _ReaderMessagePage(message: '菜谱集加载失败，请稍后重试'),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _ReaderContent extends ConsumerStatefulWidget {
  const _ReaderContent({required this.snapshot});

  final RecipeCollectionReaderSnapshotEntity snapshot;

  @override
  ConsumerState<_ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends ConsumerState<_ReaderContent> {
  late final PageController _pageController;
  late final List<RecipeCollectionReaderEntryEntity> _entries;
  var _currentIndex = 0;
  var _isPaging = false;
  var _openingDetail = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _entries = [...widget.snapshot.entries];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _entries[_currentIndex];
    return Scaffold(
      appBar: AppBar(title: Text(widget.snapshot.collection.name)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.s8),
            Semantics(
              liveRegion: true,
              label:
                  '当前分组 ${current.groupLabel}，${current.recipe.recipe.title}',
              child: Text(
                '${current.groupLabel} · ${current.recipe.recipe.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification &&
                      !_isPaging &&
                      mounted) {
                    setState(() => _isPaging = true);
                  } else if (notification is ScrollEndNotification &&
                      _isPaging &&
                      mounted) {
                    setState(() => _isPaging = false);
                  }
                  return false;
                },
                child: PageView.builder(
                  key: const ValueKey('recipe-collection-reader-pages'),
                  controller: _pageController,
                  itemCount: _entries.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 180),
                      tween: Tween(
                        begin: 0.97,
                        end: index == _currentIndex ? 1 : 0.97,
                      ),
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s6,
                          vertical: AppSpacing.s8,
                        ),
                        child: _ReaderJournalPage(
                          entry: entry,
                          enabled: !_isPaging && !_openingDetail,
                          onTap: () => _openDetail(index),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s16,
                AppSpacing.s8,
                AppSpacing.s16,
                AppSpacing.s16,
              ),
              child: Semantics(
                liveRegion: true,
                label: '第 ${_currentIndex + 1} 页，共 ${_entries.length} 页',
                child: Text('${_currentIndex + 1} / ${_entries.length}'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetail(int index) async {
    if (_isPaging || _openingDetail || index != _currentIndex) return;
    setState(() => _openingDetail = true);
    final entry = _entries[index];
    await context.pushRecipeDetail<void>(entry.recipe.recipe.id);
    if (!mounted) return;
    final refresher = ref
        .read(recipeLibraryDependenciesProvider)
        .getRecipeJournalSummary;
    if (refresher == null) {
      setState(() => _openingDetail = false);
      return;
    }
    final refreshed = await refresher(entry.recipe.recipe.id);
    if (!mounted) return;
    if (refreshed == null) {
      _removeUnavailableEntry(index);
      return;
    }
    setState(() {
      _entries[index] = RecipeCollectionReaderEntryEntity(
        recipe: refreshed,
        groupLabel: entry.groupLabel,
      );
      _openingDetail = false;
    });
  }

  void _removeUnavailableEntry(int index) {
    _entries.removeAt(index);
    if (_entries.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('这个菜谱集已没有可翻阅的菜谱')));
      return;
    }
    setState(() {
      _currentIndex = math.min(index, _entries.length - 1);
      _openingDetail = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }
}

class _ReaderJournalPage extends StatelessWidget {
  const _ReaderJournalPage({
    required this.entry,
    required this.enabled,
    required this.onTap,
  });

  final RecipeCollectionReaderEntryEntity entry;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = entry.recipe;
    final resolution = BuiltInTemplates.defaultResolver(
      summary.recipe.templateSelection,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(
          constraints.maxWidth,
          constraints.maxHeight * resolution.definition.aspectRatio,
        );
        return Center(
          child: SizedBox(
            width: width,
            child: Semantics(
              button: true,
              label: '${summary.recipe.title}，查看详细步骤',
              child: Card(
                elevation: 10,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: enabled ? onTap : null,
                  child: Stack(
                    children: [
                      RecipeTemplateRendererWidget(
                        definition: resolution.definition,
                        data: RecipeTemplateDataMapper.fromJournalSummary(
                          summary,
                        ),
                        mode: TemplateRenderMode.reader,
                      ),
                      if (summary.recipe.status == RecipeStatus.incomplete)
                        Positioned(
                          left: AppSpacing.s12,
                          bottom: AppSpacing.s12,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColor.paper.withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(
                                AppRadius.r10,
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.s8,
                                vertical: AppSpacing.s4,
                              ),
                              child: Text(
                                '待完善',
                                style: TextStyle(
                                  fontSize: AppText.caption,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReaderEmptyPage extends StatelessWidget {
  const _ReaderEmptyPage({required this.collection});

  final RecipeCollectionEntity collection;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(collection.name)),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_outlined, size: AppSize.icon54),
          const SizedBox(height: AppSpacing.s16),
          const Text('这个菜谱集还没有可翻阅的菜谱'),
          const SizedBox(height: AppSpacing.s16),
          FilledButton.icon(
            onPressed: () => context.pushRecipeCollection<void>(collection.id),
            icon: const Icon(Icons.playlist_add_rounded),
            label: const Text('添加菜谱'),
          ),
        ],
      ),
    ),
  );
}

class _ReaderMessagePage extends StatelessWidget {
  const _ReaderMessagePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('翻阅菜谱集')),
    body: Center(child: Text(message)),
  );
}
