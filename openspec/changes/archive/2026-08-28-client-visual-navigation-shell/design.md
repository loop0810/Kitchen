## Context

参见 `proposal.md` 的 Why 和 Impact。本次变更的当前入口是根 App 的 `MainShell` 和 `kitchen_design_system` 主题：MainShell 仍使用 Material 默认图标，主题已有手账/极简两种视觉样式，但导航壳的背景、选中状态和资源尚未统一。`client/assets/images/` 中已有 8 个统一为 `75×75` 的 PNG，当前文件名仍带 `@3x`，且尚未在 `pubspec.yaml` 中声明。

## Goals / Non-Goals

**Goals:**

- 让四个底部 Tab 使用成对的品牌图标资源，并在固定显示盒中切换状态。
- 让根导航壳、页面顶部 AppBar 和页面背景复用现有设计系统颜色与主题切换。
- 保留当前路由、Tab 顺序、中文标签和导航栈语义。
- 不引入新的生产依赖，并为资源、主题和导航壳提供可重复验证。

**Non-Goals:**

- 不重做首页、菜谱库、导入箱或个人页的内容布局。
- 不改变路由路径、业务流程、数据模型、API 或服务端代码。
- 不将 `@3x` 批量改名到 iOS AppIcon 或 LaunchImage 等平台专用资源；本次只处理客户端导航资源目录。

## Decisions

### 1. 使用语义化的 Tab 资源名并显式声明资源

采用 `tab_<destination>_<selected|unselected>.png`、`snake_case` 命名。`selected/unselected` 与 Flutter 导航语义一致，`tab_` 前缀为未来顶部导航资源保留命名空间；`import_inbox` 与产品名称和现有组件命名保持一致。资源作为根 App 的显式 Flutter asset 声明接入，不依赖平台目录或隐式扫描。

替代方案：继续使用 `home-selected@3x.png` 等设计工具导出名。该方案虽然改动少，但会把像素密度信息混入逻辑资源名，并与项目的下划线命名风格及现有 `import_inbox` 术语不一致，因此不采用。

### 2. 75 像素源画布映射到固定的 25 logical px 显示盒

资源保留统一的 `75×75` 源画布，在导航入口中以固定 `25×25` logical px 显示并使用 contain 对齐。这样可以保留适合高密度屏幕的源图，同时保证 selected/unselected 切换时不会因 PNG 外接尺寸不同而跳动。

替代方案：直接让 `Image.asset` 使用其 intrinsic size。该方案会把 75 像素误当作 logical px，导致导航栏过大；使用 `ImageIcon` 也无法表达 selected/unselected 两套不同的填充图形，因此不采用。

### 3. 通过现有主题统一导航壳，而不是在 Feature 页面分别设色

在 `AppTheme.forStyle` 中集中定义 AppBar、NavigationBar 和 scaffold surface 的关系：手账风格复用 `paper/card/coral/blush/ink`，极简风格复用 `minimalSurface/minimalSeed/minimalBorder` 及白色表面。MainShell 只负责导航结构和资源映射，不持有业务视觉常量；页面自身的 AppBar 继续通过全局主题获得一致表现。

替代方案：在每个 Feature 页面内分别设置 `backgroundColor`、AppBar 和导航栏颜色。该方案容易产生页面间色带不一致，也会扩大变更范围，违背 design system 的职责边界，因此不采用。

### 4. 保持导航行为不变

只替换视觉层和主题配置，不调整 `StatefulNavigationShell` 的分支顺序、`goBranch` 参数或路由注册。测试重点覆盖当前 Tab 选择状态与已有分支切换行为，避免视觉修复引入导航回归。

## Risks / Trade-offs

- [Risk] 75 像素图片在非 3x 屏幕上缩放后可能出现轻微边缘柔化 → 使用固定 25 logical px 和 `BoxFit.contain`，并在 Android/iOS 竖屏设备上进行一次视觉检查。
- [Risk] 页面局部可能覆盖主题背景 → 先限制本 Change 为根主题和导航壳；发现必须修改某个页面局部背景时，记录为当前 Task 的明确范围扩展，不用隐式硬编码绕过主题。
- [Risk] 图片资源重命名导致旧引用失效 → 当前搜索未发现资源引用；资源注册与引用在同一 Task 中完成，并通过全仓库搜索确认不存在旧文件名或 `@3x` 导航资源名。

## Migration Plan

1. 将 8 个导航 PNG 重命名为稳定资源名并登记到 `client/pubspec.yaml`。
2. 接入 MainShell 的 selected/unselected 资源并更新导航主题。
3. 更新设计系统主题测试和根 App 相关 Widget 验证。
4. 若视觉回归不符合预期，回滚当前 Change 中的资源声明、导航壳和主题修改即可；不涉及数据迁移或线上兼容窗口。

## Open Questions

无。顶部导航和 App 背景先复用现有设计系统的两套主题；更细的页面内容视觉重做另行规划。
