## Context

当前 monorepo 已经把客户端、服务端和共享文档分层，并把所有变更集中到根 `openspec/`。根级与端侧 `AGENTS.md` 能告诉 Codex 应该读取哪些资料，但它们没有形成统一的 Task 执行协议：活动 Change 可以同时存在，tasks 目前主要是复选框，验证命令分散在端侧说明中，失败和部分完成没有固定记录位置。

本设计迁移 RoadTrip 已验证的 OpenSpec + Harness 分层，但适配 Kitchen 的 Flutter/Android、Python/FastAPI、共享 contract 和本地优先产品边界。变更只涉及规范文档、导航、OpenSpec 配置和模板；当前工作区已有未提交的客户端改动，不能通过清理、回滚或自动提交来建立“干净基线”。

## Goals / Non-Goals

**Goals:**

- 让每个后续 Task 都有可追踪的 Change、Scope、Out of Scope、Acceptance Criteria、Validation Level 和 Report。
- 将 OpenSpec 的需求与设计权威、Harness 的执行规则、Task Report 的实际证据和 Git 的回溯职责分开。
- 为客户端、服务端、共享 contract、产品行为和文档维护建立最小读取路由与升级触发器。
- 让验证规则覆盖 Flutter/Android、FastAPI/PostgreSQL、跨端 contract 和文档/OpenSpec 校验。
- 保留当前活动 Change、现有任务格式和用户未提交修改，不要求为了套用模板而批量重写历史任务。

**Non-Goals:**

- 不改变任何产品行为、API 契约、数据库 schema、登录/同步语义或版本范围。
- 不实现新客户端、服务端或基础设施功能，不新增生产依赖或外部服务。
- 不替用户选择多个活动 Change 中的“当前 Change”，不自动提交、清理或回滚工作区。
- 不把 Harness 文档变成第二套产品需求、contract 或任务清单。

## Decisions

### 1. Harness 作为 `docs/Harness/` 下的执行规范，根 AGENTS 只做路由

新增 `docs/Harness/`，由 `README.md`、`openspec-rules.md`、`task-workflow.md`、`code-change-rules.md`、`validation-rules.md`、`definition-of-done.md`、`git-rules.md`、`task-template.md` 和 `task-report-template.md` 组成。根 `AGENTS.md` 保留范围判断和条件读取，链接到 Harness；`docs/client/workflow/CODEX_WORKFLOW.md` 保留学习、界面分工和示例，规范性规则改为引用 Harness。

备选方案是把所有规则继续堆在根 `AGENTS.md` 中，但这会让每个任务默认携带过多流程细节，也无法清晰区分导航、规范和教学内容。

### 2. OpenSpec 是唯一任务来源，Harness 不复制任务清单

当前 Task 必须来自唯一明确的 `openspec/changes/<change>/tasks.md`。Harness 只定义如何读取、开始、执行、验证和收尾，不维护第二份任务列表。现有 `tasks.md` 继续支持原生 `[ ]` / `[x]`；中间状态存放在 `reports/<task-id>.md`，只有 Report 为 `DONE` 且验收与验证完整时才勾选 `[x]`。

备选方案是建立独立 Harness 任务队列，但它会和 OpenSpec 产生竞争事实源，并让任务状态在多个文件之间漂移。

### 3. 用 Report 承载状态和证据，不伪造验证结果

每个执行过的 Task 都可以在当前 Change 下创建 `reports/<task-id>.md`，记录状态、实际修改文件、Acceptance Criteria、命令与结果、偏差、遗留问题和下一任务上下文。`DONE`、`PARTIAL`、`BLOCKED`、`FAILED` 的定义固定在 Definition of Done；未执行的命令必须标记 `NOT RUN`，手动运行不能写成自动化测试。

这样既能保留失败现场，又不强迫所有未开始的历史任务批量生成空 Report。

### 4. Git 规则采用“现场归属 + 可选 checkpoint”，不假设工作区干净

开始 Task 前记录 `git status --short`，按文件或路径区分既有现场、当前 Task 和范围外修改。Harness 禁止使用破坏性清理命令，也不自动提交。若用户明确要求建立 checkpoint，提交信息使用 `<change>/<task-id>` 标识，并只提交可归属文件；如果工作区混有未归属改动，则先报告或采用显式路径暂存。

备选方案是每个 Task 自动提交并要求工作区干净，但不适合当前已有未提交实现，也会超出 Codex 在普通任务中的提交授权。

### 5. 验证等级按受影响边界组合，而不是只按端分类

- `Structural`：目录、类型、接口、配置、文档和静态结构；客户端至少运行格式/分析与相关测试，服务端至少运行锁文件、格式、类型检查和单元测试中的适用项。
- `Behavior`：用户交互、导入状态、导航、持久化恢复、平台桥接和 HTTP 行为；除结构检查外，必须执行相关 Flutter/Android、服务端运行或集成验证，并记录真实观察。
- `Critical`：数据库迁移、认证/授权、幂等、同步、备份恢复、删除策略和跨端一致性；必须同时有自动化测试、边界验证和必要的运行时/集成验证。

共享 contract、用户可见行为、版本范围、安全、迁移和跨端边界会提升读取范围和验证范围；单端内部任务不默认读取另一端文档。

### 6. 多个活动 Change 时停止猜选，服务端收尾连接学习记录

当 `openspec list` 显示多个活动 Change，Codex 必须依据用户明确的 Change 名称或当前会话上下文确认，不得把最近修改的 Change 当作当前任务。服务端 Change 在归档前继续遵守 `docs/learning/server/README.md`：创建学习记录或在 tasks/Report 中写明无学习增量豁免；Harness 只规定触发和证据，不复制学习模板内容。

### 7. OpenSpec config 只补充通用元规则

根 `openspec/config.yaml` 增加项目上下文和 artifact 规则，约束新 Change 的 proposal 要写 Non-goals、tasks 要包含 Scope/Out of Scope/Acceptance Criteria/Validation Level，并提示保持任务小而可验证。它不替代 `AGENTS.md`、产品文档、contract 或 Harness，也不修改既有 Change 的内容。

## Risks / Trade-offs

- **[风险] Harness 与 AGENTS 或端侧 README 出现重复且互相冲突的命令** → 将 Harness 定位为执行规范，端侧只保留项目命令与架构边界；发现冲突时以更近的专项 `AGENTS.md` 和权威 contract 为准，并在 Harness 中链接而不复制完整事实。
- **[风险] Report 增加文档负担** → 只要求执行过的 Task 使用 Report，提供短模板；历史任务不批量补空报告。
- **[风险] 任务状态被错误勾选** → Definition of Done 明确 `[x]` 需要 Report、验收和验证全部完成；`PARTIAL`、`BLOCKED`、`FAILED` 保留未勾选。
- **[风险] 脏工作区导致 checkpoint 混入无关改动** → 开始前记录状态、按路径核对差异，默认不自动提交；Report 记录无法归属的文件。
- **[风险] 共享变更只验证一端** → 将共享字段、错误、幂等、同步和版本触发器写入读取矩阵，并要求两端受影响边界都出现在 Validation 计划中。
- **[权衡] 规则数量增加** → 通过根 `AGENTS.md` 的导航和 `docs/Harness/README.md` 的按任务入口控制上下文，不要求每个任务读取全部 Harness。

## Migration Plan

1. 新增 Harness 规则、模板和 README，先完整表达 OpenSpec、Task、Report、验证和 Git 约束。
2. 更新根 `AGENTS.md`、`client/AGENTS.md`、`server/AGENTS.md`，补充 Harness 路由与现有端侧命令，不改产品或代码边界。
3. 更新 `docs/client/workflow/CODEX_WORKFLOW.md` 为学习入口，去除与 Harness 竞争的规范性描述并保留适合初学者的示例。
4. 更新 `openspec/config.yaml`，运行 OpenSpec change 状态/验证以及文档路径检查。
5. 不迁移或批量改写既有活动 Change；从本变更完成后创建的新 Change 开始采用模板，旧 Change 仅在自然修改时补充字段。

回滚只需按文件恢复新增导航和配置变更；不涉及应用数据、数据库、远端资源或生成文件。
