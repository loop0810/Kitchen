# 厨房手记项目约束

## 开始工作前

- 本项目用于学习 Flutter、组件化、数据库和 Codex 工作流。
- 修改产品行为前阅读 `docs/MVP_REQUIREMENTS.md`。
- 新增或重命名文件前阅读 `docs/NAMING_CONVENTIONS.md`。
- 涉及 Codex 教学时阅读 `docs/CODEX_WORKFLOW.md`。
- 产品名和 Bundle ID 尚未最终确定。
- 交付代码时简要说明本次涉及的架构边界或 Flutter 知识点。

## 组件边界

```text
app
├── feature_* ──> recipe_domain
├── recipe_data ─> recipe_domain
├── design_system
└── app_core
```

- `app` 负责路由、依赖装配和跨 Feature 协调，Feature 之间禁止直接依赖。
- Domain 不依赖 Flutter、Drift、平台插件或网络库；Data 实现 Domain 接口。
- Presentation 不得使用 Drift 生成类型或直接访问数据库。
- 跨组件通信使用 callback、Riverpod、UseCase、Repository Stream 或类型化导航。
- 禁止使用全局 EventBus。
- 通用视觉组件放入 `design_system`，业务组件留在所属 Feature。

## 命名摘要

- 文件使用 `snake_case` 和明确的职责后缀。
- 页面必须使用 `*_page.dart` / `*Page`，禁止新增 `screen`。
- 抽取到独立文件的 UI 子组件必须使用 `*_widget.dart` / `*Widget`。
- 禁止含义模糊的 `utils`、`helpers`、`common`、`manager`。
- 其它后缀和例外以 `docs/NAMING_CONVENTIONS.md` 为准。
- `*.g.dart` 等生成文件保留工具命名，禁止手动编辑。

## 数据、AI 与 UI

- 核心浏览、编辑和烹饪必须离线可用。
- 原始导入内容与用户修改分开保存，用户修改优先。
- 云端 AI 通过抽象接口访问，客户端禁止保存服务密钥。
- 修改 Drift 表时必须升级 schema、补充迁移、生成代码并添加数据库测试。
- 极简与手账风格共享业务页面，通过 Design Token 和展示组件切换。
- 禁止在 Feature 中新增硬编码颜色、间距、字体或圆角。
- 烹饪模式必须易读、大点击区域、无广告。
- 默认使用中文文案，并考虑语义标签、Tooltip 和系统文字缩放。

## 验证

完成代码修改后运行：

```sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

修改 Drift 声明后额外运行 `dart run build_runner build`。

## 修改纪律

- 保留无关的用户修改。
- 新增生产依赖时说明用途和现有依赖无法满足的原因。
- 产品需求变化时更新 `docs/MVP_REQUIREMENTS.md`。
- 工程结构或启动方式变化时更新 `README.md`。
- 禁止提交密钥、签名材料、构建目录和本地环境路径。
