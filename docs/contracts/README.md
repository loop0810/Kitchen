# 跨端契约

## 权威范围

本分区面向客户端和服务端开发者，唯一权威定义双方共同依赖的请求与响应语义、稳定标识符、版本、错误、幂等、同步和服务端权威状态。

## 不负责

- 产品目标和页面行为。
- Flutter 缓存、Riverpod 或 Drift 实现。
- Vapor Controller、ORM 和部署实现。

## 契约目录

| 契约 | 适用场景 |
| --- | --- |
| `PERSONALIZATION_SYNC_CONTRACT.md` | 个性化分类、标签、难度配置及 revision/pending 同步 |
| `AI_REQUEST_CONTRACT.md` | 未来 AI 请求、幂等、额度预留和结果查询 |
| `ENTITLEMENT_CONTRACT.md` | AI Credit、模板权益和服务端权威账本 |
| `BACKUP_SYNC_CONTRACT.md` | 版本化备份、恢复安全和未来多设备冲突原则 |

新增共享字段前先确认现有契约不能承载。规范性定义只写一次；单端文档和学习记录使用链接，不复制另一份权威描述。

当前尚未确定通用 HTTP 路径、JSON 命名、鉴权和错误 envelope。它们应由首个服务端 API OpenSpec change 决定，不能从客户端内部模型反推为正式网络协议。
