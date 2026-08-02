# 产品文档

## 权威范围

本分区面向产品、客户端和服务端开发者，定义产品方向、当前版本范围、用户行为和菜谱领域语义。发生需求冲突时，以对应专项权威文档为准，并通过 OpenSpec 变更记录调整。

## 不负责

- Flutter Widget、状态管理和本地数据库实现。
- Vapor 路由、数据库表和腾讯云部署。
- HTTP 字段与错误格式；这些由 `docs/contracts` 定义。

## 阅读路由

| 任务 | 必读 | 条件阅读 |
| --- | --- | --- |
| 产品方向 | `PRODUCT_REQUIREMENTS.md` | `../decisions/DECISION_LOG.md` |
| 当前版本范围 | `MVP_REQUIREMENTS.md` | 相关专项需求 |
| 菜谱行为 | `RECIPE_REQUIREMENTS.md` | `MVP_REQUIREMENTS.md`、相关 contract |

产品行为或版本范围没有变化时，单端实现任务不默认读取本分区全文。
