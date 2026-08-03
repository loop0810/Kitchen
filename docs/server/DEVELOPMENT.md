# 服务端开发与运行

## 配置

所有配置在启动阶段由 Pydantic Settings 的 `Settings` 集中解析：

| 变量 | 必需 | 说明 |
| --- | --- | --- |
| `APP_ENV` | 否 | `development`、`testing`、`production`；默认 `development` |
| `DATABASE_URL` | 是 | `postgresql://` 或 `postgres://` URL |
| `HOST` | 否 | 默认 `127.0.0.1` |
| `PORT` | 否 | 默认 `8080` |
| `LOG_LEVEL` | 否 | 生产默认 `info`，其他环境默认 `debug` |

测试环境额外要求数据库名包含 `test`，这是阻止测试误连普通或生产数据库的最低保护。生产环境只从进程环境或未来的秘密管理设施注入秘密；仓库中的 `.env.example` 只含本地示例值。

配置缺失或格式错误时进程在监听 HTTP 前以非零结果退出，日志只记录稳定错误类别，不记录配置值。数据库运行中不可用时存活仍成功、就绪返回 503，以便负载均衡摘流。

## 依赖与版本

- Python `3.13.14`：本地验证解释器；项目范围固定为 `>=3.13,<3.14`。
- FastAPI `0.141.1` 与 Uvicorn `0.52.1`：ASGI 应用、生命周期和 HTTP 进程入口。
- SQLAlchemy `2.0.51` 与 asyncpg `0.31.0`：异步数据库会话和 PostgreSQL 驱动。
- Alembic `1.18.5`：唯一 schema migration 入口。
- Pydantic Settings `2.14.2`：启动期环境配置解析与校验。
- PostgreSQL `17-alpine`：仅作为本地 Compose 固定镜像；生产部署不在当前 change 范围。

`pyproject.toml` 声明直接依赖和兼容范围，`uv.lock` 锁定完整传递解析。开发、CI 和部署使用 `uv sync --frozen`；升级时重新生成锁文件并执行全部验证，不能只手工修改 `uv.lock`。

## 命令

在 `server/` 运行：

```sh
make format-check
make typecheck
make test
make integration-test
```

`make test` 不连接 PostgreSQL。`make integration-test` 启动端口 5433、名称固定为 `kitchen_test` 的隔离容器，执行空库 upgrade、重复 upgrade、就绪探针和 downgrade。开发库使用 `docker compose up -d --wait postgres`，迁移使用 `make migrate`；发布流程必须在启动应用实例前只执行一次 migration。

## 失败、恢复与回滚

- 依赖解析失败：保留 `pyproject.toml` 与 `uv.lock`，恢复网络后使用 `uv sync --frozen` 重试，不引入全局或未锁定包。
- 配置失败：修正运行环境后重启，不以默认秘密绕过校验。
- migration 失败：停止发布，修复 migration 后在隔离备份副本验证；禁止手工标记已完成。
- 数据库不可用：实例保持非就绪，恢复数据库后探针自动恢复。
- 当前尚无业务表或用户数据。整体回滚可停止服务并移除 `server/`；当前 migration 回滚可使用 `uv run alembic downgrade base`。不得影响 `client/`。
