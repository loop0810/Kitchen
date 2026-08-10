## Context

GoRouter 的路由注册需要访问具体页面类型，因此继续由壳工程注册。Feature package 不直接依赖壳工程，而通过 `kitchen_app_core` 暴露的导航扩展调用全局页面跳转。

## Design

### 路由分层

```text
kitchen_app_core
  ├── AppRouteNames
  └── AppNavigationExtension
          ↑ Feature 依赖
          │
根壳工程
  └── kitchen_notes_app_router.dart 注册 GoRoute
```

- `AppRouteNames` 保存稳定的 route name。
- `AppNavigationExtension` 封装 `goNamed`、`pushNamed` 和参数传递。
- 壳工程的 `appRouter` 是唯一全局 `path` 注册点。
- Feature 页面只调用 `context.pushRecipeDetail(id)` 等语义化方法。

### 生产代码约束

- Feature 生产代码禁止直接调用 `context.go('/...')`、`context.push('/...')`、`context.pushNamed('...')`。
- Feature 生产代码禁止复制全局路由的 path 或 route name。
- `Navigator.pop`、`showDialog` 和局部临时页面导航仍可保留。
- 测试可以构造最小 GoRouter，但测试中的路径只用于验证路由注册，不作为生产导航 API。

### 参数安全

新增带参数的路由时，必须在导航扩展中集中填写 `pathParameters` 或 `queryParameters`。页面调用方只传递领域参数，例如 `recipeId`，不传 route name 或参数键名。

### 不采用代码生成

本轮不引入 `go_router_builder`。当前项目已有 `AppRouteNames` 和导航扩展，继续完善这套方案可以保持 package 边界简单；当路由参数和页面规模显著增长时，再单独评估类型化路由生成。

## Verification

- 使用 `rg` 检查 Feature 生产代码中不存在全局路径字符串跳转。
- 检查所有 `AppRouteNames` 都有对应 GoRoute 注册和导航扩展（局部只读路由名除外）。
- 运行受影响 package 测试和 Flutter analyze。
