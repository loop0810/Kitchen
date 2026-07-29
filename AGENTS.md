# 厨房手记项目约束

## 开始工作前

- 本项目用于学习 Flutter、组件化、数据库和 Codex 工作流。
- 修改产品行为前先阅读 `docs/README.md`，再按其中路由只读取与任务相关的
  权威需求或服务文档；涉及当前版本范围时必须阅读 `docs/MVP_REQUIREMENTS.md`。
- 新增或重命名文件前阅读 `docs/NAMING_CONVENTIONS.md`。
- 涉及 Codex 教学时阅读 `docs/CODEX_WORKFLOW.md`。
- 修改 `packages/**` 前阅读 `packages/AGENTS.md`。
- 修改含有子级 `AGENTS.md` 的组件前，继续阅读该组件的专项约束。
- 产品名和 Bundle ID 尚未最终确定。
- 交付代码时简要说明本次涉及的架构边界或 Flutter 知识点。

## 组件边界

```text
kitchen_notes
├── kitchen_{home,import,profile} ──> kitchen_design_system + kitchen_app_core
├── kitchen_recipe_{library,editor} ──> kitchen_recipe_template
│                                      + kitchen_recipe_domain
│                                      + kitchen_design_system
│                                      + kitchen_app_core
├── kitchen_recipe_template ──> kitchen_recipe_domain
├── kitchen_recipe_data ──> kitchen_recipe_domain
├── kitchen_design_system
└── kitchen_app_core
```

- 根 App 负责路由、依赖装配和跨 Feature 协调。
- Feature 之间禁止直接依赖。
- 跨组件通信使用 callback、Riverpod、UseCase、Repository Stream 或类型化导航。
- 禁止使用全局 EventBus。

## 产品通用约束

- 核心浏览、编辑和烹饪必须离线可用。
- 默认使用中文文案，并考虑语义标签、Tooltip 和系统文字缩放。
- 烹饪模式必须易读、大点击区域、无广告。

## 验证

完成代码修改后运行：

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter test packages/*/test
```

组件专项验证以对应子级 `AGENTS.md` 为准。

## 修改纪律

- 保留无关的用户修改。
- 新增生产依赖时说明用途和现有依赖无法满足的原因。
- 产品需求变化时更新对应权威需求文档和 `docs/DECISION_LOG.md`；影响当前版本
  范围时同时更新 `docs/MVP_REQUIREMENTS.md`。
- 工程结构或启动方式变化时更新 `README.md`。
- 禁止提交密钥、签名材料、构建目录和本地环境路径。
