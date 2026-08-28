# client-visual-navigation-shell Specification

## Purpose

为客户端根导航壳提供一致、可识别且适配两套视觉主题的底部 Tab 栏、顶部导航栏和应用背景表现，确保导航状态切换不会引起图标尺寸或页面层次跳变。

## Requirements

### Requirement: Bottom navigation exposes branded selected states

客户端 SHALL 在现有顺序中提供“首页”“菜谱库”“导入箱”“我的”四个底部导航入口，并为每个入口显示对应的选中或未选中视觉资源。切换视觉资源不得改变现有导航分支、中文标签或导航栈行为。

#### Scenario: Current branch shows the selected asset

- **WHEN** 当前导航分支为任一底部 Tab
- **THEN** 当前 Tab 显示该入口的 selected 资源，其余三个 Tab 显示各自的 unselected 资源

#### Scenario: Switching branches updates only visual selection

- **WHEN** 用户点击另一个底部 Tab
- **THEN** 选中资源随当前分支更新，四个入口的顺序、标签和原有导航栈恢复行为保持不变

### Requirement: Navigation assets have a stable package contract

底部导航资源 SHALL 以八个名称稳定、状态成对的 PNG 文件打包；每个文件的源画布 SHALL 为 `75×75`，文件名 SHALL 使用 `tab_<destination>_<selected|unselected>.png` 形式，且不得包含 `@3x`。

#### Scenario: All four destinations have both states

- **WHEN** 客户端构建读取导航资源
- **THEN** `home`、`recipe_library`、`import_inbox` 和 `profile` 四个 destination 均存在 selected 与 unselected 两个资源

#### Scenario: Navigation icons render in a stable box

- **WHEN** selected 与 unselected 状态在同一底部 Tab 位置之间切换
- **THEN** 图标在相同的显示尺寸和对齐区域内渲染，不因源图片内容或状态变化造成布局跳动

### Requirement: Navigation chrome follows the active visual style

顶部导航栏、底部导航栏和页面根背景 SHALL 使用当前应用视觉主题的表面色、前景色和强调色；手账主题 SHALL 保持温暖纸张层次，极简主题 SHALL 保持低对比度的极简背景。导航栏不得产生与页面主题无关的突兀色带。

#### Scenario: Scrapbook style renders warm navigation chrome

- **WHEN** 当前视觉主题为手账风格
- **THEN** 页面根背景使用手账纸张表面色，顶部导航标题和底部标签使用墨色，选中状态使用手账强调色体系

#### Scenario: Minimal style renders restrained navigation chrome

- **WHEN** 当前视觉主题为极简风格
- **THEN** 页面根背景使用极简表面色，顶部导航和底部导航保持白色/低对比度表面，选中状态使用极简主题主色体系

#### Scenario: System insets remain usable

- **WHEN** 设备存在底部安全区域或系统文字缩放
- **THEN** 底部导航内容不被系统区域遮挡，顶部标题和导航标签仍保持可读且不改变导航入口语义
