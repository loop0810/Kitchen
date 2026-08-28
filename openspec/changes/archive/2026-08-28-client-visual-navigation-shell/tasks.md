## 1. 导航资源整理

- [x] 1.1 统一底部 Tab 图片资源命名并接入 Flutter 资源声明
  - Validation Level: Structural
  - Goal: 让四个底部 Tab 的 selected/unselected 图片以稳定、无 `@3x` 的名称被客户端构建识别。
  - Scope:
    - 将 `client/assets/images/` 下 8 个导航 PNG 重命名为 `tab_home`、`tab_recipe_library`、`tab_import_inbox`、`tab_profile` 对应的 selected/unselected 文件。
    - 确认 8 个文件均为 `75×75`，并在根 `client/pubspec.yaml` 中声明资源目录或明确的资源文件。
    - 检查旧文件名没有残留引用；不将 `.DS_Store` 声明为 Flutter 资源。
  - Out of Scope:
    - 不修改 iOS AppIcon、LaunchImage 等平台专用资源名称。
    - 不改变图片内容、颜色或画布尺寸。
  - Acceptance Criteria:
    - [ ] 8 个最终文件均符合 `tab_<destination>_<selected|unselected>.png` 命名，且名称不含 `@3x`。
    - [ ] 8 个 PNG 均为 `75×75`，Flutter 资源声明可被工程解析。
    - [ ] `rg` 搜索不到旧导航资源名的生产引用。
  - Reset / Verification:
    - 仅回滚本 Task 的资源重命名和 `client/pubspec.yaml` 资源声明；运行 `file client/assets/images/*.png`、`rg -n '@3x|home-selected|recipe-library-selected|import-box-selected|profile-selected' client/assets client/pubspec.yaml` 验证。

## 2. 根导航壳

- [x] 2.1 使用品牌资源替换底部 Tab 默认图标
  - Validation Level: Behavior
  - Goal: 在保留现有导航语义的前提下，让底部 Tab 按当前分支显示正确的品牌图标。
  - Scope:
    - 修改根 App 的导航壳，将四组图片映射到现有四个 `NavigationDestination`。
    - 为 selected/unselected 图标设置统一的 `25×25` logical px 显示盒和 contain 对齐。
    - 保留现有 Tab 顺序、中文标签、`StatefulNavigationShell` 分支切换和再次点击回到初始页的行为。
    - 补充或更新根 App 导航壳的 Widget 验证。
  - Out of Scope:
    - 不新增 Tab，不改变路由路径或导航分支。
    - 不在 Feature 包中复制根导航逻辑。
  - Acceptance Criteria:
    - [ ] 当前 Tab 显示 selected 资源，其余 Tab 显示 unselected 资源。
    - [ ] selected 与 unselected 切换时图标尺寸和位置不发生布局跳动。
    - [ ] 现有导航栈恢复及重复点击行为验证通过。
  - Reset / Verification:
    - 回滚 MainShell 及其测试修改即可恢复默认图标；运行相关 Flutter Widget 测试并通过 Android 竖屏手动切换四个 Tab 验证。

## 3. 主题视觉统一

- [x] 3.1 统一顶部导航栏、底部导航栏和 App 背景主题
  - Validation Level: Behavior
  - Goal: 让根导航壳和页面顶部导航在手账/极简主题下保持一致的表面色、前景色和选中强调色。
  - Scope:
    - 在 `kitchen_design_system` 的 `AppTheme` 中集中配置 AppBar、NavigationBar 和 scaffold surface 的视觉关系。
    - 手账主题复用 `paper/card/coral/blush/ink`，极简主题复用 `minimalSurface/minimalSeed/minimalBorder` 和白色表面。
    - 更新主题测试，覆盖两套主题的背景、导航表面和前景色关键约束。
  - Out of Scope:
    - 不重做首页、菜谱库、导入箱或个人页的内容布局。
    - 不新增视觉依赖、字体或图片背景资源。
  - Acceptance Criteria:
    - [x] 两套主题的页面根背景、顶部导航栏和底部导航栏没有与主题无关的突兀色带。
    - [x] 顶部标题、底部标签和选中状态满足 spec 中的主题色约束。
    - [x] 既有 design system 主题测试和相关 package 测试通过。
  - Reset / Verification:
    - 回滚 `AppTheme` 及主题测试修改即可恢复原主题；运行 `./tool/kitchen_flutter.sh test packages/kitchen_design_system/test` 并检查两套主题的 Widget 渲染。

## 4. 变更验证

- [x] 4.1 完成导航壳视觉变更的结构与运行时验证
  - Validation Level: Behavior
  - Goal: 确认资源、主题、导航行为和安全区域适配在客户端工程中可重复验证。
  - Scope:
    - 运行适用的 Dart 格式、Flutter analyze、根客户端测试和 design system 测试。
    - 在 Android 竖屏模拟器或实体设备上验证四个 Tab、顶部导航和页面背景；记录设备/环境前提。
    - 检查差异、旧资源引用、`@3x` 残留和 `.DS_Store` 是否被误加入资源声明。
  - Out of Scope:
    - 不进行服务端、数据库、API 或跨端契约验证。
    - 未实际运行的设备或命令不得标记为通过。
  - Acceptance Criteria:
    - [x] 已执行的结构和客户端验证命令结果记录在当前 Change 的 Task Report 中。
    - [x] Android 竖屏手动验收结果记录为 PASS、PARTIAL、BLOCKED 或 NOT RUN，并说明原因。
    - [x] `openspec validate --strict`、`git diff --check` 和适用客户端检查结果真实记录。
  - Reset / Verification:
    - 不修改运行时状态；从干净的当前工作树重新运行 Report 中记录的命令即可复核。
