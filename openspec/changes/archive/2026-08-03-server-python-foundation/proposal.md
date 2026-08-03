## Why

仓库尚无已验证可运行的服务端工程，而账号、会话和后续云端能力需要一个可运行、可迁移、可观测且不会泄露密钥的服务端基础。先独立建立 Python/FastAPI 模块化单体，可以避免在首个登录方式中临时决定工程和运维边界，并降低依赖获取与第三方服务集成门槛。

## What Changes

- 在 `server/` 使用 Python 3.13、FastAPI 和 Uvicorn 初始化模块化单体，并通过 uv 管理和锁定依赖。
- 使用 SQLAlchemy、asyncpg 和 Alembic 建立 PostgreSQL 连接与迁移入口，并建立健康检查、结构化日志和环境变量密钥注入。
- 建立模块、HTTP、持久化和外部适配器的依赖方向，不在本 change 实现登录业务。
- 补充服务端工程文档、验证命令和首轮学习记录要求。

## Capabilities

### New Capabilities

- `server-runtime-foundation`：定义服务端可启动、可配置、可迁移、可观测和安全失败的基础运行能力。

### Modified Capabilities

无。

## Impact

- 以 Python/FastAPI 工程替换 `server/` 中尚未验证完成的 Swift/Vapor 草案，并新增服务端测试与运行入口。
- 更新 `server/AGENTS.md`、`docs/server/README.md` 及相关架构、开发运行和安全文档。
- 引入 FastAPI、Uvicorn、SQLAlchemy、asyncpg、Alembic 和 Pydantic Settings 等首批生产依赖；不新增业务 API 或用户数据表。
