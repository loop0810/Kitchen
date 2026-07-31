# Dart 与 Flutter 文件命名规范

新增、拆分或重命名文件时遵循本文档。文件统一使用 `snake_case`，类型使用
`UpperCamelCase`，并以职责作为后缀。

## 组件文件前缀

每个组件内的 Dart 文件必须使用该组件唯一且统一的前缀，避免不同组件在搜索、
日志、构建产物或 IDE 标签中出现难以区分的同名文件。

| 组件 | 文件前缀 |
| --- | --- |
| 根 App `kitchen_notes` | `kitchen_notes_` |
| `kitchen_app_core` | `kitchen_app_core_` |
| `kitchen_design_system` | `kitchen_design_` |
| `kitchen_home` | `kitchen_home_` |
| `kitchen_import` | `kitchen_import_` |
| `kitchen_import_domain` | `kitchen_import_domain_` |
| `kitchen_import_data` | `kitchen_import_data_` |
| `kitchen_profile` | `kitchen_profile_` |
| `kitchen_recipe_domain` | `kitchen_recipe_domain_` |
| `kitchen_recipe_data` | `kitchen_recipe_data_` |
| `kitchen_recipe_editor` | `kitchen_recipe_editor_` |
| `kitchen_recipe_library` | `kitchen_recipe_library_` |
| `kitchen_recipe_template` | `kitchen_recipe_template_` |

- 一个组件只能使用表中列出的一个前缀，禁止在同一组件中混用简称和全称。
- package 公共 barrel 使用 package 本身的名称，例如
  `kitchen_import.dart`，不重复写成 `kitchen_import_kitchen_import.dart`。
- Flutter 入口 `main.dart` 保留框架约定名称。
- `*.g.dart`、`*.freezed.dart` 等生成文件保留工具后缀；其源文件基础名仍必须
  使用组件前缀，例如 `kitchen_recipe_data_app_database.g.dart`。
- 测试文件沿用被测职责的组件前缀，例如
  `kitchen_import_import_inbox_page_test.dart`。

## UI

| 职责 | 文件 | 类型 |
| --- | --- | --- |
| 页面 | `<组件前缀>_recipe_detail_page.dart` | `RecipeDetailPage` |
| 独立 UI 子组件 | `<组件前缀>_recipe_card_widget.dart` | `RecipeCardWidget` |
| 弹窗 | `<组件前缀>_delete_recipe_dialog.dart` | `DeleteRecipeDialog` |
| Bottom Sheet | `<组件前缀>_recipe_filter_sheet.dart` | `RecipeFilterSheet` |
| 主题 | `kitchen_design_app_theme.dart` | `AppTheme` |
| 颜色常量 | `kitchen_design_app_color.dart` | `AppColor` |
| 间距常量 | `kitchen_design_app_spacing.dart` | `AppSpacing` |

- 新页面禁止使用 `screen` 后缀。
- 只有抽取到独立文件的 UI 子组件必须使用 `widget` 后缀；页面文件内的私有小
  组件不强制。

## Application 与状态管理

| 职责 | 文件 | 类型 |
| --- | --- | --- |
| 应用入口与根组件 | `kitchen_notes_app.dart` | `KitchenNotesApp` |
| 应用或导航壳 | `kitchen_notes_main_shell.dart` | `MainShell` |
| Riverpod Provider | `<组件前缀>_recipe_list_provider.dart` | `recipeListProvider` |
| Notifier / 控制器 | `<组件前缀>_recipe_editor_controller.dart` | `RecipeEditorController` |
| 状态模型 | `<组件前缀>_recipe_editor_state.dart` | `RecipeEditorState` |
| 跨流程协调器 | `<组件前缀>_import_coordinator.dart` | `ImportCoordinator` |
| 路由器 | `kitchen_notes_app_router.dart` | `AppRouter` |
| 类型化路由 | `<组件前缀>_recipe_detail_route.dart` | `RecipeDetailRoute` |

Provider 通常是变量而不是类型，变量使用 `lowerCamelCase` 并以 `Provider`
结尾。

## Domain

| 职责 | 文件 | 类型 |
| --- | --- | --- |
| 实体 | `<组件前缀>_recipe_entity.dart` | `RecipeEntity` |
| Value Object | `<组件前缀>_ingredient_amount_value_object.dart` | `IngredientAmountValueObject` |
| UseCase | `<组件前缀>_save_recipe_use_case.dart` | `SaveRecipeUseCase` |
| Repository 接口 | `<组件前缀>_recipe_repository.dart` | `RecipeRepository` |
| Domain Service | `<组件前缀>_recipe_validation_service.dart` | `RecipeValidationService` |
| Domain Event | `<组件前缀>_recipe_imported_event.dart` | `RecipeImportedEvent` |
| Failure | `<组件前缀>_import_failure.dart` | `ImportFailure` |

## Data 与外部能力

| 职责 | 文件 | 类型 |
| --- | --- | --- |
| 数据库入口 | `<组件前缀>_app_database.dart` | `AppDatabase` |
| Repository 实现 | `<组件前缀>_recipe_repository_impl.dart` | `RecipeRepositoryImpl` |
| 数据源 | `<组件前缀>_recipe_local_data_source.dart` | `RecipeLocalDataSource` |
| DTO | `<组件前缀>_recipe_dto.dart` | `RecipeDto` |
| Mapper | `<组件前缀>_recipe_mapper.dart` | `RecipeMapper` |
| Drift 表 | `<组件前缀>_recipes_table.dart` | `RecipesTable` |
| DAO | `<组件前缀>_recipe_dao.dart` | `RecipeDao` |
| 数据库迁移 | `<组件前缀>_recipe_migration.dart` | `RecipeMigration` |
| 外部适配器 | `<组件前缀>_recipe_ai_adapter.dart` | `RecipeAiAdapter` |
| 基础设施 Service | `<组件前缀>_rewarded_ad_service.dart` | `RewardedAdService` |

Repository 接口位于 Domain，具体实现必须使用 `repository_impl` 后缀并位于
Data。

## 通用规则

- 测试文件与源文件对应，并以 `_test.dart` 结尾。
- 扩展方法使用 `*_extension.dart`。
- 常量集合使用能直接表达内容的名词，例如
  `kitchen_design_app_color.dart`、`kitchen_design_app_spacing.dart` 或
  `<组件前缀>_recipe_category.dart`；不要使用语义宽泛的 `tokens`、
  `constants` 作为文件职责，也不要创建全局常量杂物文件。
- 避免 `utils.dart`、`helpers.dart`、`common.dart`、`base.dart`、
  `manager.dart` 等无法表达单一职责的名称。
- 一个文件承担多种职责时，优先拆分职责，再选择后缀。
- 现有单体结构中的混合职责文件可在组件化迁移时逐步拆分；新增文件必须立即
  遵守本规范。
- `*.g.dart`、`*.freezed.dart` 等生成文件遵循生成器命名，不手动修改。
