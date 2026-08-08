# 服务端 Auth 模块

认证共享语义以 [`docs/contracts/AUTH_CONTRACT.md`](../contracts/AUTH_CONTRACT.md) 为准；本页只说明 FastAPI 服务端实现边界。

当前 Auth 模块已建立账号、已验证身份、设备会话、refresh token family 和幂等记录的 SQLAlchemy 模型与 PostgreSQL migration，并提供短期 access token 签发、refresh token 摘要轮换、重放撤销、设备会话撤销、身份冲突、删除状态机和安全审计端口。具体 Apple、手机号和微信凭证验证不在本模块内。

服务端只保存 refresh token 摘要，不记录访问令牌、第三方密钥、菜谱正文或图片。账号删除进入 `deletion_pending` 状态并先撤销全部会话；本机菜谱是否清除由客户端独立确认。

实现导航：

- 模型：`server/src/kitchen_server/auth/models.py`
- 会话服务：`server/src/kitchen_server/auth/service.py`
- 迁移：`server/migrations/versions/20260808_0002_auth_account_session.py`
- 令牌测试：`server/tests/unit/test_auth_service.py`
- 集成测试：`server/tests/integration/test_postgres.py`
