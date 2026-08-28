# 厨房手记 Monorepo 约束

## 先确定任务范围

- 本仓库同时维护 `client/` 中的 Flutter 客户端和 `server/` 中的 Python/FastAPI 服务端。
- 开始任务先阅读 `docs/README.md` 的任务矩阵，只加载默认文档；禁止默认遍历整个 `docs/`。
- 修改 `client/**` 时继续阅读 `client/AGENTS.md` 和命中目录中的专项 `AGENTS.md`。
- 修改 `server/**` 时继续阅读 `server/AGENTS.md`；服务端内部任务不默认读取客户端、Figma 或完整产品文档。
- 修改共享请求、响应、标识符、版本、错误、幂等或同步语义时，必须读取并更新对应 `docs/contracts` 权威文档，再检查两端受影响边界。
- 修改用户可见行为或版本范围时，必须读取 `docs/product/README.md` 路由的权威需求，并记录相关决策。
- 修改基础设施或腾讯云部署时，只读取服务端运维、基础设施、安全及相关 contract；不默认读取客户端视觉和本地功能细节。

## OpenSpec

- 仓库只使用根 `openspec/` 作为变更规划入口；从仓库根运行 OpenSpec 命令。
- Change 模式下的客户端、服务端和共享变更均位于 `openspec/changes`，名称应清楚表达范围，例如 `client-*`、`server-*` 或 `shared-*`；已有历史名称无需仅为前缀重命名。
- 产品行为、共享契约、架构边界或跨文件工作流变化按全局 Change Gate 判断；开发者明确选择 `change` 时先创建 OpenSpec Change，低风险局部任务可由开发者选择 `direct` 轻量路径。
- 完成服务端 change 后、归档前，按 `docs/learning/server/README.md` 创建学习记录或写明学习记录豁免。
- 通用 OpenSpec/Harness 生命周期由全局 `~/.codex/AGENTS.md` 和 `~/.codex/skills/harness/SKILL.md` 负责；执行仓库任务时再阅读 [`docs/Harness/README.md`](docs/Harness/README.md) 获取 Kitchen 技术栈扩展。
- `docs/Harness/` 只维护本项目的读取路由、Flutter/Android、FastAPI/PostgreSQL、共享 contract、验证命令和工作区边界，不复制全局生命周期。
- Change 模式下，`openspec list` 存在多个活动 Change 时不得按最近修改时间猜选；必须由用户或当前会话明确当前 Change。Direct 模式不创建或选择 Change。

## 修改纪律

- 保留无关用户修改；移动文件前检查 Git 状态，迁移后验证内容和链接。
- 规范性内容只在一个权威位置定义；其他文档使用链接和实现说明，禁止复制出竞争事实源。
- 新增生产依赖、密钥处理、数据迁移或外部服务时，必须说明边界、失败策略和验证方式。
- 禁止提交密钥、签名材料、构建目录和本地环境绝对路径。
- 开始 Task 前保留 Git 现场并区分已有用户修改；不得自动清理、回滚或提交未获授权的改动。
- 验证命令和代码风格以对应项目及更深层 `AGENTS.md` 为准。
