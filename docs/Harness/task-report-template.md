# Kitchen OpenSpec Task Report Template

全局 Harness 负责何时创建和更新 Report；本模板定义 Kitchen 需要记录的客户端、服务端、共享 contract 和 Git 证据。Report 存放于：

```text
openspec/changes/<change-name>/reports/<task-id>.md
```

```markdown
# <change-name> / <task-id>: <Task Name>

- Status: <IN_PROGRESS | DONE | PARTIAL | BLOCKED | FAILED>
- Validation Level: <Structural | Behavior | Critical>
- Completed At: <YYYY-MM-DD HH:mm，Asia/Shanghai>
- OpenSpec Task: <tasks.md 中的原生 Task ID>

## Result

<实际结果，不重新定义任务目标。>

## Observable Behavior

- 用户/客户端能观察到：<行为或 NOT APPLICABLE>
- 服务端/共享语义能观察到：<HTTP、数据库、状态或 contract 结果，或 NOT APPLICABLE>
- 失败、恢复和幂等：<策略与结果>
- Reset / 复现：<操作、环境和恢复内容>

## Changed Files

- `<path>` — <修改内容>

## Acceptance Criteria

- [x] <已满足的条件>
- [ ] <未满足的条件及原因>

## Validation

- 文档/OpenSpec：<PASS / FAIL / NOT RUN，附命令或范围>
- 客户端格式/分析/测试：<PASS / FAIL / NOT RUN，附命令>
- Android/iOS/模拟器/设备：<PASS / FAIL / NOT RUN，附场景>
- 服务端 lock/format/type/test：<PASS / FAIL / NOT RUN，附命令>
- PostgreSQL/集成验证：<PASS / FAIL / NOT RUN，附数据库与环境前提>
- 共享 contract/跨端一致性：<PASS / FAIL / NOT RUN，附请求或语义>
- Git 现场/checkpoint：<状态、归属检查和是否创建>

## Deviations

- <无，或记录范围/设计偏差>

## Remaining Issues

- <无，或记录遗留问题、风险和阻塞>

## Next Task Context

<下一任务需要知道的事实、未完成验证或解除阻塞条件。>
```

Report 必须记录真实结果。不能把手动验收写成自动化测试，不能把未执行的命令写成通过，也不能用 Report 改写当前 Task 的 Scope 或验收标准。
