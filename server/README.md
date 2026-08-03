# Kitchen Server

厨房手记服务端的 Python/FastAPI 模块化单体。目前只提供配置、PostgreSQL 迁移、健康检查和安全日志基础，不提供业务 API。

## 快速开始

需要 Python 3.13、uv、Docker 和 Docker Compose。

```sh
docker compose up -d postgres
export APP_ENV=development
export DATABASE_URL=postgresql://kitchen:kitchen-local-only@127.0.0.1:5432/kitchen_development
uv sync --frozen
make migrate
make run
```

存活检查为 `GET /health/live`，就绪检查为 `GET /health/ready`。服务端不会自动读取 `.env`，避免本地文件被误当成生产秘密来源。

## 验证

```sh
make format-check
make typecheck
make test
make integration-test
```

`make test` 不连接 PostgreSQL；集成测试只有在显式提供名称含 `test` 的 `TEST_DATABASE_URL` 时才运行。

架构与依赖方向见 [服务端架构](../docs/server/ARCHITECTURE.md)，配置、失败策略与日常命令见 [开发运行手册](../docs/server/DEVELOPMENT.md)。
