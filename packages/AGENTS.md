# Package 通用约束

本文件适用于 `packages/**`，并继承项目根目录 `AGENTS.md`。

## 公共边界

- 每个 package 只通过 `lib/kitchen_*.dart` 暴露必要公共 API。
- 跨 package 禁止导入其他 package 的 `src/`。
- Feature 不依赖 Data、根 App 或其他 Feature。
- Data 不依赖 UI、Design System 或 Feature。
- App Core 不依赖业务 Domain。
- 通用视觉组件放入 `kitchen_design_system`，业务组件留在所属 Feature。
- Presentation 不得使用 Drift 生成类型或直接访问数据库。

## 命名

- 新增或重命名文件前阅读 `docs/NAMING_CONVENTIONS.md`。
- Dart 文件使用该组件唯一且统一的文件前缀。
- 页面使用 `*_page.dart` / `*Page`，禁止新增 `screen`。
- 独立 UI 子组件使用 `*_widget.dart` / `*Widget`。
- 禁止含义模糊的 `utils`、`helpers`、`common`、`manager`。
- `*.g.dart` 等生成文件保留工具命名，禁止手动编辑。

## 依赖与 UI

- 新增生产依赖时说明用途，以及现有依赖无法满足需求的原因。
- Feature 中禁止新增硬编码颜色、间距、字体或圆角。
- 默认中文文案需要考虑语义标签、Tooltip 和系统文字缩放。

## 验证

- 修改 package 后运行该 package 的相关测试。
- 跨 package 修改完成后执行根 `AGENTS.md` 中的全量验证。
