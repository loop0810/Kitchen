# Kitchen Harness 项目扩展

Kitchen 的通用 Codex / OpenSpec 生命周期由全局配置和 skill 负责：

- `~/.codex/AGENTS.md`：全局 Harness 导航。
- `~/.codex/skills/harness/SKILL.md`：OpenSpec Change 选择、Task 执行、验证、Report 和停止规则。

本目录不重复定义全局生命周期，只补充 Kitchen 的 Change/Direct 路径下的 monorepo、Flutter/Android、Python/FastAPI、PostgreSQL、共享 contract 和本地工作区规则。若全局 skill 与项目扩展同时出现，项目扩展只负责技术栈事实；发现冲突时暂停并报告，不自行覆盖全局流程。

## 文档分工

| 文档层 | 负责的问题 | 权威位置 |
| --- | --- | --- |
| 产品 / contract / 架构 | 为什么做、用户行为和共享语义 | `docs/product`、`docs/contracts`、`docs/decisions` |
| OpenSpec Change | 当前变更交付什么 | `openspec/changes/<change>/` |
| 全局 Harness | 如何选择 Change 或 Direct、执行 Task、验证、报告和停止 | `~/.codex/AGENTS.md`、全局 `harness` skill |
| Kitchen Harness | 本项目的读取路由、命令、边界和模板 | 本目录 |
| Task Report | 实际修改和验证出了什么 | 当前 Change 的 `reports/<task-id>.md` |

## 使用顺序

1. 由全局 Harness skill 读取项目 `AGENTS.md`、判断 Change Gate，并检查已有修改。
2. 低风险局部任务可走 Direct 路径：只读取相关项目扩展，不创建 Change artifacts，执行最小相关验证。
3. 选择 Change 路径后，明确当前唯一 Change；本仓库有多个活动 Change 时不得按时间或名称猜选。
4. 读取当前 Change 的 `proposal.md`、`design.md`、相关 `specs/` 和 `tasks.md`。
5. 根据影响范围读取本目录的项目扩展：
   - 客户端/服务端读取和边界：[code-change-rules.md](code-change-rules.md)
   - 命令和验证等级：[validation-rules.md](validation-rules.md)
   - 需要创建/更新 Report 时使用：[task-report-template.md](task-report-template.md)
   - OpenSpec、Task、完成条件、Git 和通用模板遵循全局 `harness` skill 的 references。
6. Change 模式开始实现前确认 Task 的 Scope、Out of Scope、Acceptance Criteria、依赖和 Validation Level；结束后按全局 skill 与本项目 Report 模板记录真实结果。Direct 模式只报告实际修改和最小验证结果。

## Kitchen 项目硬约束

- Change 模式的变更使用根 `openspec/`；Task 唯一来源仍是当前 Change 的 `tasks.md`。Direct 模式不创建 proposal、design/specs、tasks 或 Task Report。
- Feature、Domain、Data、平台适配、根 App 和服务端模块边界以各自 `AGENTS.md` 与权威文档为准。
- 共享请求、响应、标识符、错误、幂等、版本和同步语义必须先读取对应 contract，并检查两端边界。
- 用户可见行为或版本范围变化必须读取 product 路由并记录决策。
- 当前工作区可能已有用户修改；不得自动清理、回滚、覆盖或提交未授权改动。
- 未执行的客户端、服务端、数据库、设备或链接检查必须按 `NOT RUN` 记录，不能写成通过。

## 项目扩展地图

| 文档 | 作用 |
| --- | --- |
| [code-change-rules.md](code-change-rules.md) | 客户端、服务端、文档和生成文件的修改边界 |
| [validation-rules.md](validation-rules.md) | Flutter/Android、FastAPI/PostgreSQL 和共享变更的验证命令 |
| [task-report-template.md](task-report-template.md) | 需要创建/更新 Report 时使用的项目证据模板 |
