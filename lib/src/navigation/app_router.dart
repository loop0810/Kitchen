import 'package:go_router/go_router.dart';
import 'package:kitchen_notes/src/features/home/home_screen.dart';
import 'package:kitchen_notes/src/features/imports/import_inbox_screen.dart';
import 'package:kitchen_notes/src/features/profile/profile_screen.dart';
import 'package:kitchen_notes/src/features/recipes/create_recipe_screen.dart';
import 'package:kitchen_notes/src/features/recipes/recipe_detail_screen.dart';
import 'package:kitchen_notes/src/features/recipes/recipe_library_screen.dart';
import 'package:kitchen_notes/src/features/search/search_screen.dart';
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
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => const RecipeLibraryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/inbox',
              builder: (context, state) => const ImportInboxScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) =>
          SearchScreen(initialQuery: state.uri.queryParameters['q'] ?? ''),
    ),
    GoRoute(
      path: '/recipes/new',
      builder: (context, state) => const CreateRecipeScreen(),
    ),
    GoRoute(
      path: '/recipes/:id',
      builder: (context, state) =>
          RecipeDetailScreen(recipeId: state.pathParameters['id']!),
    ),
  ],
);
