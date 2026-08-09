# 厨房手记

一个使用 Flutter 开发的本地优先菜谱应用。当前 V1 先面向 Android，目标是在无网络、无需
登录的情况下完成菜谱导入、整理、保存、搜索和查阅；iOS 与账号/云端能力在稳定后再恢复。

V1 核心能力：

- 极简首页搜索
- 一套稳定免费模板与基础极简视觉
- 本地 SQLite 菜谱存储
- 菜谱库、收藏/完整度筛选与本地搜索
- 手动创建菜谱
- 统一创建入口与持久化导入任务
- 文章 / 公开 HTTPS 链接本地整理
- Android 相册多选、失败恢复与离线 OCR
- OCR 草稿逐字段审核与确认
- 本地分类、标签与难度使用
- 食材分组、步骤与菜谱详情
- 导入箱；云端 AI、登录、备份和 iOS Share Extension 暂不属于 V1 发布前置条件

## 项目文档

- [Monorepo 文档导航](../docs/README.md)
- [产品需求总纲](../docs/product/PRODUCT_REQUIREMENTS.md)
- [MVP 需求文档](../docs/product/MVP_REQUIREMENTS.md)
- [菜谱功能需求文档](../docs/product/RECIPE_REQUIREMENTS.md)
- [Figma 视觉设计 Brief](../docs/client/design/FIGMA_DESIGN_BRIEF.md)
- [客户端基础服务目录](../docs/client/services/README.md)
- [产品与架构决策记录](../docs/decisions/DECISION_LOG.md)
- [Codex CLI 与 VS Code 学习工作流](../docs/client/workflow/CODEX_WORKFLOW.md)
- [Codex 项目通用约束](AGENTS.md)
- [Package 通用约束](packages/AGENTS.md)
- [Recipe Data 专项约束](packages/kitchen_recipe_data/AGENTS.md)
- [Recipe Domain 专项约束](packages/kitchen_recipe_domain/AGENTS.md)
- [Design System 专项约束](packages/kitchen_design_system/AGENTS.md)
- [Dart 与 Flutter 命名规范](../docs/client/engineering/NAMING_CONVENTIONS.md)

## 技术结构

- Flutter / Dart
- Riverpod：状态与依赖管理
- GoRouter：声明式导航和四个主入口
- Drift + SQLite：本地数据库和迁移
- Flutter Pub Workspace：管理组件化 package
- Domain Entity / UseCase / Repository：隔离 UI 与 Drift
- Feature dependency port + Riverpod override：由根 App 完成依赖装配

主要目录：

```text
lib/
├── main.dart              Data 生命周期与 Feature 依赖装配
└── src/
    ├── kitchen_notes_app.dart    根 MaterialApp
    └── navigation/               路由表与四栏 MainShell
packages/
├── kitchen_app_core/      路由名称与导航扩展
├── kitchen_design_system/ 主题与视觉常量
├── kitchen_recipe_domain/ 纯 Dart 实体、UseCase 与 Repository 接口
├── kitchen_recipe_data/   Drift、Mapper 与 Repository 实现
├── kitchen_recipe_template/版本化模板、校验、降级与共享 Flutter 渲染器
├── kitchen_recipe_library/菜谱库、搜索、详情与业务展示组件
├── kitchen_recipe_editor/ 手动创建菜谱
├── kitchen_home/          首页
├── kitchen_import/        导入箱
├── kitchen_import_domain/ 导入状态机、草稿与处理端口（纯 Dart）
├── kitchen_import_data/   独立 Drift 导入库、网页提取、媒体存储与 OCR 适配
└── kitchen_profile/       我的页面与全局视觉风格状态
```

依赖方向：

```text
kitchen_notes → 所有组件（组合根）
Feature → kitchen_app_core + kitchen_design_system
Recipe Feature → kitchen_recipe_domain
Recipe Feature → kitchen_recipe_template → kitchen_recipe_domain
kitchen_recipe_data → kitchen_recipe_domain
```

Feature 不直接依赖 Data、根 App 或其他 Feature。菜谱库和编辑器公开依赖端口，
根 App 将同一个 Repository 实例包装为 UseCase 后通过 Riverpod override 注入。
导入 Feature 同样只依赖 Import Domain；根 App 负责将导入草稿映射到菜谱编辑器，
并在保存成功后协调两套状态。

## 运行

```sh
flutter pub get
dart run build_runner build
flutter run
```

根工程使用 Pub Workspace 管理全部 `kitchen_*` package，`flutter pub get`
会统一解析组件依赖。

修改 Drift 表结构后，在 `packages/kitchen_recipe_data` 中重新运行代码生成：

```sh
cd packages/kitchen_recipe_data
dart run build_runner build
```

全量验证：

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test packages/*/test
```

## 当前环境说明

- iOS 模拟器构建已验证。
- Android 工程已生成；本机需要 JDK 17 或更高版本，并补齐 Android
  command-line tools 与 licenses 后才能构建。
- `com.example.kitchenNotes` 是开发期临时 Bundle ID，发布前需要替换。
