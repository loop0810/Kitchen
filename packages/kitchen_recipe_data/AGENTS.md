# Recipe Data 组件约束

本文件适用于 `packages/kitchen_recipe_data/**`，并继承上级约束。

## 架构边界

- 本组件只实现 `kitchen_recipe_domain` 定义的接口。
- 禁止依赖 Flutter UI、Design System、根 App 或任何 Feature。
- Drift Row、Companion、数据库连接和 Mapper 只能留在本组件内部。
- 公共 API 仅暴露 `RecipeDataModule`，并通过它提供 Domain Repository getter
  和生命周期能力。

## 数据与 AI

- 数据库路径、文件名、schema version、种子数据和既有行为不得无意改变。
- 原始导入内容与用户修改分开保存，用户修改优先。
- 核心菜谱数据必须支持离线读写。
- 云端 AI 通过抽象接口访问，客户端禁止保存服务密钥。

## Drift 修改

- 修改 Drift 表声明时必须升级 schema version。
- 为 schema 变化补充迁移和数据库测试。
- 运行 `dart run build_runner build` 重新生成代码。
- 禁止手动编辑 `*.g.dart`。

## 验证

修改 Drift 声明后进入本组件执行：

```sh
cd packages/kitchen_recipe_data
dart run build_runner build
flutter test
```
