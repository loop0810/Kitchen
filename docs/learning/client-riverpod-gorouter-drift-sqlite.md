# Riverpod、GoRouter、Drift/SQLite 学习笔记

本文基于厨房手记客户端的实际代码，分别说明三个框架的基础用法、项目职责、核心入口、调用链，以及它们如何协作。

## 一、Riverpod：状态管理与依赖注入

### 基础用法

Riverpod 主要解决两类问题：

- 管理状态，例如菜谱列表、加载状态和错误状态。
- 管理依赖，例如 Repository、UseCase 和服务对象。

最简单的 Provider：

```dart
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
```

Widget 中使用：

```dart
class ExamplePage extends ConsumerWidget {
  const ExamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(apiClientProvider);
    return Text(client.name);
  }
}
```

`watch` 表示读取并订阅变化；`read` 表示读取但不订阅变化：

```dart
final value = ref.watch(provider); // 变化时重建当前 Widget
final value = ref.read(provider);  // 只读取一次
```

异步查询可以使用 `FutureProvider` 或 `StreamProvider`：

```dart
final detailProvider = FutureProvider<RecipeEntity?>((ref) async {
  return ref.watch(recipeRepositoryProvider).getRecipeDetail('id');
});
```

页面通过 `AsyncValue` 处理加载、错误和成功：

```dart
final value = ref.watch(detailProvider);

return value.when(
  loading: () => const CircularProgressIndicator(),
  error: (error, stackTrace) => Text('加载失败'),
  data: (recipe) => Text(recipe?.title ?? '不存在'),
);
```

`family` 让 Provider 接收参数：

```dart
final detailProvider = FutureProvider.autoDispose
    .family<RecipeEntity?, String>((ref, recipeId) {
  return ref.watch(recipeRepositoryProvider).getRecipeDetail(recipeId);
});

ref.watch(detailProvider('recipe-1'));
```

`autoDispose` 表示没有页面使用时可以释放查询状态和订阅，适合页面级数据；数据库连接等 App 级对象通常不应频繁销毁。

应用根部需要提供 `ProviderScope`：

```dart
ProviderScope(
  overrides: [
    someProvider.overrideWithValue(realImplementation),
  ],
  child: const MyApp(),
)
```

### 在本项目中的职责

Riverpod 在项目中负责：

- 从根 App 向 Feature 注入 UseCase、Repository 和服务。
- 将数据库 Stream 转换为页面可观察的状态。
- 处理异步加载、错误和自动刷新。
- 让测试可以替换真实数据库和服务。
- 使用 `autoDispose` 管理页面查询的生命周期。

核心入口：

```text
client/lib/main.dart
client/packages/kitchen_recipe_library/lib/src/recipe_library/providers/
client/packages/kitchen_recipe_editor/lib/src/recipe_form/providers/
client/packages/kitchen_import/lib/src/shared/providers/
client/packages/kitchen_profile/lib/src/profile/providers/
```

根 App 中集中注入：

```dart
return ProviderScope(
  overrides: [
    ...buildRecipeFeatureOverrides(...),
    profileDependenciesProvider.overrideWithValue(...),
    importDependenciesProvider.overrideWithValue(...),
  ],
  child: const KitchenNotesApp(),
);
```

Feature 先声明自己需要的能力，默认实现故意抛错：

```dart
final importDependenciesProvider = Provider<ImportDependencies>((ref) {
  throw StateError('请在应用组合根注入 ImportDependencies。');
});
```

然后由 `main.dart` 提供真实值：

```dart
importDependenciesProvider.overrideWithValue(
  ImportDependencies(
    repository: _importDataModule.importTaskRepository,
    pipeline: _importPipeline,
    persistPickedImages: _importDataModule.persistPickedImages,
  ),
)
```

导入箱的调用链是：

```text
ImportInboxPage
  ↓
importTasksProvider
  ↓
importDependenciesProvider
  ↓
ImportTaskRepository
  ↓
ImportTaskRepositoryImpl
  ↓
ImportAppDatabase
  ↓
SQLite
```

菜谱列表类似：

```text
main.dart
  ↓ 注入 RecipeLibraryDependencies
recipeLibraryDependenciesProvider
  ↓
recipesProvider
  ↓
RecipeLibraryPage
```

测试时可以通过 `overrideWithValue` 注入假 UseCase，避免打开真实数据库。

## 二、GoRouter：声明式路由

### 基础用法

GoRouter 用来管理 URL、页面、路径参数、查询参数和嵌套路由。

基础配置：

```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfilePage(),
    ),
  ],
);
```

接入应用：

```dart
MaterialApp.router(
  routerConfig: router,
)
```

导航操作：

```dart
context.go('/profile');       // 切换到目标位置
context.push('/recipes/abc'); // 压入一个新页面
context.pop();                // 返回
```

路径参数：

```dart
GoRoute(
  path: '/recipes/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return RecipeDetailPage(recipeId: id);
  },
)
```

查询参数：

```dart
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'] ?? '';
    return SearchPage(initialQuery: query);
  },
)
```

地址 `/search?q=鸡肉` 中的 `鸡肉` 就会通过 `queryParameters['q']` 读取。

`StatefulShellRoute.indexedStack` 适合底部 Tab。它为每个分支保留独立导航栈，使用户从菜谱详情切到“我的”再回来时，菜谱库仍保留原来的位置。

### 在本项目中的职责

核心入口：

```text
client/lib/src/kitchen_notes_app.dart
client/lib/src/navigation/kitchen_notes_app_router.dart
client/lib/src/navigation/kitchen_notes_main_shell.dart
```

应用接入：

```dart
return MaterialApp.router(
  title: '厨房手记',
  theme: AppTheme.forStyle(visualStyle),
  routerConfig: appRouter,
);
```

当前路由结构：

```text
StatefulShellRoute.indexedStack
  ├── /          首页
  ├── /recipes   菜谱库
  ├── /inbox     导入箱
  └── /profile   我的

/search              搜索
/recipes/new         创建菜谱
/imports/paste       粘贴导入
/imports/images      图片导入
/imports/:id         导入任务
/imports/:id/review  导入草稿审核
/recipes/:id         菜谱详情
/recipes/:id/edit    菜谱编辑
```

底部 Tab 放在 Stateful Shell 内；搜索、创建、详情和编辑等跨 Tab 页面放在 Shell 外。

路由页面也可以是 `ConsumerWidget`。例如导入草稿协调页会同时读取任务和个人配置：

```dart
final task = ref.watch(importTaskProvider(taskId));
final personalConfig = ref.watch(personalRecipeConfigProvider);
```

然后根据任务状态显示审核页、错误页或跳转到已保存的菜谱详情。

## 三、Drift/SQLite：本地持久化

### 基础概念

SQLite 是设备上的嵌入式关系型数据库，负责真正保存数据；Drift 是 Dart/Flutter 访问 SQLite 的类型安全工具。

```text
SQLite：数据库引擎和本地文件
Drift：Dart 代码与 SQLite 之间的类型安全接口
```

Drift 提供：

- Dart 表声明。
- 类型安全查询。
- Stream 监听查询结果。
- 事务。
- 数据库迁移。
- 生成数据库访问代码。

声明表：

```dart
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  BoolColumn get isFavorite => boolean().withDefault(
    const Constant(false),
  )();
}
```

查询：

```dart
final recipe = await (select(recipes)
      ..where((row) => row.id.equals(recipeId)))
    .getSingleOrNull();
```

持续监听：

```dart
Stream<List<Recipe>> watchRecipes() {
  return select(recipes).watch();
}
```

调用 `watch()` 后，查询依赖的表发生变化时，Drift 会重新发出查询结果。

多表写入使用事务：

```dart
await transaction(() async {
  await insertRecipe();
  await insertIngredients();
  await insertSteps();
});
```

其中一步失败时全部回滚，避免数据库出现半份菜谱。

迁移通过版本号控制：

```dart
@override
int get schemaVersion => 8;
```

升级时按版本逐段执行：

```dart
if (from < 2) {
  // 添加 v2 结构
}
if (from < 3) {
  // 添加 v3 结构
}
```

### 在本项目中的职责

菜谱数据库入口：

```text
client/packages/kitchen_recipe_data/lib/kitchen_recipe_data.dart
client/packages/kitchen_recipe_data/lib/src/database/kitchen_recipe_data_app_database.dart
```

导入任务使用独立数据库：

```text
client/packages/kitchen_import_data/lib/src/import_task/database/
```

菜谱库中的主要表：

```text
Recipes
Ingredients
RecipeSteps
RecipeTags
RecipeCollections
RecipeCollectionMembers
RecipeLibrarySettings
PersonalRecipeConfigCache
```

`RecipeDataModule` 是 Data package 的装配入口。它创建 `AppDatabase` 和各种 Repository，但对外主要暴露 Domain 层接口：

```text
RecipeDataModule
  ↓
RecipeRepositoryImpl / CollectionRepositoryImpl / DeletionRepositoryImpl
  ↓
AppDatabase
  ↓
Drift
  ↓
SQLite
```

Repository 负责把 Domain 查询转换为 Drift 查询，并把 Drift Row 映射成 Domain Entity；UI 和 Domain 不直接接触数据库表类型。

数据库还负责：

- 多表事务。
- 查询 Stream。
- 数据库迁移。
- 外键和级联删除。
- 本地数据清除、导出和恢复。

## 四、三个框架如何协作？

三个框架职责不同：

| 框架 | 负责的问题 |
| --- | --- |
| GoRouter | 用户现在在哪个页面、要跳转到哪个页面 |
| Riverpod | 页面需要哪些状态和业务依赖 |
| Drift/SQLite | 数据如何查询、写入和持久化 |

它们组成的通用链路是：

```text
GoRouter 决定打开哪个页面
  ↓
页面通过 Riverpod 获取状态和业务能力
  ↓
UseCase 调用 Repository
  ↓
Repository 通过 Drift 查询 SQLite
  ↓
Drift Stream 发出新结果
  ↓
Riverpod 更新状态
  ↓
页面自动重建
```

### 示例：打开菜谱库

```text
用户点击底部“菜谱库”
  ↓
GoRouter 匹配 /recipes
  ↓
创建 RecipeLibraryPage
  ↓
ref.watch(recipesProvider(query))
  ↓
WatchRecipesUseCase
  ↓
RecipeRepositoryImpl
  ↓
AppDatabase.watchRecipeSummaries()
  ↓
Drift statement.watch()
  ↓
SQLite
  ↓
RecipeJournalSummaryEntity
  ↓
Riverpod StreamProvider
  ↓
RecipeLibraryPage 重建
```

### 示例：收藏菜谱

```text
RecipeLibraryPage
  ↓ ref.read
SetFavoriteUseCase
  ↓
RecipeRepositoryImpl.setFavorite
  ↓
Drift update
  ↓
SQLite 修改 is_favorite
  ↓
recipesProvider 的 Stream 发出新结果
  ↓
页面自动刷新
```

### 示例：打开详情页

```text
点击菜谱卡片
  ↓
GoRouter: /recipes/:id
  ↓
RecipeDetailPage(recipeId: id)
  ↓
ref.watch(recipeDetailProvider(id))
  ↓
GetRecipeDetailUseCase
  ↓
RecipeRepositoryImpl.getRecipeDetail
  ↓
Drift 查询菜谱、食材、步骤和标签
  ↓
RecipeDetailEntity
  ↓
页面展示
```

## 五、推荐阅读顺序

### Riverpod

```text
client/lib/main.dart
  ↓
Feature 的 dependencies.dart
  ↓
Feature 的具体 Provider
  ↓
页面中的 ref.watch/ref.read
```

### GoRouter

```text
client/lib/src/kitchen_notes_app.dart
  ↓
client/lib/src/navigation/kitchen_notes_app_router.dart
  ↓
client/lib/src/navigation/kitchen_notes_main_shell.dart
  ↓
页面中的 context.go/context.push
```

### Drift/SQLite

```text
client/packages/kitchen_recipe_data/lib/kitchen_recipe_data.dart
  ↓
src/database/kitchen_recipe_data_app_database.dart
  ↓
src/recipe/repositories/
  ↓
src/recipe/mappers/
  ↓
Domain Entity
```

最后可以这样记忆：

```text
GoRouter：决定页面位置
Riverpod：连接页面与状态/依赖
Drift/SQLite：负责本地数据查询和持久化
```

