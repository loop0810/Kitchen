import 'package:go_router/go_router.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';
import 'package:kitchen_home/kitchen_home.dart';
import 'package:kitchen_import/kitchen_import.dart';
import 'package:kitchen_notes/src/navigation/kitchen_notes_main_shell.dart';
import 'package:kitchen_profile/kitchen_profile.dart';
import 'package:kitchen_recipe_editor/kitchen_recipe_editor.dart';
import 'package:kitchen_recipe_library/kitchen_recipe_library.dart';

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
