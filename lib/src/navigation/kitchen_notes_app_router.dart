import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_home/kitchen_home.dart';
import 'package:kitchen_import/kitchen_import.dart';
import 'package:kitchen_notes/src/navigation/kitchen_notes_main_shell.dart';
import 'package:kitchen_profile/kitchen_profile.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_editor/kitchen_recipe_editor.dart';
import 'package:kitchen_recipe_library/kitchen_recipe_library.dart';
import 'package:kitchen_recipe_template/kitchen_recipe_template.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // StatefulShellRoute 为每个底部导航分支保留独立导航栈和页面状态。
    // 例如从菜谱库切到“我的”再返回时，菜谱库不会重新从根页面开始。
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: AppRouteNames.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recipes',
              name: AppRouteNames.recipes,
              builder: (context, state) => const RecipeLibraryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              name: AppRouteNames.importInbox,
              builder: (context, state) => const ImportInboxPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: AppRouteNames.profile,
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    // 搜索、创建和详情属于跨 Tab 的全局页面，因此放在 Shell 之外。
    GoRoute(
      path: '/search',
      name: AppRouteNames.search,
      builder: (context, state) =>
          SearchPage(initialQuery: state.uri.queryParameters['q'] ?? ''),
    ),
    GoRoute(
      path: '/recipes/new',
      name: AppRouteNames.createRecipe,
      builder: (context, state) => const CreateRecipePage(),
    ),
    GoRoute(
      path: '/imports/paste',
      name: AppRouteNames.pasteImport,
      builder: (context, state) => const PasteArticlePage(),
    ),
    GoRoute(
      path: '/imports/images',
      name: AppRouteNames.imageImport,
      builder: (context, state) => const ImageImportPage(),
    ),
    GoRoute(
      path: '/imports/:id',
      name: AppRouteNames.importTask,
      builder: (context, state) =>
          ImportTaskPage(taskId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/imports/:id/review',
      name: AppRouteNames.reviewImportDraft,
      builder: (context, state) =>
          _ImportDraftCoordinatorPage(taskId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/recipe-collections/:id',
      name: AppRouteNames.recipeCollection,
      builder: (context, state) =>
          RecipeCollectionDetailPage(collectionId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/recipe-collections/:id/read',
      name: AppRouteNames.recipeCollectionReader,
      builder: (context, state) =>
          RecipeCollectionReaderPage(collectionId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/recipes/trash',
      name: AppRouteNames.recipeTrash,
      builder: (context, state) => const RecipeTrashPage(),
    ),
    GoRoute(
      path: '/recipes/:id/edit',
      name: AppRouteNames.editRecipe,
      builder: (context, state) =>
          EditRecipePage(recipeId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/recipes/:id',
      name: AppRouteNames.recipeDetail,
      builder: (context, state) =>
          RecipeDetailPage(recipeId: state.pathParameters['id']!),
    ),
  ],
);

class _ImportDraftCoordinatorPage extends ConsumerWidget {
  const _ImportDraftCoordinatorPage({required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(importTaskProvider(taskId));
    return task.when(
      data: (value) {
        if (value == null) {
          return const _ImportMessagePage(message: '导入任务不存在或已删除');
        }
        if (value.finalRecipeId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.replaceWithRecipeDetail(value.finalRecipeId!);
            }
          });
          return const _ImportMessagePage(message: '正在打开已保存的菜谱…');
        }
        final draft = value.draft;
        if (draft == null) {
          return const _ImportMessagePage(message: '草稿尚未准备好，请返回导入箱稍后重试');
        }
        // 映射留在组合根：Import Feature 不直接依赖 Recipe Feature，
        // 两个领域只通过根 App 的协调页面发生转换。
        final initialInput = CreateRecipeInput(
          title: draft.title.value,
          summary: draft.summary.value,
          category: draft.category.value,
          ingredients: draft.ingredients.value,
          steps: draft.steps.value,
          templateSelection: BuiltInTemplates.defaultSelection,
          servings: draft.servings.value,
          prepMinutes: draft.prepMinutes.value,
          cookMinutes: draft.cookMinutes.value,
          difficulty: draft.difficulty.value,
          tags: draft.tags.value,
          sourceSnapshot: RecipeSourceSnapshot(
            originalText: draft.sourceSnapshot.originalText,
            publicUrl: draft.sourceSnapshot.publicUrl,
            sourceTitle: draft.sourceSnapshot.sourceTitle,
          ),
          importTaskId: taskId,
        );
        return CreateRecipePage(
          initialInput: initialInput,
          onCreated: (recipeId) => ref
              .read(importDependenciesProvider)
              .repository
              .markSaved(taskId: taskId, recipeId: recipeId),
        );
      },
      error: (_, _) => const _ImportMessagePage(message: '草稿加载失败，请稍后重试'),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _ImportMessagePage extends StatelessWidget {
  const _ImportMessagePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('确认导入草稿')),
      body: Center(child: Text(message)),
    );
  }
}
