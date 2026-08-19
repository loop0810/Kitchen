# 服务端文档

## 当前状态

Python/FastAPI 服务端运行时基础位于 `server/`。当前实现覆盖集中配置校验、PostgreSQL/SQLAlchemy/Alembic 迁移、存活与就绪检查、请求关联 ID 和安全错误事件；尚无业务 API 或生产部署。

## 权威范围

本分区面向服务端开发者，负责已实现的服务端架构、模块边界、数据库与迁移、安全控制、运行方式和腾讯云运维。

## 不负责

- Flutter、Figma、端侧 OCR 和本地 UI 状态。
- 产品范围与用户行为。
- 客户端和服务端共享的协议语义；这些由 `docs/contracts` 定义。

## 默认阅读顺序

1. 根 `AGENTS.md`、`server/AGENTS.md` 和 [`../Harness/README.md`](../Harness/README.md)。
2. 当前根 OpenSpec change 的 proposal、spec、design 和 tasks。
3. 本索引及任务涉及的服务端模块文档。
4. 仅在修改共享接口时读取对应 contract。
5. 仅在改变用户行为或版本范围时读取对应 product 文档。
6. 完成服务端 Change 前读取 [`../learning/server/README.md`](../learning/server/README.md) 的学习记录收尾规则。

## 已实现文档

- [服务端架构](ARCHITECTURE.md)：目录边界、依赖方向和请求/数据库数据流。
- [开发运行手册](DEVELOPMENT.md)：环境变量、本地 PostgreSQL、迁移、验证和失败/回滚策略。

腾讯云部署仍作为独立迭代处理。
