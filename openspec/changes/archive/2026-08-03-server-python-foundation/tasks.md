## 1. 工程与依赖

- [x] 1.1 确认现有 Swift/Vapor 草案不含业务数据或已发布接口，以 Python 3.13、`pyproject.toml` 和 `uv.lock` 替换其清单、源码与测试，并锁定 FastAPI、Uvicorn、SQLAlchemy、asyncpg、Alembic 和 Pydantic Settings 依赖
- [x] 1.2 建立领域、应用装配、基础设施适配器和 ASGI 入口的单向目录边界，确保领域层不依赖 FastAPI、SQLAlchemy 或外部 SDK
- [x] 1.3 增加仓库忽略规则，确保构建产物、本地环境文件、数据库卷和秘密不会进入版本控制

## 2. 配置与持久化

- [x] 2.1 使用 Pydantic Settings 实现开发、测试和生产配置解析及启动期必需配置校验，并增加秘密脱敏测试
- [x] 2.2 配置 SQLAlchemy 2 异步引擎、按请求 AsyncSession、asyncpg、隔离测试数据库和 Alembic 迁移入口
- [x] 2.3 增加空数据库 Alembic upgrade、重复执行、downgrade 和数据库不可用时拒绝就绪的 PostgreSQL 集成测试

## 3. HTTP 与可观测性

- [x] 3.1 使用 FastAPI lifespan 和 ASGI 路由实现分离的存活与就绪检查，确保响应不泄露拓扑或连接信息
- [x] 3.2 增加请求关联 ID、ASGI 中间件错误边界、异常映射和字段白名单结构化 JSON 日志
- [x] 3.3 增加错误请求日志测试，验证令牌、密钥、完整手机号和业务正文均不会被记录

## 4. 验证与文档

- [x] 4.1 建立 uv 依赖锁定检查、Ruff 格式与 lint、mypy 严格类型检查、pytest 单元测试和 PostgreSQL 集成测试命令并在本地执行
- [x] 4.2 更新 `server/AGENTS.md`、`docs/server/README.md` 和服务端架构/开发运行文档
- [x] 4.3 记录新增生产依赖、配置失败策略、回滚方式和验证证据
- [x] 4.4 按 `docs/learning/server/README.md` 创建本轮服务端学习记录，或在本任务中写明无学习增量的豁免依据
