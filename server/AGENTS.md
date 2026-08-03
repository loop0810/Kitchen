# 厨房手记服务端约束

## 当前状态

- `server/` 是 Python 3.13、FastAPI、SQLAlchemy 2 和 PostgreSQL 的模块化单体。
- 当前仅包含运行时基础，不包含账号、同步或其他业务 API。

## 开始工作前

1. 阅读根 `AGENTS.md` 和当前根 OpenSpec change。
2. 阅读 `docs/server/README.md` 及任务涉及的服务端模块文档。
3. 涉及 HTTP、共享模型、错误、幂等或同步时，读取对应 `docs/contracts`。
4. 只有改变用户行为或发布范围时，才读取 `docs/product` 的对应权威需求。
5. 不默认读取 `docs/client`、Figma、Flutter、Drift 或端侧 OCR 文档；仅在共享边界的客户端适配也受影响时读取最小相关内容。

## 架构与文档

- 服务端采用模块化单体方向；业务模块不能因文档中的“服务”名称自动拆成微服务。
- API、数据库、任务队列和腾讯云部署的具体选择以对应 change 和已实现文档为准，不能从未来需求反推为现状。
- 跨端契约定义网络和共享语义；服务端文档只解释 FastAPI、持久化、安全和运维实现。
- 每轮服务端实现完成后，按 `docs/learning/server/iterations/TEMPLATE.md` 记录实际学习结果，或在 tasks 中说明无学习增量的豁免原因。

## 验证与安全

- 在 `server/` 运行 `make lock-check`、`make format-check`、`make typecheck` 和 `make test`。
- PostgreSQL 集成验证运行 `make integration-test`；它只使用端口 5433 的 `kitchen_test` 数据库。
- 本地服务先运行 `docker compose up -d --wait postgres`，复制 `.env.example` 的非生产值到 shell，执行 `make migrate` 后运行 `make run`。
- 依赖只能通过 `pyproject.toml` 声明并提交 `uv.lock`；开发、CI 与部署必须使用锁定解析结果。
- Python 代码使用 Ruff 格式与 lint、mypy 严格类型检查和 pytest；不得用 SQLite 替代 PostgreSQL 作为约束语义的最终验证。
- 服务端不得记录菜谱正文、图片内容、访问令牌或第三方密钥。
- 数据库迁移、鉴权、额度账本、对象存储和删除流程必须具有失败与恢复验证。
