# Design System 组件约束

本文件适用于 `packages/kitchen_design_system/**`，并继承上级约束。

## 架构边界

- 本组件只依赖 Flutter，不依赖 Domain、Data、根 App 或 Feature。
- 只接收真正跨业务复用的视觉常量、主题和展示组件。
- 禁止加入菜谱、导入、账户等业务逻辑。

## 视觉规则

- 常量文件使用颜色、间距、圆角、尺寸和文字等具体职责命名。
- 禁止使用含义宽泛的 `tokens` 作为文件后缀。
- 极简与手账风格共享业务页面，通过视觉常量和展示组件切换。
- 修改既有常量值时说明视觉影响，并补充或更新主题测试。

## 验证

```sh
./tool/kitchen_flutter.sh test packages/kitchen_design_system/test
```
