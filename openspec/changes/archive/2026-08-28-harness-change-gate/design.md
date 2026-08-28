## Context

参见 `proposal.md` 的 Why 和 Impact。当前全局 `~/.codex/AGENTS.md` 与 `~/.codex/skills/harness/SKILL.md` 将 OpenSpec 仓库的所有修改统一导向完整 Change；Kitchen 的 `AGENTS.md` 和 `docs/Harness/` 又把 OpenSpec 作为所有变更的入口，因此简单资源替换也会触发完整规划和重验证。

本次调整影响两类规则：全局 Agent 如何选择执行路径，以及 Kitchen 如何描述本地边界和验证。OpenSpec CLI 的 schema 配置不负责 Agent 的模式选择，因此不在 CLI 配置中伪造一个不存在的开关。

## Goals / Non-Goals

**Goals:**

- 让开发者可以明确选择 `change` 或 `direct`。
- 对未声明模式的低风险局部工作默认采用轻量路径。
- 对高风险、跨边界或不明确的工作先提示开发者，不自动创建 Change。
- 保留完整 Change 生命周期和高风险工作的可追踪性。
- 在全局规则和 Kitchen 文档中使用同一套 Change Gate 术语和验证边界。

**Non-Goals:**

- 不修改 OpenSpec CLI、schema 或现有 Change artifact。
- 不删除 tasks、Report、真实验证和单 Task 停止规则。
- 不允许 direct mode 默默扩大到产品、共享契约、架构、数据、安全或外部服务范围。
- 不为每种低风险操作增加独立配置文件或环境变量。

## Decisions

### 1. 使用显式执行模式，而不是仓库存在性作为触发条件

执行入口分为 `change` 和 `direct` 两种模式。开发者明确指定时，Agent 必须遵守；未指定时，低风险局部工作默认 direct，边界不清或跨边界工作先请求决定。这样 OpenSpec 仍然可用，但不再把仓库元数据误当成每个修改都必须走完整流程的授权。

替代方案：继续以 `openspec/` 是否存在作为唯一触发器。该方案实现简单，但正是本次低风险任务耗时过高的原因，因此不采用。

### 2. 将轻量模式写入全局规则和 Skill，而不是 openspec/config.yaml

`~/.codex/AGENTS.md` 负责全局入口判断，`~/.codex/skills/harness/SKILL.md` 负责两条路径的执行动作。Kitchen 的 `AGENTS.md` 与 `docs/Harness/` 只描述项目级补充和验证矩阵。`openspec/config.yaml` 继续只负责 spec-driven artifact 规则。

替代方案：增加 `lightweight: true` 或 `change_required: false` 的 OpenSpec YAML 字段。当前 CLI 不消费此字段，容易制造“配置已生效”的假象，因此不采用。

### 3. Direct mode 只保留风险匹配的最小验证

Direct mode 默认执行 `git diff --check`、相关格式检查、静态分析和受影响的单元/Widget/结构检查；完整测试、设备流程、截图和跨端验证只在修改风险或开发者要求确实需要时执行。若实现过程中范围扩大，Agent 必须停下并建议切换 Change，而不是用 direct mode 绕过规划。

### 4. 高风险任务由开发者最终决定，但 Agent 必须明确提示

产品行为、共享契约、架构边界、跨文件工作流、数据迁移、安全和外部服务属于 Change 推荐范围。未明确模式时，Agent 不能静默选择；开发者可以明确选择 Change，也可以在了解影响后明确要求 direct，后者需在结果中记录范围和风险。

### 5. 全局文件与仓库文档分开管理

全局规则文件位于用户配置目录，不属于 Kitchen Git 仓库；本 Change 在 Kitchen 中记录契约、设计和验证，实际全局文件修改作为外部工作区变更单独确认。Kitchen 文档同步更新，避免本地说明继续要求所有修改都必须有 Change。

## Risks / Trade-offs

- [Risk] 低风险判断可能遗漏隐含的跨边界影响 → 对不明确任务先询问；在 direct 实施中发现范围扩大时立即停止并建议切换 Change。
- [Risk] 全局规则更新会影响其他仓库 → 规则只改变 Change 的进入判定，不改变已选择 Change 的执行约束；变更后使用全局文件内容检查和 Kitchen 文档校验。
- [Risk] 轻量验证可能遗漏需要设备才能发现的视觉问题 → 仅对不需要真实布局判断的低风险改动跳过设备；用户明确要求视觉验收或任务改变布局时仍执行设备/截图检查。
- [Risk] 全局 Skill 与项目 AGENTS 再次出现冲突 → 使用统一术语 `change/direct/轻量路径`，并在 Kitchen Harness 文档中明确全局入口与项目补充的职责。

## Migration Plan

1. 更新全局 `~/.codex/AGENTS.md` 和 `~/.codex/skills/harness/SKILL.md`，加入 Change Gate 与 direct mode。
2. 更新 Kitchen 根 `AGENTS.md` 和 `docs/Harness/` 中“所有变更必须使用 OpenSpec”的冲突表述。
3. 运行 OpenSpec 严格校验、文档链接/结构检查和受影响规则文件检查。
4. 后续任务按新 Gate 运行；现有活动 Change 不迁移、不重写、不改变状态。
5. 若新规则导致误判，回滚全局规则和 Kitchen 文档的对应段落即可，不涉及应用运行时数据。

## Open Questions

无。模式选择和轻量验证边界已在本设计中确定。
