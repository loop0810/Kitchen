import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kitchen_recipe_domain/kitchen_recipe_domain.dart';
import 'package:kitchen_recipe_editor/kitchen_recipe_editor.dart';
import 'package:kitchen_recipe_template/kitchen_recipe_template.dart';

void main() {
  testWidgets('缺少菜名时阻止保存', (tester) async {
    final repository = _EditorRepository();
    await tester.pumpWidget(_testApp(repository));

    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(
      find.descendant(of: find.byType(SnackBar), matching: find.text('请输入菜名')),
      findsOneWidget,
    );
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 1200));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(TextFormField).at(0),
        matching: find.text('请输入菜名'),
      ),
      findsOneWidget,
    );
    expect(repository.createdInput, isNull);
  });

  testWidgets('菜名超过数据库长度限制时展示字段错误', (tester) async {
    final repository = _EditorRepository();
    await tester.pumpWidget(_testApp(repository));

    await tester.enterText(
      find.byType(TextFormField).first,
      List.filled(121, '菜').join(),
    );
    await tester.tap(find.text('保存'));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text('菜名不能超过 120 个字符'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(TextFormField).at(0),
        matching: find.text('菜名不能超过 120 个字符'),
      ),
      findsOneWidget,
    );
    expect(repository.createdInput, isNull);
  });

  testWidgets('手账预览明确说明缩略图最多展示四项食材', (tester) async {
    await tester.pumpWidget(_testApp(_EditorRepository()));

    await tester.scrollUntilVisible(
      find.text('缩略图最多展示前 4 项食材，完整食材会保留在详情中'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('缩略图最多展示前 4 项食材，完整食材会保留在详情中'), findsOneWidget);
  });

  testWidgets('表单已修改后继续编辑食材仍会实时刷新手账预览', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_testApp(_EditorRepository()));

    final ingredientsField = find.byType(TextFormField).at(2);
    await tester.enterText(ingredientsField, '番茄  2 个');
    await tester.pump();
    expect(
      tester
          .widget<RecipeTemplateRendererWidget>(
            find.byType(RecipeTemplateRendererWidget),
          )
          .data
          .primaryIngredients
          .single
          .name,
      '番茄',
    );

    await tester.enterText(ingredientsField, '鸡蛋  3 个');
    await tester.pump();
    expect(
      tester
          .widget<RecipeTemplateRendererWidget>(
            find.byType(RecipeTemplateRendererWidget),
          )
          .data
          .primaryIngredients
          .single
          .name,
      '鸡蛋',
    );

    await tester.enterText(ingredientsField, '  3 个');
    await tester.pump();
    expect(
      tester
          .widget<RecipeTemplateRendererWidget>(
            find.byType(RecipeTemplateRendererWidget),
          )
          .data
          .primaryIngredients,
      isEmpty,
    );
    expect(find.text('食材待补充'), findsOneWidget);
  });

  testWidgets('保存成功后进入新菜谱详情', (tester) async {
    final repository = _EditorRepository();
    await tester.pumpWidget(_testApp(repository));

    await tester.enterText(find.byType(TextFormField).first, '测试菜谱');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repository.createdInput?.title, '测试菜谱');
    expect(repository.createdInput?.ingredients, isEmpty);
    expect(repository.createdInput?.steps, isEmpty);
    expect(
      repository.createdInput?.templateSelection.templateId,
      'builtin.journal.basic',
    );
    expect(find.text('详情 recipe-created'), findsOneWidget);
  });

  testWidgets('从来源页创建成功后详情保留返回按钮和 iOS 滑动返回栈', (tester) async {
    final repository = _EditorRepository();
    await tester.pumpWidget(_navigationTestApp(repository));

    await tester.tap(find.text('打开创建页'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '可返回菜谱');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(5, 300));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(650, 0));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('来源页'), findsOneWidget);
  });

  testWidgets('保存失败时展示明确反馈并保留编辑页', (tester) async {
    final repository = _EditorRepository(shouldFail: true);
    await tester.pumpWidget(_testApp(repository));

    await tester.enterText(find.byType(TextFormField).first, '测试菜谱');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(find.text('保存失败，请稍后重试'), findsOneWidget);
    expect(find.text('创建菜谱'), findsOneWidget);
  });

  testWidgets('新建菜谱分类读取统一个性化配置缓存', (tester) async {
    final repository = _EditorRepository();
    final configRepository = _ConfigRepository(
      PersonalRecipeConfigEntity.defaults.copyWith(
        categories: const ['低脂餐', '节日菜'],
      ),
    );
    await tester.pumpWidget(_testApp(repository, configRepository));
    await tester.pumpAndSettle();

    expect(find.text('低脂餐'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '缓存分类菜谱');
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repository.createdInput?.category, '低脂餐');
  });
}

Widget _testApp(
  _EditorRepository repository, [
  PersonalRecipeConfigRepository? configRepository,
]) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const CreateRecipePage()),
      GoRoute(
        path: '/recipes/:id',
        name: 'recipeDetail',
        builder: (context, state) => Scaffold(
          appBar: AppBar(),
          body: Text('详情 ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      recipeEditorDependenciesProvider.overrideWithValue(
        RecipeEditorDependencies(
          createRecipe: CreateRecipeUseCase(repository),
          getRecipeDetail: GetRecipeDetailUseCase(repository),
          updateRecipe: UpdateRecipeUseCase(repository),
          personalRecipeConfigRepository: configRepository,
        ),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

class _ConfigRepository implements PersonalRecipeConfigRepository {
  _ConfigRepository(this.config);

  PersonalRecipeConfigEntity config;

  @override
  Future<PersonalRecipeConfigEntity> getCached() async => config;

  @override
  Future<void> save(PersonalRecipeConfigEntity config) async {
    this.config = config;
  }

  @override
  Future<void> synchronize() async {}

  @override
  Stream<PersonalRecipeConfigEntity> watchCached() => Stream.value(config);
}

Widget _navigationTestApp(_EditorRepository repository) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                const Text('来源页'),
                FilledButton(
                  onPressed: () => context.push('/recipes/new'),
                  child: const Text('打开创建页'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/recipes/new',
        builder: (context, state) => const CreateRecipePage(),
      ),
      GoRoute(
        path: '/recipes/:id',
        name: 'recipeDetail',
        builder: (context, state) => Scaffold(
          appBar: AppBar(),
          body: Text('详情 ${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      recipeEditorDependenciesProvider.overrideWithValue(
        RecipeEditorDependencies(
          createRecipe: CreateRecipeUseCase(repository),
          getRecipeDetail: GetRecipeDetailUseCase(repository),
          updateRecipe: UpdateRecipeUseCase(repository),
        ),
      ),
    ],
    child: MaterialApp.router(
      theme: ThemeData(platform: TargetPlatform.iOS),
      routerConfig: router,
    ),
  );
}

class _EditorRepository implements RecipeRepository {
  _EditorRepository({this.shouldFail = false});

  final bool shouldFail;
  CreateRecipeInput? createdInput;

  @override
  Future<String> createRecipe(CreateRecipeInput input) async {
    createdInput = input;
    if (shouldFail) throw StateError('failed');
    return 'recipe-created';
  }

  @override
  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId) async => null;

  @override
  Future<void> setFavorite({
    required String recipeId,
    required bool isFavorite,
  }) async {}

  @override
  Future<void> updateRecipe(UpdateRecipeInput input) async {}

  @override
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query) {
    return Stream.value(const []);
  }
}
