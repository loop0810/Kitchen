# 002 账号与会话认证基础

> OpenSpec change：`shared-auth-account-session`  
> 完成日期：2026-08-08

## 本轮目标

建立稳定账号、认证身份、设备会话、刷新令牌族和账号删除状态的服务端领域边界，并让 Flutter 以会话端口观察登录状态，同时保持本地优先。

## 前置概念

需要理解数据库唯一约束、事务嵌套保存点、refresh token rotation、token family replay detection、Riverpod 依赖装配和 Keychain/Keystore 与业务缓存的区别。

## 架构与数据流

```text
已验证身份 -> AuthService -> User/AuthIdentity -> DeviceSession/RefreshTokenFamily
                                      ↓
                         access token + 安全存储 refresh token
```

首次认证由数据库唯一约束兜底并发创建；客户端恢复会话异步进行，失败只影响账号能力，不影响本地菜谱。

## 实现顺序及原因

先稳定共享契约和数据库模型，再补认证服务中的会话撤销、身份冲突和删除状态机，最后在客户端增加 domain 状态、会话仓储端口和 Profile 入口。这样客户端不会自行定义用户 ID 或令牌协议。

## 契约与数据库变化

- [认证契约](../../../contracts/AUTH_CONTRACT.md)
- [认证迁移](../../../../server/migrations/versions/20260808_0002_auth_account_session.py)

新增账号、身份、设备会话、刷新令牌族和幂等记录表，并增加删除完成时间字段。

## 验证方法

- 服务端 Ruff、mypy 与 16 个非集成测试通过。
- Flutter auth domain、Profile widget 与会话仓储测试通过。
- PostgreSQL 迁移和 Auth 集成测试已增加；本机 Docker socket 不可用，执行时由 pytest 安全跳过。

## 遇到的问题与修正

服务端原有 `make typecheck` 使用了错误的 mypy 入口，导致系统环境无法解析 FastAPI 等依赖；已改为 `uv run python -m mypy`。Profile 页面新增账号区时保留了无组合根依赖的视觉测试兼容路径，避免账号服务成为本地页面渲染前置条件。Docker socket 不可用时集成测试只跳过，不把未执行误记为通过。

## 最终代码导航

- 应用或模块入口：`server/src/kitchen_server/auth/service.py`
- Domain/Service：`AuthService`、`AuthError`
- Repository/Migration：`server/src/kitchen_server/auth/models.py`、`server/migrations/versions/20260808_0002_auth_account_session.py`
- 客户端会话：`client/lib/src/auth/kitchen_notes_auth_session_repository.dart`
- 核心测试：`server/tests/unit/test_auth_service.py`、`client/test/kitchen_notes_auth_session_repository_test.dart`

## 相关资料

- OpenSpec：`openspec/changes/shared-auth-account-session/`
- Contract：`docs/contracts/AUTH_CONTRACT.md`
- Decision：`docs/decisions/DECISION_LOG.md`

## 下一步

接入真实 HTTP 认证网关和 Keychain/Keystore 平台适配器，并为身份断言、幂等副作用和 PostgreSQL 并发场景增加集成测试。
