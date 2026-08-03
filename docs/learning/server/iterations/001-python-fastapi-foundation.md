# 001 Python/FastAPI 运行时基础

> OpenSpec change：`server-python-foundation`  
> 完成日期：2026-08-03

## 本轮目标

以 Python 3.13 和 FastAPI 建立可重复启动、迁移、探测和安全失败的模块化单体基线，并用真实 PostgreSQL 验证 migration 约束。本轮不包含账号、同步、短信或生产部署。

## 前置概念

- FastAPI/Starlette 的 ASGI 中间件顺序与 lifespan 生命周期。
- Pydantic Settings 的环境输入、`SecretStr` 和启动期校验。
- SQLAlchemy 2 的异步 engine、按请求 `AsyncSession` 与连接释放。
- Alembic 的 upgrade/downgrade、版本表和发布前单次迁移原则。
- Uvicorn 进程、Docker Compose 健康检查和负载均衡就绪探针。

## 架构与数据流

```text
Uvicorn
  ↓
Request ID → Safe error boundary → FastAPI health routes
                                      ↓
                              readiness domain port
                                      ↓
                         SQLAlchemy async adapter
                                      ↓
                                  PostgreSQL
```

领域层只定义就绪端口，不依赖 FastAPI 或 SQLAlchemy。装配根创建数据库适配器并通过应用 state 提供按请求会话；Alembic 独立于 Uvicorn worker 执行，避免多进程并发迁移。

## 实现顺序及原因

先固定 Python 3.13、直接依赖和 `uv.lock`，避免代码建立在不可重复环境上；随后完成配置和数据库端口，使健康检查可以围绕真实依赖编写。HTTP 中间件和安全日志在路由之后接入，并用注入式 recorder 验证日志字段白名单。最后才运行 PostgreSQL migration 往返验证和更新长期文档，使文档记录实际结果。

## 契约与数据库变化

- 共享 HTTP/业务契约：无；健康端点仍属于服务端运行时内部接口。
- Migration：[20260803_0001_runtime_metadata.py](../../../../server/migrations/versions/20260803_0001_runtime_metadata.py)
- OpenSpec capability：[server-runtime-foundation](../../../../openspec/specs/server-runtime-foundation/spec.md)

## 验证方法

- `uv lock --check`：锁文件与 `pyproject.toml` 一致。
- `ruff format --check .` 与 `ruff check .`：格式和 lint 通过。
- `mypy src tests`：严格类型检查通过。
- `pytest -m "not integration"`：13 个配置、健康、中间件和日志测试通过。
- `pytest -m integration`：真实 PostgreSQL 17 上的空库 upgrade、重复 upgrade、就绪探针和 downgrade 通过。
- 配置失败测试确认只输出稳定类别；错误请求测试确认令牌、密钥、完整手机号和菜谱正文不进入事件。

## 遇到的问题与修正

- SwiftPM 首次解析依赖长期停在 GitHub 仓库获取，且没有生成锁文件；在业务 API 和用户数据出现前切换到 PyPI/uv，降低了当前项目的依赖获取门槛。
- 本机缺少 Python 3.13 和 uv，补齐工具后将 uv 缓存显式放入临时目录，避免自动化环境依赖用户级可写目录。
- macOS 大小写不敏感导致新 `tests/` 合并进旧 `Tests/`，通过两步目录迁移纠正并删除旧 Swift 缓存。
- Docker Desktop 引擎已运行，但沙箱不能直接访问其 Unix socket和本机测试端口；集成验证需要在获准的宿主环境执行。
- 当前 Starlette 已弃用 HTTPX 兼容回退，改用其推荐的 HTTPX2 2.x，消除了测试弃用警告。

## 最终代码导航

- 应用或模块入口：[main.py](../../../../server/src/kitchen_server/main.py)
- Controller/Handler：[factory.py](../../../../server/src/kitchen_server/app/factory.py)
- Domain/Service：[readiness.py](../../../../server/src/kitchen_server/domain/readiness.py)
- Repository/Migration：[database.py](../../../../server/src/kitchen_server/infrastructure/database.py)、[runtime metadata migration](../../../../server/migrations/versions/20260803_0001_runtime_metadata.py)
- 核心测试：[test_health_and_logging.py](../../../../server/tests/unit/test_health_and_logging.py)、[test_postgres.py](../../../../server/tests/integration/test_postgres.py)

## 相关资料

- OpenSpec：[server-python-foundation](../../../../openspec/changes/archive/2026-08-03-server-python-foundation/)
- Contract：[跨端契约索引](../../../contracts/README.md)；本轮没有新增共享语义。
- Decision：本轮技术选型记录在 change 的 `design.md`，尚无独立长期 decision。

## 下一步

在 `shared-auth-account-session` 中建立首个正式业务 HTTP 契约、账号 schema 和事务边界，并继续保持匿名端侧功能不依赖服务端可用性。
