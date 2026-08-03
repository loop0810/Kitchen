# 服务端架构

## 当前边界

服务端是单一 Python 应用的模块化单体，当前只建立运行时基础：

```text
main（Uvicorn 进程入口）
  ↓
app（FastAPI 装配、路由、中间件）
  ↓                         ↓
domain（稳定端口） ← infrastructure（配置、PostgreSQL）
                                  ↓
                 SQLAlchemy / asyncpg / PostgreSQL
```

`domain` 不依赖 FastAPI、SQLAlchemy 或数据库。`infrastructure` 实现领域端口；`app.factory` 只在装配根选择适配器；`main` 负责配置校验和 Uvicorn 进程生命周期。未来业务模块应在领域端口上表达需求，不允许 handler 直接创建数据库连接或外部客户端。

数据库通过应用 state 注入，未来 handler 使用 `get_database_session` 获得按请求隔离的 `AsyncSession`。会话发生异常时回滚，请求结束后释放；不得跨请求共享事务状态。

## HTTP 基线

- `GET /health/live` 只说明进程仍能处理 HTTP。
- `GET /health/ready` 查询运行时 metadata 表以同时检查连接和 migration 状态；失败统一返回不透明的 503。
- `X-Request-ID` 只接受最长 64 字符的 ASCII 字母、数字、`-_.`，否则生成 UUID。
- 错误事件名固定为 `request_failed`，字段只允许 `request_id`、`status` 和 `error_category`。请求正文、认证头、手机号和底层异常文本不进入事件。

## 持久化

Alembic migration 是 schema 的唯一演进入口。首个 `20260803_0001_runtime_metadata` migration 只验证空库、重复执行和回滚机制，不承载业务数据。migration 在发布准备阶段只执行一次，Uvicorn worker 不自动迁移。PostgreSQL 是约束语义的最终验证后端；单元测试替身不能替代 PostgreSQL 集成测试。
