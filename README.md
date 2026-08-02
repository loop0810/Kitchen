# Kitchen / 厨房手记

厨房手记 monorepo 同时维护移动客户端和未来服务端。产品坚持本地优先：核心菜谱导入、整理、浏览、编辑和查阅不依赖网络，服务端用于账号配置、备份同步、AI 编排和权益等可降级能力。

## 项目

| 目录 | 状态 | 技术 |
| --- | --- | --- |
| [`client/`](client/README.md) | 已开发 | Flutter / Dart / Drift |
| `server/` | 尚未初始化 | 计划采用 Swift / Vapor / PostgreSQL |

## 仓库入口

- [文档导航](docs/README.md)：按 product、contracts、client、server、learning 和 decisions 分区。
- [OpenSpec](openspec/)：所有客户端、服务端和共享变更从仓库根统一规划。
- [Monorepo 约束](AGENTS.md)：先按任务范围选择最小阅读集。

服务端框架初始化和腾讯云部署将分别通过后续 OpenSpec change 实施；当前 `server/` 只保存未来服务端工作的范围指令。
