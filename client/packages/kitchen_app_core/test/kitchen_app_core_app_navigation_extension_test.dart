import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';

void main() {
  testWidgets('goToRecipes 与 goToImportInbox 切换到对应主分支', (tester) async {
    final router = await _pumpRouter(tester);

    _context(tester).goToRecipes();
    await tester.pumpAndSettle();
    expect(_location(router), '/recipes');

    _context(tester).goToImportInbox();
    await tester.pumpAndSettle();
    expect(_location(router), '/inbox');
  });

  testWidgets('pushSearch 把关键词编码为查询参数', (tester) async {
    await _pumpRouter(tester);

    _context(tester).pushSearch<void>('番茄 鸡蛋');
    await tester.pumpAndSettle();

    final location = Uri.parse(_topLocation(tester));
    expect(location.path, '/search');
    expect(location.queryParameters['q'], '番茄 鸡蛋');
  });

  testWidgets('push 系列扩展进入对应命名路由并保留返回栈', (tester) async {
    await _pumpRouter(tester);

    final cases = <String, void Function(BuildContext context)>{
      '/recipes/new': (context) => context.pushCreateRecipe<void>(),
      '/recipes/trash': (context) => context.pushRecipeTrash<void>(),
      '/imports/task-1': (context) => context.pushImportTask<void>('task-1'),
      '/imports/task-1/review': (context) =>
          context.pushReviewImportDraft<void>('task-1'),
      '/recipes/recipe-1': (context) =>
          context.pushRecipeDetail<void>('recipe-1'),
      '/recipes/recipe-1/edit': (context) =>
          context.pushEditRecipe<void>('recipe-1'),
      '/recipe-collections/collection-1': (context) =>
          context.pushRecipeCollection<void>('collection-1'),
      '/recipe-collections/collection-1/read': (context) =>
          context.pushRecipeCollectionReader<void>('collection-1'),
    };

    for (final entry in cases.entries) {
      entry.value(_context(tester));
      await tester.pumpAndSettle();
      expect(_topLocation(tester), entry.key);

      _context(tester).pop();
      await tester.pumpAndSettle();
      expect(_topLocation(tester), '/');
    }
  });

  testWidgets('replaceWith 系列扩展替换当前页面而不增加返回栈', (tester) async {
    await _pumpRouter(tester);

    _context(tester).pushCreateRecipe<void>();
    await tester.pumpAndSettle();
    _context(tester).replaceWithRecipeDetail('recipe-1');
    await tester.pumpAndSettle();

    expect(_topLocation(tester), '/recipes/recipe-1');
    _context(tester).pop();
    await tester.pumpAndSettle();
    expect(_topLocation(tester), '/');
  });

  testWidgets('replaceWithImportTask 替换当前页面为导入任务', (tester) async {
    await _pumpRouter(tester);

    _context(tester).pushCreateRecipe<void>();
    await tester.pumpAndSettle();
    _context(tester).replaceWithImportTask('task-1');
    await tester.pumpAndSettle();

    expect(_topLocation(tester), '/imports/task-1');
  });

  testWidgets('showRecipeCreationOptions 从扩展打开创建方式面板', (tester) async {
    await _pumpRouter(tester);

    _context(tester).showRecipeCreationOptions();
    await tester.pumpAndSettle();

    expect(find.text('创建菜谱'), findsOneWidget);
  });
}

/// 用最小页面复刻根 App 的命名路由表，只验证扩展生成的目标位置。
Future<GoRouter> _pumpRouter(WidgetTester tester) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: AppRouteNames.home,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/recipes',
        name: AppRouteNames.recipes,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/inbox',
        name: AppRouteNames.importInbox,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/search',
        name: AppRouteNames.search,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/recipes/new',
        name: AppRouteNames.createRecipe,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/recipes/trash',
        name: AppRouteNames.recipeTrash,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/imports/paste',
        name: AppRouteNames.pasteImport,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/imports/images',
        name: AppRouteNames.imageImport,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/imports/:id',
        name: AppRouteNames.importTask,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/imports/:id/review',
        name: AppRouteNames.reviewImportDraft,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/recipe-collections/:id',
        name: AppRouteNames.recipeCollection,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/recipe-collections/:id/read',
        name: AppRouteNames.recipeCollectionReader,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/recipes/:id/edit',
        name: AppRouteNames.editRecipe,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/recipes/:id',
        name: AppRouteNames.recipeDetail,
        builder: (context, state) => _ProbePage(location: state.uri.toString()),
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
  return router;
}

BuildContext _context(WidgetTester tester) {
  return tester.element(find.byType(_ProbePage).last);
}

/// 命名路由 push 后 GoRouter 的 currentConfiguration 仍指向基础位置，
/// 因此断言目标页面实际收到的匹配位置。
String _topLocation(WidgetTester tester) {
  return tester.widgetList<_ProbePage>(find.byType(_ProbePage)).last.location;
}

String _location(GoRouter router) {
  return router.routerDelegate.currentConfiguration.uri.toString();
}

class _ProbePage extends StatelessWidget {
  const _ProbePage({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(location)));
  }
}
