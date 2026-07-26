import 'package:go_router/go_router.dart';
import 'package:kitchen_notes/src/features/home/home_page.dart';
import 'package:kitchen_notes/src/features/imports/import_inbox_page.dart';
import 'package:kitchen_notes/src/features/profile/profile_page.dart';
import 'package:kitchen_notes/src/features/recipes/create_recipe_page.dart';
import 'package:kitchen_notes/src/features/recipes/recipe_detail_page.dart';
import 'package:kitchen_notes/src/features/recipes/recipe_library_page.dart';
import 'package:kitchen_notes/src/features/search/search_page.dart';
import 'package:kitchen_notes/src/navigation/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomePage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => const RecipeLibraryPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (context, state) => const ImportInboxPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) =>
          SearchPage(initialQuery: state.uri.queryParameters['q'] ?? ''),
    ),
    GoRoute(
      path: '/recipes/new',
      builder: (context, state) => const CreateRecipePage(),
    ),
    GoRoute(
      path: '/recipes/:id',
      builder: (context, state) =>
          RecipeDetailPage(recipeId: state.pathParameters['id']!),
    ),
  ],
);
