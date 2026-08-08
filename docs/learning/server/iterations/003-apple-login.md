# 003 Apple 登录服务端验证

> OpenSpec change：`shared-apple-login`  
> 完成日期：2026-08-09

## 本轮目标

在共享账号会话基础上接入 Apple 身份验证、一次性授权流程、撤销状态和 Apple exchange HTTP 边界，不提交任何 Apple 私钥或 client secret。

## 前置概念

需要理解 JWS/JWT 的签名与声明校验、Apple 公钥 `kid` 轮换、nonce 防重放、一次性授权码、OAuth exchange、FastAPI response model 和迁移兼容。

## 架构与数据流

```text
iOS Apple SDK -> nonce/flow endpoint -> Apple identity token + code
                                      ↓
                       AppleIdentityVerifier -> AuthService -> User/Session
```

客户端只负责授权流程和传递凭证；服务端验证签名、issuer、audience、时效、nonce 和流程状态后，才把 Apple subject 转成共享身份断言。

## 契约与数据库变化

- [认证契约](../../../contracts/AUTH_CONTRACT.md)
- [Apple 服务端说明](../../../server/AUTH.md)
- [Apple 迁移](../../../../server/migrations/versions/20260809_0003_apple_identity_state.py)

`auth_identities` 增加 active/revoked 状态、可选邮箱/姓名和撤销时间。

## 验证方法

- 服务端 Ruff、mypy 与 23 个非集成测试通过。
- Apple verifier 测试覆盖有效 token、错误 audience/issuer/nonce/expiry、流程重放。
- Flutter analyze、Apple HTTP gateway、会话和 Profile 测试通过。
- PostgreSQL 与 iOS 真机/沙盒验收需在 Docker 和 Apple Developer 配置可用后执行。

## 遇到的问题与修正

服务端直接运行 `alembic` 入口在当前环境不可用，改用 `uv run python -m alembic` 验证迁移链；Apple 公钥未命中时强制刷新一次，避免把正常公钥轮换误判为凭证错误。

## 最终代码导航

- Apple 验证：`server/src/kitchen_server/auth/apple.py`
- Apple HTTP：`server/src/kitchen_server/auth/routes.py`
- 共享账号：`server/src/kitchen_server/auth/service.py`
- 客户端协调器：`client/lib/src/auth/kitchen_notes_apple_sign_in.dart`
- iOS entitlement：`client/ios/Runner/Runner.entitlements`
- 测试：`server/tests/unit/test_apple_auth.py`、`client/test/kitchen_notes_apple_sign_in_test.dart`

## 下一步

提供正式 Apple Developer App ID/Services ID、生产 audience、签名材料注入和真实 iOS 沙盒验收；多副本服务端将内存授权流程状态替换为共享 TTL 存储。
