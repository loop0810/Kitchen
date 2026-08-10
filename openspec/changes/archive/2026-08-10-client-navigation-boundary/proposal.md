## Why

当前路由由壳工程注册，但部分页面仍可能直接依赖路径字符串或 `Navigator` 细节。随着页面数量增加，路径参数、route name 和跳转方式容易出现拼写不一致，路由重命名也难以安全地全局维护。

## What Changes

- 统一使用 `kitchen_app_core` 中的 `AppRouteNames` 和语义化导航扩展。
- 禁止生产 Feature 代码直接写全局 GoRouter 路径或 route name。
- 保留壳工程作为唯一的全局路由注册位置。
- 为新增路由补充统一的注册、命名和导航扩展约束。
- 清理受影响生产代码中的直接全局路径跳转；局部弹窗和临时页面仍可使用局部 Navigator。

## Capabilities

### New Capabilities

<!-- 纯架构重构，不改变用户可见行为，已通过 skip_specs=true 跳过行为规格。 -->

### Modified Capabilities

<!-- 纯架构重构，不修改既有产品行为或接口契约。 -->

## Impact

- 影响 `client/lib/src/navigation/kitchen_notes_app_router.dart`、`client/packages/kitchen_app_core` 及各 Feature 的生产跳转代码。
- 不新增生产依赖，不改变路由地址、页面行为或数据库数据。
- 需要补充静态搜索/测试约束，防止未来重新引入生产代码中的硬编码全局路径。
