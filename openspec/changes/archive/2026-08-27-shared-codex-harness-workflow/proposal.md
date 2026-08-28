## Why

Kitchen 已经有根级和端侧 `AGENTS.md`、分层文档导航以及 OpenSpec change，但执行规则仍主要依赖聊天上下文和简单的 `tasks.md` 复选框。跨 Flutter/Android、Python/FastAPI 和共享 contract 的任务因此缺少统一的开始条件、范围控制、验证证据、失败状态和交接记录，容易把“代码完成”误判为“变更完成”。

现在将 RoadTrip 中验证过的 Codex + OpenSpec + Harness 模式迁移到 Kitchen，可以在不改变产品行为、API、数据 schema 或生产依赖的前提下，把现有工作流升级为可审计、可恢复的执行闭环。

## What Changes

- 在 `docs/Harness/` 建立 monorepo 级 Harness 规则地图，覆盖 OpenSpec、Task 生命周期、代码修改边界、验证等级、Git checkpoint、Task Report 和 Definition of Done。
- 更新根 `AGENTS.md` 与客户端/服务端工作流入口，让 Codex 在任务开始时按影响范围读取最小必要上下文，并明确多个活动 Change 时不得自行猜选。
- 增加适用于 Flutter/Android、Python/FastAPI、共享 contract 和文档工作的 Task 模板、Report 模板与验证矩阵。
- 约定 `DONE`、`PARTIAL`、`BLOCKED`、`FAILED` 的判定、`tasks.md` 勾选条件、Report 证据要求以及服务端学习记录收尾规则。
- 将现有 `docs/client/workflow/CODEX_WORKFLOW.md` 调整为入口和教学材料，规范性执行规则统一链接到 Harness，避免产生竞争事实源。
- 在 `openspec/config.yaml` 增加适用于后续 change 的上下文与 artifact 规则，帮助规划和 apply 阶段保持任务粒度与验证记录一致。
- 不修改应用代码、产品需求、共享 API、数据库 schema、生产依赖或当前工作区已有用户改动。

## Capabilities

### New Capabilities

本变更仅调整工程文档、OpenSpec 元规则和 Codex 执行护栏，不引入应用或产品行为能力，因此通过 `.openspec.yaml` 的 `skip_specs: true` 明确不创建行为 delta spec。

### Modified Capabilities

无。

## Impact

- 影响根 `AGENTS.md`、`client/AGENTS.md`、`server/AGENTS.md`、`docs/client/workflow/CODEX_WORKFLOW.md`、`openspec/config.yaml` 和新增的 `docs/Harness/` 文档。
- 影响后续 OpenSpec change 的 tasks 编写、单 Task 执行、验证和收尾方式；不回写或批量重写已有活动 Change 的任务清单。
- 不新增代码、API、依赖、密钥处理、迁移或外部服务。
- 当前已有未提交的客户端实现与学习记录必须保留，Harness 只增加边界说明，不把它们自动归入本变更或提交。
