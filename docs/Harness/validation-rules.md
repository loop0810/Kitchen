# Kitchen Validation Rules

全局 Harness 负责验证流程和真实证据要求；本文件只定义 Kitchen Task 的技术栈验证命令和范围矩阵。验证等级由当前 Task 和受影响边界决定；没有填写时按 `Behavior` 处理，并在 Report 中说明。

## Level 1：Structural

适用于目录、类型、接口、配置、依赖方向、文档和 OpenSpec 元数据。

最低要求：

- 结构、引用和差异检查；
- 客户端适用时运行 `dart format --output=none --set-exit-if-changed .`、`./tool/kitchen_flutter.sh analyze` 和相关 package 测试；
- 服务端适用时运行 `make lock-check`、`make format-check`、`make typecheck`、`make test` 中的相关命令；
- 文档或 OpenSpec 任务运行 `openspec validate --strict`、相对链接/过期路径扫描和 `git diff --check`。

结构任务默认不要求新增自动化测试，但必须说明已有检查是否执行。

## Level 2：Behavior

适用于用户交互、导航、导入状态、OCR 草稿、持久化恢复、平台桥接、HTTP 行为和服务运行规则。

最低要求：

- 结构检查；
- 相关 Flutter 单元/Widget 测试和 `./tool/kitchen_flutter.sh test` 的适用范围；
- Android 模拟器或实体设备上的真实流程（当前 V1 默认优先 Android）；
- 服务端相关 `make test`，需要 PostgreSQL 约束时运行 `make integration-test`，并记录数据库/环境前提；
- 对失败、取消、重试、恢复、幂等和 Reset 的观察或测试。

只有逻辑容易回归、边界无法稳定手动验证、Task 明确要求或属于长期核心能力时，才要求新增自动化测试。手动验收必须明确写成手动验收。

## Level 3：Critical

适用于数据库 schema/迁移、认证授权、幂等、同步、备份恢复、删除策略、额度账本、安全边界和跨端一致性。

最低要求：

- 结构检查和自动化测试；
- 客户端本地数据库迁移/恢复及相关包测试；
- 服务端 PostgreSQL 集成测试，不用 SQLite 代替最终约束验证；
- 共享 contract 两端受影响边界的兼容性验证；
- 关键失败、重复执行、取消/恢复和数据清理场景；
- 必要的 Android/服务运行时验证。

## 按范围选择验证

| 影响范围 | 需要的最低证据 |
| --- | --- |
| 客户端内部 | 相关格式、分析、package 测试；Behavior 任务再加模拟器/设备流程 |
| 服务端内部 | 相关 lock/format/type/test；涉及 DB、安全或迁移时加 PostgreSQL 集成测试 |
| 共享 contract | 先更新 contract，再验证客户端和服务端的请求/响应、错误、版本、幂等或同步语义 |
| 产品行为或版本 | 产品权威文档与决策记录已更新，相关端到端行为真实验收 |
| Harness / OpenSpec / 文档 | OpenSpec validate、链接和 stale 路径检查、范围 diff；不把应用构建误报为已执行 |

## 证据要求

- 记录完整命令、目标范围、环境前提和结果；失败保留错误摘要。
- `PASS` 只表示命令真实执行并通过；`FAIL` 表示真实失败；`NOT RUN` 表示未执行，不能留空。
- 构建通过不等于用户行为、数据库迁移或跨端语义通过。
- 未能运行设备、Docker、PostgreSQL 或签名验证时，写为 `BLOCKED`、`PARTIAL` 或 `NOT RUN`，并记录解除条件。
