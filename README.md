# 厨房手记

一个使用 Flutter 开发的本地优先菜谱应用。当前版本用于验证核心 MVP：

- 极简首页搜索
- 手账 / 极简双视觉主题
- 本地 SQLite 菜谱存储
- 菜谱库、状态筛选与本地搜索
- 手动创建菜谱
- 食材分组、步骤与菜谱详情
- 导入箱、云端 AI 和激励广告的扩展入口

## 项目文档

- [MVP 需求文档](docs/MVP_REQUIREMENTS.md)
- [Codex CLI 与 VS Code 学习工作流](docs/CODEX_WORKFLOW.md)
- [Codex 项目约束](AGENTS.md)

## 技术结构

- Flutter / Dart
- Riverpod：状态与依赖管理
- GoRouter：声明式导航和四个主入口
- Drift + SQLite：本地数据库和迁移
- 当前为 Feature-first 单 package 结构
- 目标为 app、domain、data、design system 与 feature packages 组成的组件化结构

主要目录：

```text
lib/src/
├── data/          数据库与 Repository
├── features/      业务功能
├── navigation/    路由与主导航
└── theme/         视觉主题和设计令牌
```

## 运行

```sh
flutter pub get
dart run build_runner build
flutter run
```

修改 Drift 表结构后，需要重新运行代码生成。

## 当前环境说明

- iOS 模拟器构建已验证。
- Android 工程已生成；本机需要 JDK 17 或更高版本，并补齐 Android
  command-line tools 与 licenses 后才能构建。
- `com.example.kitchenNotes` 是开发期临时 Bundle ID，发布前需要替换。
