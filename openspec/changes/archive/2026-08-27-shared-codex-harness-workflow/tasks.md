## 1. Harness 规范与模板

- [x] 1.1 建立 monorepo Harness 规则地图与 OpenSpec 执行边界
  - Validation Level: Structural
  - Goal: 让 Codex 能从一个入口理解 OpenSpec、Task、Report 和验证职责
  - Scope: `docs/Harness/README.md`、`openspec-rules.md`、`task-workflow.md`、`code-change-rules.md`
  - Out of Scope: 产品需求、共享 contract、客户端或服务端生产代码
  - Acceptance Criteria:
    - [ ] 明确 OpenSpec 是任务唯一来源，Harness 不复制任务清单
    - [ ] 明确多个活动 Change 时不得猜选，需求/设计冲突时先暂停
    - [ ] 明确开始、执行、验证、收尾和停止条件
  - Reset / Verification: 检查文档内部链接、范围描述与根/端侧 AGENTS 不冲突

- [x] 1.2 建立验证、完成判定、Git 和 Task Report 模板
  - Validation Level: Structural
  - Goal: 为 Flutter/Android、FastAPI/PostgreSQL、共享 contract 和文档任务提供可复用执行格式
  - Scope: `validation-rules.md`、`definition-of-done.md`、`git-rules.md`、`task-template.md`、`task-report-template.md`
  - Out of Scope: 自动化提交工具、CI workflow、既有 Change 的批量任务迁移
  - Acceptance Criteria:
    - [ ] 定义 Structural、Behavior、Critical 三档验证及端侧最低命令
    - [ ] 只有验收、真实验证和 Report 完整时才能勾选 `[x]`
    - [ ] 明确 `DONE`、`PARTIAL`、`BLOCKED`、`FAILED`，并禁止伪造未执行验证
    - [ ] 明确脏工作区归属检查和不自动清理/提交规则
  - Reset / Verification: 用一个客户端任务、一个服务端任务和一个共享任务分别走读模板字段

## 2. 项目导航与教学入口

- [x] 2.1 更新根入口和 OpenSpec 配置
  - Validation Level: Structural
  - Goal: 把 Harness 纳入 monorepo 默认导航和后续 OpenSpec artifact 规则
  - Scope: 根 `AGENTS.md`、根 `README.md`、`docs/README.md`、`openspec/config.yaml`
  - Out of Scope: 修改当前活动 Change 的 proposal、design、spec 或 tasks 内容
  - Acceptance Criteria:
    - [ ] 根入口能指向 Harness，并保留现有 docs 任务矩阵与条件读取规则
    - [ ] `openspec/config.yaml` 的上下文和 artifact 规则与 Harness 一致
    - [ ] 不把端侧命令、产品事实或 contract 复制成新的权威定义
  - Reset / Verification: 运行 `openspec list --json`，检查五个既有活动 Change 仍可发现

- [x] 2.2 更新客户端工作流入口并接入 Flutter/Android 约束
  - Validation Level: Structural
  - Goal: 保留学习性内容，同时把客户端执行规范路由到 Harness 和现有端侧 AGENTS
  - Scope: `client/AGENTS.md`、`client/README.md`、`docs/client/README.md`、`docs/client/workflow/CODEX_WORKFLOW.md`
  - Out of Scope: 修改 Flutter 源码、客户端产品行为或现有验证脚本
  - Acceptance Criteria:
    - [ ] 明确客户端任务开始前读取当前 Change、相关文档和专项 AGENTS
    - [ ] 明确格式、分析、测试、Android/模拟器验收的分级关系
    - [ ] 教学示例不再与 Harness 维护竞争性的任务状态或 DoD
  - Reset / Verification: 检查文档相对链接，并用现有客户端命令做只读可执行性核对

- [x] 2.3 更新服务端工作流入口并接入学习记录收尾
  - Validation Level: Structural
  - Goal: 让服务端任务使用同一套 Scope/Report/验证规则，同时保留 PostgreSQL 与学习记录专属约束
  - Scope: `server/AGENTS.md`、`server/README.md`、`docs/server/README.md`、`docs/learning/server/README.md`
  - Out of Scope: 新增 API、数据库迁移、Docker 配置或服务端业务代码
  - Acceptance Criteria:
    - [ ] 明确服务端 change 收尾必须有学习记录或有理由的豁免
    - [ ] 保留 `make lock-check`、`make format-check`、`make typecheck`、`make test` 和集成测试边界
    - [ ] 服务端内部任务默认不加载客户端/Figma/完整产品文档
  - Reset / Verification: 检查服务端文档链接、命令与现有 `server/AGENTS.md` 一致

## 3. 一致性验证与交付记录

- [x] 3.1 走读并验证 Harness 与现有仓库现场的兼容性
  - Validation Level: Structural
  - Goal: 证明新增规则不会覆盖用户未提交修改、隐藏活动 Change 或制造 stale 路径
  - Scope: 当前 change 全部文档、根 OpenSpec 状态、Git diff 和仓库内 Harness 引用
  - Out of Scope: 提交当前工作区、执行客户端构建、执行服务端集成测试、修改既有活动 Change
  - Acceptance Criteria:
    - [ ] `git status --short` 中已有文件仍未被本 change 改写或归类为本 change 成果
    - [ ] `openspec status --change shared-codex-harness-workflow` 显示 proposal/design/tasks 完整且 specs 明确 skipped
    - [ ] OpenSpec validate、Markdown/相对链接检查和 `git diff --check` 通过
    - [ ] Report 或最终说明记录未运行的应用验证及后续采用方式
  - Reset / Verification: 只读检查 `git status`、`git diff --stat`、OpenSpec 状态和链接扫描结果
