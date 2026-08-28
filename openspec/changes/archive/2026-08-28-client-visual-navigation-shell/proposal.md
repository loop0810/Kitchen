## Why

客户端当前的底部导航仍使用 Material 默认图标，顶部导航栏、页面背景和导航栏的视觉关系也没有统一到现有的手账/极简主题。新的导航图标资源已经准备好，且需要在正式接入前完成命名和资源注册，避免视觉实现继续依赖临时图标。

## What Changes

- 将底部四个 Tab 的 8 个 PNG 资源统一为带 `tab_` 前缀、`snake_case` 和 `selected/unselected` 状态后缀的名称，并移除资源名中的 `@3x`。
- 在 Flutter 应用中注册并使用底部 Tab 图标资源，保留现有四个入口、顺序、中文标签和导航栈行为。
- 统一根导航壳的底部 Tab 栏视觉样式，包括图标尺寸、选中状态、背景、标签和安全区域适配。
- 统一顶部导航栏与 App 背景的主题表现，并复用 `kitchen_design_system` 的颜色、间距和文字常量。
- 为资源注册、主题配置和导航壳的关键视觉行为补充适用的结构/Widget 验证。

## Capabilities

### New Capabilities

- `client-visual-navigation-shell`: 定义客户端根导航壳的底部 Tab 栏、顶部导航栏和 App 背景的可观察视觉约束。

### Modified Capabilities

- 无。

## Impact

- 受影响代码：根 App 导航壳、`kitchen_design_system` 主题及其测试。
- 受影响资源：`client/assets/images/` 下的底部导航图标和根 `client/pubspec.yaml` 资源声明。
- 不涉及服务端、API、数据库、路由语义、产品流程或生产依赖。
