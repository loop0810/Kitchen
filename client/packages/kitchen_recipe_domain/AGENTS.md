# Recipe Domain 组件约束

本文件适用于 `packages/kitchen_recipe_domain/**`，并继承上级约束。

## 纯 Dart 边界

- `lib/` 生产代码只依赖 Dart SDK。
- 禁止依赖 Flutter、Riverpod、Drift、平台插件或网络库。
- 禁止出现数据库 Row、Companion、DTO 或 UI 类型。

## 职责

- Entity 表达领域数据，不承担持久化或展示职责。
- Repository 只定义领域所需接口，由 Data 实现。
- UseCase 编排单一业务动作，并保持错误传播可测试。
- 新增领域能力时同步补充实体、Repository 契约和 UseCase 测试。

## 验证

```sh
./tool/kitchen_flutter.sh test packages/kitchen_recipe_domain/test
```
