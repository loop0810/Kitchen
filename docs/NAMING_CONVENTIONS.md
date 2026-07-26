# Dart 与 Flutter 文件命名规范

新增、拆分或重命名文件时遵循本文档。文件统一使用 `snake_case`，类型使用
`UpperCamelCase`，并以职责作为后缀。

## UI

| 职责 | 文件 | 类型 |
| --- | --- | --- |
| 页面 | `recipe_detail_page.dart` | `RecipeDetailPage` |
| 独立 UI 子组件 | `recipe_card_widget.dart` | `RecipeCardWidget` |
| 弹窗 | `delete_recipe_dialog.dart` | `DeleteRecipeDialog` |
| Bottom Sheet | `recipe_filter_sheet.dart` | `RecipeFilterSheet` |
| 主题 | `app_theme.dart` | `AppTheme` |
| Design Token | `app_color_tokens.dart` | `AppColorTokens` |

- 新页面禁止使用 `screen` 后缀。
- 只有抽取到独立文件的 UI 子组件必须使用 `widget` 后缀；页面文件内的私有小
  组件不强制。

## Application 与状态管理

| 职责 | 文件 | 类型 |
| --- | --- | --- |
| 应用入口与根组件 | `app.dart` | `KitchenNotesApp` |
| 应用或导航壳 | `main_shell.dart` | `MainShell` |
| Riverpod Provider | `recipe_list_provider.dart` | `recipeListProvider` |
| Notifier / 控制器 | `recipe_editor_controller.dart` | `RecipeEditorController` |
| 状态模型 | `recipe_editor_state.dart` | `RecipeEditorState` |
| 跨流程协调器 | `import_coordinator.dart` | `ImportCoordinator` |
| 路由器 | `app_router.dart` | `AppRouter` |
| 类型化路由 | `recipe_detail_route.dart` | `RecipeDetailRoute` |

Provider 通常是变量而不是类型，变量使用 `lowerCamelCase` 并以 `Provider`
结尾。

## Domain

| 职责 | 文件 | 类型 |
| --- | --- | --- |
| 实体 | `recipe_entity.dart` | `RecipeEntity` |
| Value Object | `ingredient_amount_value_object.dart` | `IngredientAmountValueObject` |
| UseCase | `save_recipe_use_case.dart` | `SaveRecipeUseCase` |
| Repository 接口 | `recipe_repository.dart` | `RecipeRepository` |
| Domain Service | `recipe_validation_service.dart` | `RecipeValidationService` |
| Domain Event | `recipe_imported_event.dart` | `RecipeImportedEvent` |
| Failure | `import_failure.dart` | `ImportFailure` |

## Data 与外部能力

| 职责 | 文件 | 类型 |
| --- | --- | --- |
| 数据库入口 | `app_database.dart` | `AppDatabase` |
| Repository 实现 | `recipe_repository_impl.dart` | `RecipeRepositoryImpl` |
| 数据源 | `recipe_local_data_source.dart` | `RecipeLocalDataSource` |
| DTO | `recipe_dto.dart` | `RecipeDto` |
| Mapper | `recipe_mapper.dart` | `RecipeMapper` |
| Drift 表 | `recipes_table.dart` | `RecipesTable` |
| DAO | `recipe_dao.dart` | `RecipeDao` |
| 数据库迁移 | `recipe_migration.dart` | `RecipeMigration` |
| 外部适配器 | `recipe_ai_adapter.dart` | `RecipeAiAdapter` |
| 基础设施 Service | `rewarded_ad_service.dart` | `RewardedAdService` |

Repository 接口位于 Domain，具体实现必须使用 `repository_impl` 后缀并位于
Data。

## 通用规则

- 测试文件与源文件对应，并以 `_test.dart` 结尾。
- 扩展方法使用 `*_extension.dart`。
- 常量集合使用描述具体领域的 `*_constants.dart`，不要创建全局
  `constants.dart`。
- 避免 `utils.dart`、`helpers.dart`、`common.dart`、`base.dart`、
  `manager.dart` 等无法表达单一职责的名称。
- 一个文件承担多种职责时，优先拆分职责，再选择后缀。
- 现有单体结构中的混合职责文件可在组件化迁移时逐步拆分；新增文件必须立即
  遵守本规范。
- `*.g.dart`、`*.freezed.dart` 等生成文件遵循生成器命名，不手动修改。
