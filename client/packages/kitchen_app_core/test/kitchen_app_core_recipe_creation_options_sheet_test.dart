import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_app_core/kitchen_app_core.dart';

void main() {
  testWidgets('面板同时展示手动、粘贴和图片三种创建方式', (tester) async {
    await _pumpSheetHost(tester);

    expect(find.text('创建菜谱'), findsOneWidget);
    expect(find.text('手动创建'), findsOneWidget);
    expect(find.text('粘贴文章或链接'), findsOneWidget);
    expect(find.text('选择图片'), findsOneWidget);
  });

  testWidgets('选择手动创建后进入创建菜谱路由', (tester) async {
    await _pumpSheetHost(tester);

    await tester.tap(find.text('手动创建'));
    await tester.pumpAndSettle();

    expect(find.text('/recipes/new'), findsOneWidget);
  });

  testWidgets('选择粘贴文章后进入粘贴导入路由', (tester) async {
    await _pumpSheetHost(tester);

    await tester.tap(find.text('粘贴文章或链接'));
    await tester.pumpAndSettle();

    expect(find.text('/imports/paste'), findsOneWidget);
  });

  testWidgets('选择图片后进入图片导入路由', (tester) async {
    await _pumpSheetHost(tester);

    await tester.tap(find.text('选择图片'));
    await tester.pumpAndSettle();

    expect(find.text('/imports/images'), findsOneWidget);
  });

  testWidgets('关闭面板不触发任何导航', (tester) async {
    await _pumpSheetHost(tester);

    Navigator.of(tester.element(find.text('创建菜谱'))).pop();
    await tester.pumpAndSettle();

    expect(find.text('创建菜谱'), findsNothing);
    expect(find.text('打开创建方式'), findsOneWidget);
    expect(find.byType(_DestinationPage), findsNothing);
  });

  testWidgets('系统大字体下三个选项仍可滚动访问', (tester) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pumpSheetHost(tester, textScaleFactor: 2);

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.scrollUntilVisible(find.text('选择图片'), 100);
    expect(find.text('选择图片'), findsOneWidget);
  });
}

Future<void> _pumpSheetHost(
  WidgetTester tester, {
  double textScaleFactor = 1,
}) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: AppRouteNames.home,
        builder: (context, state) => const _SheetHostPage(),
      ),
      GoRoute(
        path: '/recipes/new',
        name: AppRouteNames.createRecipe,
        builder: (context, state) =>
            _DestinationPage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/imports/paste',
        name: AppRouteNames.pasteImport,
        builder: (context, state) =>
            _DestinationPage(location: state.uri.toString()),
      ),
      GoRoute(
        path: '/imports/images',
        name: AppRouteNames.imageImport,
        builder: (context, state) =>
            _DestinationPage(location: state.uri.toString()),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: textScaleFactor,
        maxScaleFactor: textScaleFactor,
        child: child!,
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('打开创建方式'));
  await tester.pumpAndSettle();
}

class _SheetHostPage extends StatelessWidget {
  const _SheetHostPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => showRecipeCreationOptions(context),
          child: const Text('打开创建方式'),
        ),
      ),
    );
  }
}

class _DestinationPage extends StatelessWidget {
  const _DestinationPage({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(location)));
  }
}
