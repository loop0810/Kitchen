# harness-change-gate Specification

## Purpose

为 Codex 提供开发者可控的变更入口：低风险局部修改可以快速直接实施，涉及产品、契约、架构或跨文件工作流的变更仍可通过完整 OpenSpec 生命周期获得可追踪的规划、验证和报告。

## Requirements

### Requirement: Change creation is controlled by developer intent

Agent SHALL NOT create an OpenSpec Change solely because the repository contains `openspec/` or `openspec/config.yaml`. The Agent MUST honor an explicit developer instruction to use `change` or `direct` mode. When no mode is stated, low-risk local work MAY use direct mode by default; ambiguous or materially cross-boundary work MUST be surfaced to the developer before modification.

#### Scenario: Developer explicitly requests a Change

- **WHEN** 开发者明确要求创建、选择或继续 OpenSpec Change
- **THEN** Agent 使用完整 Change 生命周期，并从当前 Change 的 tasks.md 选择任务实施

#### Scenario: Developer explicitly requests direct mode

- **WHEN** 开发者明确要求直接修改且不创建 Change
- **THEN** Agent 不创建 OpenSpec artifact，直接在声明的范围内实施，并执行轻量路径要求的验证

#### Scenario: Low-risk work has no explicit mode

- **WHEN** 任务是局部资源替换、单文件样式修正、文案调整、格式化或针对性测试修复，且不改变产品、契约、架构或跨文件工作流语义
- **THEN** Agent 默认采用 direct mode，不要求开发者先创建 Change

#### Scenario: Cross-boundary work has no explicit mode

- **WHEN** 任务可能改变产品行为、共享契约、架构边界、跨文件工作流、数据迁移、安全边界或外部服务
- **THEN** Agent 先向开发者说明完整 Change 的必要性并请求决定，不得自行创建 Change 或直接修改实现

### Requirement: Direct mode uses bounded lightweight validation

Direct mode SHALL keep the implementation scope explicit and SHALL run only checks relevant to the changed files and risk. It MUST NOT automatically require proposal、design、spec、tasks、Task Report、完整测试套件、设备流程或截图验证。

#### Scenario: Direct asset or style change completes

- **WHEN** 低风险资源或样式修改完成
- **THEN** Agent 至少执行适用的 diff/结构检查和相关格式、静态或针对性测试，并在回复中简要记录实际命令和结果

#### Scenario: Direct change expands scope

- **WHEN** 直接实施过程中发现需要改变产品语义、共享接口、架构边界或多个独立模块的工作流
- **THEN** Agent 停止扩大修改，向开发者建议切换到 Change mode

### Requirement: Change mode retains full traceability

当开发者选择 Change mode 时，Agent SHALL 保留现有 OpenSpec 生命周期、tasks.md 作为唯一任务来源、Task Report、真实验证证据和按 Task 停止规则；轻量路径不得削弱已选择 Change 的约束。

#### Scenario: Existing Change is selected

- **WHEN** 开发者指定一个活动 Change
- **THEN** Agent 读取该 Change 的规划 artifact，按单个 Task 实施、验证、更新 Report 和任务状态

#### Scenario: Multiple active Changes exist

- **WHEN** 未明确 Change 且任务不能安全归类为 direct mode
- **THEN** Agent 不按最近修改时间猜选 Change，而是请求开发者指定或确认创建新的 Change
