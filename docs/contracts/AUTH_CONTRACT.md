# 账号与会话认证契约

## 1. 范围

本契约是客户端与服务端共享的认证事实源，定义稳定账号、外部身份、设备会话、令牌、错误、幂等和账号删除语义。具体第三方凭证验证由 Apple、手机号和微信各自的 change 定义；本契约只接收已验证的身份断言。

登录是可选能力。未登录或认证服务不可用时，设备本地菜谱的创建、导入、编辑、搜索和查阅必须继续可用。登录不会自动上传、同步或迁移设备本地菜谱。

## 2. 稳定账号与身份

- `userId` 由服务端生成，使用不透明字符串；不得使用手机号、邮箱或第三方 subject 作为业务主键。
- `AuthIdentity` 由 `provider`、`providerSubject`、`issuerAudienceScope` 唯一确定，并指向一个 `userId`。
- 同一账号可以绑定多个身份；同一身份不得属于多个账号。
- 首次收到已验证且未占用的身份断言时，服务端在一个数据库事务内创建账号、身份和设备会话。
- 相同显示名、邮箱文本或手机号文本不能触发账号合并。
- 已占用身份的绑定返回 `identity_conflict`，不得泄露已占用账号的详情。

## 3. 会话与令牌

- Access token 为短期凭证，至少包含 `sub`、`sid`、`iat`、`exp` 和 `tokenType`，有效期由服务端配置。
- Refresh token 是高熵不透明值；服务端只保存摘要、token family、设备会话和过期时间。
- 成功刷新必须轮换 refresh token，并立即使旧值失效。
- 重放已轮换 refresh token 时，服务端撤销对应 token family 和设备会话，返回 `session_replay_detected`。
- 客户端不得把 refresh token 写入 Drift、普通偏好、日志或业务请求体之外的埋点。

## 4. HTTP 与错误 envelope

认证 API 使用 JSON 请求与响应。错误统一为：

```json
{
  "error": {
    "code": "invalid_session",
    "message": "会话已失效",
    "requestId": "..."
  }
}
```

稳定错误码至少包括：`invalid_request`、`invalid_credentials`、`invalid_session`、`session_replay_detected`、`identity_conflict`、`recent_auth_required`、`idempotency_conflict`、`account_deletion_in_progress` 和 `internal_error`。错误不得说明另一个账号是否存在。

可能产生副作用的请求必须携带 `Idempotency-Key`。同一操作、同一账号和同一幂等键必须返回原结果；同一键对应不同请求体返回 `idempotency_conflict`。

## 5. 设备与账号删除

- 设备会话包含 `sessionId`、设备显示名称、创建时间、最近使用时间、过期时间和撤销时间；不得记录设备硬件标识作为账号主键。
- 退出当前设备只撤销当前 session 和其 token family。
- 退出全部设备撤销账号下所有 session 和 token family。
- 删除账号需要近期重新认证；服务端先撤销全部会话，再将账号置为删除中，并由可重试清理任务完成后续删除。
- 账号删除与清除本机菜谱是两个独立确认项。只删除账号时，本机菜谱保持可用。

## 6. 关联边界

- 个性化配置网关必须从正式会话解析当前 `userId`，客户端不能在请求中传入可伪造的 owner ID。
- 本契约不定义菜谱云同步、备份上传或跨设备恢复。

## 7. Apple 身份边界

- Apple 身份使用已验证的 `sub` 作为 `providerSubject`，`issuerAudienceScope` 必须同时隔离 `https://appleid.apple.com` 与当前 App ID / Services ID。
- Apple 的邮箱、姓名和私密中继邮箱都是可选资料，不得作为账号主键；姓名可能只在首次授权返回。
- Apple 登录不要求补充手机号；用户取消授权时不得创建账号或会话，并应返回可恢复的取消状态。
- 服务端必须验证 Apple JWS 的签名、`iss`、`aud`、`exp`、`iat`、`nonce`、一次性授权流程状态和授权码存在性；客户端返回的 subject、邮箱和姓名不能单独认证。
- Apple 身份撤销只标记该身份不可用于新会话；同一账号绑定的其他身份不受影响。账号删除仍按本契约的删除流程执行。

## 8. 账号设置中的身份管理

- `GET /v1/auth/identities` 只返回当前 access token 对应账号的身份摘要：`id`、`provider`、`status` 和可选邮箱；不得返回 provider subject。
- `DELETE /v1/auth/identities/{id}` 需要有效的当前设备会话和近期认证；服务端必须确认身份属于当前账号，并拒绝解绑最后一个身份。
- 解绑单个 Apple 身份不等同于删除账号；删除账号仍使用本契约第 5 节的近期重新认证、撤销全部会话和可重试清理流程。
