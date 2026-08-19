# Kitchen / 厨房手记

厨房手记 monorepo 同时维护移动客户端和未来服务端。产品坚持本地优先：核心菜谱导入、整理、浏览、编辑和查阅不依赖网络，服务端用于账号配置、备份同步、AI 编排和权益等可降级能力。

## 项目

| 目录 | 状态 | 技术 |
| --- | --- | --- |
| [`client/`](client/README.md) | 已开发 | Flutter / Dart / Drift |
| `server/` | 尚未初始化 | 计划采用 Swift / Vapor / PostgreSQL |

## 仓库入口

- [文档导航](docs/README.md)：按 product、contracts、client、server、learning 和 decisions 分区。
- [Codex Harness](docs/Harness/README.md)：OpenSpec Task 的执行、验证、Report 和 Git 现场规则。
- [OpenSpec](openspec/)：所有客户端、服务端和共享变更从仓库根统一规划。
- [Monorepo 约束](AGENTS.md)：先按任务范围选择最小阅读集。

服务端框架初始化和腾讯云部署将分别通过后续 OpenSpec change 实施；当前 `server/` 只保存未来服务端工作的范围指令。

## 当前 V1 实施队列

`client-v1-android-core-scope` 是当前唯一的 V1 收口入口，主线为 Android 无网络、无需登录
的菜谱导入、校对、保存、搜索、查看和编辑。`refocus-mvp-recipe-ocr` 作为 OCR 恢复与草稿
确认的实现主线；iOS Share Extension、Apple/微信/手机号登录和本地备份恢复暂列为 V1 稳定
后的延期队列，不作为当前发布前置条件。
