## Why

当前全局 Harness 将所有仓库修改都强制纳入 OpenSpec Change，导致低风险的资源替换、局部样式修正和测试修复也要经过完整的 proposal、spec、tasks、Report 和重验证流程。需要把“是否创建 Change”交还给开发者，同时保留对产品、契约、架构和跨文件工作流变更的完整追踪能力。

## What Changes

- 在全局 Harness 中增加开发者可控的 Change Gate：不再仅因仓库存在 `openspec/` 就强制创建 Change。
- 增加轻量直接实施路径，适用于低风险、局部、无产品/契约/架构语义变化的修改。
- 明确 `change`、`direct` 和未明确时的决策规则，避免 Agent 擅自创建 Change 或绕过开发者意图。
- 为轻量路径定义最小验证要求：只运行与修改范围相关的格式、静态、单元/Widget 或结构检查，不默认执行完整套件、设备流程或截图验证。
- 同步更新 Kitchen 的 Harness 文档，消除“所有修改必须使用根 OpenSpec”与轻量路径之间的冲突。
- 保留完整 OpenSpec 生命周期、Task 唯一来源、Report 和高风险变更追踪能力。

## Capabilities

### New Capabilities

- `harness-change-gate`: 定义开发者如何选择完整 Change 流程或低风险轻量实施流程，以及两条路径的验证边界。

### Modified Capabilities

- 无。

## Impact

- 全局规则：`~/.codex/AGENTS.md` 和 `~/.codex/skills/harness/SKILL.md`。
- Kitchen 项目规则：根 `AGENTS.md`、`docs/Harness/README.md`、`docs/Harness/code-change-rules.md` 和 `docs/Harness/validation-rules.md` 的相关表述。
- 不修改 OpenSpec CLI、schema、现有 Change artifact、客户端代码或服务端代码。
- 全局规则文件位于 Kitchen 仓库之外，不会作为本仓库提交内容；本 Change 仅记录其变更契约和验证结果。
