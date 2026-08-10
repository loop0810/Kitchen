## 1. 路由契约整理

- [x] 1.1 检查 `AppRouteNames` 与壳工程的 GoRoute name 一一对应。
- [x] 1.2 为所有跨 Feature 全局页面补齐 `AppNavigationExtension` 方法。
- [x] 1.3 确认带路径参数和查询参数的参数键只在导航扩展中维护。

## 2. 生产代码迁移

- [x] 2.1 将 Feature 中的全局 `context.go`、`context.push`、`context.pushNamed` 跳转迁移为语义化扩展。
- [x] 2.2 保留对话框、表单返回和局部临时页面使用 `Navigator` 的合理场景。
- [x] 2.3 为导航扩展补充必要的中文注释，说明全局路由与局部 Navigator 的边界。

## 3. 工程约束与验证

- [x] 3.1 在客户端工程文档中记录路由注册和 Feature 跳转约束。
- [x] 3.2 增加或更新静态搜索检查，禁止生产 Feature 直接写全局路径跳转。
- [x] 3.3 运行受影响 package 测试、Flutter analyze 和格式检查。

验证记录：`kitchen_app_core` 测试和 Flutter analyze 通过；路由边界检查及受影响文件定向格式检查通过。客户端全量 Dart 格式检查已执行，但仍报告两个与本次路由改动无关的既有文件需要格式化。
