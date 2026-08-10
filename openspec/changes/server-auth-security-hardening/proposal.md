## Why

一次针对服务端的安全审查发现：认证签名密钥和手机号 pepper 在仓库中存在可用默认值，生产环境即使不注入任何秘密也能启动，任何读过仓库的人都能伪造访问令牌；`PHONE_AUTH_MODE=mock` 与固定验证码在生产同样可用；敏感操作的“近期重新认证”判据取自会被刷新前移的访问令牌 `iat`，长期会话可以随时通过。这些都属于配置与鉴权边界问题，必须在服务端引入更多业务 API 之前收口。

## What Changes

- 生产环境启动强制要求显式注入且足够长的 `AUTH_SIGNING_SECRET` 与 `PHONE_OTP_PEPPER`，拒绝仓库中的开发示例值。
- 生产环境禁止启用 `PHONE_AUTH_MODE=mock`，模拟验证码登录只保留在非生产环境。
- `APPLE_CLIENT_ID` 为空值时按未配置处理，Apple 身份校验失败关闭而不是使用空 audience。
- 敏感操作的“近期重新认证”以设备会话建立时间为准，会话校验同时拒绝已过期的设备会话。
- 未认证即可调用的授权流程状态和进程内幂等缓存加入 TTL 回收与容量上限。

## Capabilities

### New Capabilities

无。

### Modified Capabilities

- `server-runtime-foundation`：补充生产秘密与模拟登录模式的启动校验边界。
- `account-session-auth`：明确近期重新认证判据和会话有效期校验。

## Impact

- 影响 `server/src/kitchen_server/infrastructure/config.py`、`auth/apple.py`、`auth/phone.py`、`auth/routes.py` 及对应单元测试。
- 生产部署必须在本次变更前准备好秘密注入；缺失秘密的实例将在监听 HTTP 前退出。
- 客户端契约字段不变，解绑身份等敏感操作在会话建立超过 10 分钟后需要重新登录。
