# Flutter 客户端依赖注入与分层架构学习笔记

这份笔记整理最近三个问题：

1. `main.dart` 的 `build` 为什么集中进行依赖注入？
2. 这种注入方式是否会让对象一直占用内存？项目变大后如何避免 `main.dart` 臃肿？
3. UseCase、Repository 和 Database 分别是什么？

## 一、`main.dart` 的 `build` 为什么负责依赖注入？

项目的 `main.dart` 是应用的“组合根”（Composition Root）。它负责把具体实现组装起来，再交给各个 Feature 使用。

```dart
@override
Widget build(BuildContext context) {
  return ProviderScope(
    overrides: [
      ...buildRecipeFeatureOverrides(...),
      profileDependenciesProvider.overrideWithValue(...),
      importDependenciesProvider.overrideWithValue(...),
    ],
    child: const KitchenNotesApp(),
  );
}
```

这里的 `ProviderScope` 可以理解为 Riverpod 的依赖容器。`overrides` 把 Feature 默认声明的 Provider 替换成应用真正使用的实现。

例如导入 Feature 只声明自己需要什么：

```dart
final importDependenciesProvider = Provider<ImportDependencies>((ref) {
  throw StateError('请在应用组合根注入 ImportDependencies。');
});
```

组合根再提供真实对象：

```dart
importDependenciesProvider.overrideWithValue(
  ImportDependencies(
    repository: _importDataModule.importTaskRepository,
    pipeline: _importPipeline,
    persistPickedImages: _importDataModule.persistPickedImages,
  ),
)
```

页面通过 Provider 使用它：

```dart
final importTasksProvider = StreamProvider<List<ImportTaskEntity>>((ref) {
  return ref.watch(importDependenciesProvider).repository.watchTasks();
});
```

完整调用链是：

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

页面只知道“如何获取导入任务”，不需要知道 Drift、SQLite 或数据库表结构。

### 为什么不在页面里创建数据库？

如果页面自己创建数据库和 Repository，会导致页面直接依赖 Data 层，带来以下问题：

- 页面知道太多数据库细节。
- 多个页面可能创建多个数据库实例。
- 数据库生命周期难以统一管理。
- 测试时难以替换为内存实现或假实现。
- 业务规则容易散落在页面中。

因此项目采用：

```text
页面
  ↓
Riverpod Provider
  ↓
Feature Dependencies
  ↓
UseCase / Repository 接口
  ↓
Data 层实现
  ↓
Drift / SQLite
```

## 二、对象会不会一直占用内存？项目变大后怎么办？

当前写法确实让数据库模块、Repository 和会话服务拥有 App 级生命周期：

```dart
_recipeDataModule = RecipeDataModule();
_importDataModule = ImportDataModule();
```

但“Repository 常驻”不等于“所有业务数据常驻”。`RecipeDataModule` 通常只持有数据库连接、Repository 实例和少量策略对象；菜谱内容仍然在页面订阅查询时从 SQLite 读取。

当前生命周期大致如下：

| 对象 | 生命周期 |
| --- | --- |
| 数据库、Repository | App 级 |
| 认证 Session Repository | App 级 |
| 页面查询结果 | Provider/页面级 |
| 菜谱详情查询 | `autoDispose` Provider 级 |
| 页面临时状态 | Widget 级 |

例如：

```dart
final recipesProvider = StreamProvider.autoDispose
    .family<List<RecipeJournalSummaryEntity>, RecipeQuery>((ref, query) {
  return ref.watch(recipeLibraryDependenciesProvider).watchRecipes(query);
});
```

页面离开后，`autoDispose` 可以取消查询订阅并释放页面级结果。

### `main.dart` 变大的问题

这个问题确实存在。集中管理生命周期的原则没有问题，但所有 Feature 的装配细节都写在 `main.dart`，项目变大后会变得臃肿。

可以把装配代码拆成模块：

```text
lib/src/composition/
├── recipe_feature_overrides.dart
├── import_feature_overrides.dart
├── profile_feature_overrides.dart
└── app_overrides.dart
```

`main.dart` 只保留总装配：

```dart
ProviderScope(
  overrides: [
    ...buildRecipeFeatureOverrides(recipeDataModule),
    ...buildImportFeatureOverrides(importDataModule, importPipeline),
    ...buildProfileFeatureOverrides(...),
  ],
  child: const KitchenNotesApp(),
)
```

这样仍然集中管理依赖，但每个 Feature 的接线逻辑可以独立阅读和测试。

未来也可以让 Riverpod 延迟创建模块：

```dart
final recipeDataModuleProvider = Provider<RecipeDataModule>((ref) {
  final module = RecipeDataModule();
  ref.onDispose(module.close);
  return module;
});
```

不过数据库模块一般不宜频繁 `autoDispose`，因为反复打开和关闭数据库连接会增加复杂度。更常见的做法是：数据库和基础 Repository App 级共享，页面查询结果使用 `autoDispose`。

## 三、UseCase、Repository 和 Database 分别是什么？

可以先这样记：

| 概念 | 作用 |
| --- | --- |
| UseCase | 一个完整的业务动作 |
| Repository | 业务层访问数据的统一入口 |
| Database | 真正保存和查询数据的地方 |
| Entity | 业务对象 |

### UseCase：业务动作

UseCase 可以理解为“用户或系统要完成的一件具体业务事情”，例如：

- 创建菜谱
- 查询菜谱
- 收藏菜谱
- 删除菜谱
- 恢复菜谱
- 导入图片

当前的 `CreateRecipeUseCase` 大致负责：

```text
创建菜谱
    1. 校验输入
    2. 判断业务状态
    3. 调用 Repository 保存
    4. 返回菜谱 ID
```

页面不需要知道校验规则和保存过程，只需要执行：

```dart
final recipeId = await createRecipe(input);
```

UseCase 的重点不是“代码一定要写成一个类”，而是把一个业务动作及其规则集中起来，避免规则散落到多个页面。

### Repository：数据访问代理

Repository 虽然常翻译为“仓储”，但它不是数据库本身。它更像业务层访问数据的“统一入口”。

Domain 层定义接口：

```dart
abstract interface class RecipeRepository {
  Stream<List<RecipeJournalSummaryEntity>> watchRecipes(RecipeQuery query);

  Future<RecipeDetailEntity?> getRecipeDetail(String recipeId);

  Future<String> createRecipe(CreateRecipeInput input);
}
```

Data 层提供实现：

```dart
class RecipeRepositoryImpl implements RecipeRepository {
  final AppDatabase _database;

  // 使用 Drift 查询并映射为 Domain Entity
}
```

因此调用链是：

```text
RecipeRepository 接口
    ↓
RecipeRepositoryImpl
    ↓
AppDatabase
    ↓
Drift
    ↓
SQLite 文件
```

Repository 还负责把数据库 Row 转换成领域对象：

```text
Drift Row
    ↓ Mapper
RecipeEntity / RecipeDetailEntity
```

这样 Domain 和 UI 不需要依赖 Drift 的数据库类型。

### UseCase 和 Repository 的边界

UseCase 关心“业务上能不能做”：

- 标题是否为空？
- 是否允许重复创建？
- 是否需要标记为 incomplete？
- 是否需要保留用户已编辑内容？

Repository 实现关心“数据具体怎么读写”：

- 使用哪张表？
- 如何 JOIN？
- 如何映射 Drift Row？
- 哪些写操作放进同一个事务？

一个简单判断方式是：

> 和数据库无关、换成内存实现后仍然成立的规则，通常属于 Domain 或 UseCase；和表、SQL、事务有关的细节，通常属于 Repository 实现或 Data 层。

## 四、创建菜谱的完整链路

```text
CreateRecipePage
    ↓ 收集输入
CreateRecipeUseCase
    ↓ 执行业务校验
RecipeRepository
    ↓ 调用抽象数据接口
RecipeRepositoryImpl
    ↓ 使用 Drift 和事务
AppDatabase
    ↓
SQLite
```

其中：

- 页面负责展示和收集输入。
- UseCase 负责业务流程。
- Repository 负责数据访问抽象。
- Repository 实现负责数据库细节。
- Database 负责最终持久化。

这套结构不是所有项目都必须采用。小项目可以直接使用 `页面 → Repository → SQLite`。当前项目有多个 Feature、本地优先存储、导入流水线、OCR、认证和未来同步能力，因此分层可以减少模块之间的直接依赖。

## 五、最简记忆方式

```text
页面：用户想做什么？
UseCase：这件事有哪些业务步骤？
Repository：需要哪些业务数据？
Database：数据具体存在哪里？
```

## 六、Domain 和 Feature 的职责区别

### 1. Domain 是什么？

Domain 可以理解为“业务领域层”。它描述厨房手记中的业务概念和业务规则，而不是 Flutter 页面或数据库实现。

例如菜谱领域中的概念包括：

- 菜谱、食材、步骤
- 菜谱集合
- 菜谱查询条件
- 菜谱模板选择
- 菜谱生命周期状态

Domain 主要回答：

```text
什么是菜谱？
菜谱有哪些属性？
什么条件下菜谱可以保存？
如何创建、更新、收藏或删除菜谱？
需要哪些 Repository 能力？
```

Domain 不应该关心：

- 页面使用 Material 还是 Cupertino。
- 数据保存于 SQLite 还是网络。
- 使用 Riverpod 还是其他状态管理框架。
- 当前运行在 Android 还是 iOS。

### 2. 项目中的 Domain 包

主要 Domain 包包括：

```text
client/packages/kitchen_recipe_domain/
client/packages/kitchen_import_domain/
client/packages/kitchen_auth_domain/
```

以 `kitchen_recipe_domain` 为例：

```text
lib/src/
├── entities/       领域实体，例如 RecipeEntity
├── inputs/         创建和更新菜谱的输入对象
├── queries/        查询条件
├── repositories/   Repository 接口
├── use_cases/      业务动作
├── services/       领域校验和规则
└── failures/       领域错误
```

Domain 中的 Repository 是接口：

```dart
abstract interface class RecipeRepository {
  Future<String> createRecipe(CreateRecipeInput input);
}
```

它只描述业务层需要什么数据能力，不决定数据如何保存。`CreateRecipeUseCase` 负责校验输入并调用这个接口；具体使用 Drift 写入 SQLite，则由 Data 层完成。

`kitchen_recipe_domain` 是纯 Dart package，原则上不依赖 Flutter、Riverpod、Drift、SQLite、平台插件或网络库。这样业务规则可以单独测试，也可以更换底层实现。

### 3. Feature 是什么？

Feature 可以理解为“用户可以直接使用的一组功能和交互流程”。项目中的 Feature 包包括：

```text
client/packages/kitchen_home/
client/packages/kitchen_recipe_library/
client/packages/kitchen_recipe_editor/
client/packages/kitchen_import/
client/packages/kitchen_profile/
```

Feature 主要回答：

```text
用户从哪里进入？
页面展示什么？
用户可以点击什么？
加载、空状态和失败如何展示？
如何调用 Domain 的业务能力？
```

Feature 通常包含：

```text
pages/       页面
widgets/     页面组件
providers/   Riverpod Provider 和 Feature 依赖声明
```

例如 `kitchen_recipe_library` 负责菜谱列表、搜索、卡片、收藏按钮、集合页面和回收站页面，但不应该直接使用：

```dart
AppDatabase
Recipes
RecipeCompanion
```

也不应该直接操作 Drift Row。

## 七、Domain 和 Feature 的对比

| 对比项 | Domain | Feature |
| --- | --- | --- |
| 核心问题 | 业务是什么、规则是什么 | 用户如何使用这个业务 |
| 主要内容 | Entity、Value Object、UseCase、Repository 接口 | Page、Widget、Provider、交互流程 |
| 是否依赖 Flutter | 不依赖 | 通常依赖 |
| 是否依赖 Riverpod | 不依赖 | 可以依赖 |
| 是否依赖 Drift | 不依赖 | 不应直接依赖 |
| 是否关心 UI | 不关心 | 负责展示和交互 |
| 是否关心数据库表 | 不关心 | 不直接关心 |
| 测试重点 | 业务规则和状态变化 | 页面行为和用户交互 |

理想调用方向是：

```text
Feature
  ↓ 调用
Domain UseCase / Repository 接口
  ↓ 由 Data 层实现
Data Repository
  ↓
Drift / SQLite
```

## 八、以“创建菜谱”为例

### Domain 负责什么？

```text
CreateRecipeInput
  ↓
校验标题、食材和步骤
  ↓
决定菜谱是 ready 还是 incomplete
  ↓
通过 RecipeRepository 保存
```

### Feature 负责什么？

```text
CreateRecipePage
  ↓
展示输入框和食材/步骤编辑器
  ↓
收集用户输入
  ↓
点击“保存”
  ↓
显示加载、成功或失败提示
  ↓
跳转到菜谱详情
```

### Data 负责什么？

```text
RecipeRepositoryImpl
  ↓
写入 recipes 表
  ↓
写入 ingredients 表
  ↓
写入 recipe_steps 表
  ↓
在同一个事务中提交
```

所以：

```text
Feature：用户如何创建菜谱？
Domain：什么样的输入才是合法菜谱？
Data：如何把菜谱保存到 SQLite？
```

## 九、为什么要把 Domain 和 Feature 分开？

### 避免业务规则散落在页面

手动创建页面和导入确认页面都可能需要保存菜谱。如果各自实现一套校验，规则很容易不一致。通过共同使用 `CreateRecipeUseCase`，两条入口可以遵守同一套业务规则：

```text
手动创建页面 ─┐
              ├── CreateRecipeUseCase
导入确认页面 ─┘
```

### 避免 Feature 之间互相依赖

导入 Feature 交付确认草稿，根 App 将它映射为 `CreateRecipeInput`，再交给菜谱领域的创建流程。导入 Feature 不需要直接访问菜谱 Feature 的内部页面代码。

### 方便替换底层实现

同一个 Domain Repository 接口未来可以有不同实现：

```text
RecipeRepositoryImpl       SQLite 实现
FakeRecipeRepository       测试实现
RemoteRecipeRepository     网络实现
SyncingRecipeRepository    本地 + 云端实现
```

Feature 不需要修改，只要注入的对象继续满足 Domain 接口即可。

最简单的记忆方式是：

```text
Domain：产品规则和业务能力
Feature：用户看到的功能和操作流程
Data：数据如何保存和读取
```
