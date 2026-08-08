# 服务端 Apple 登录

共享行为以 [`docs/contracts/AUTH_CONTRACT.md`](../contracts/AUTH_CONTRACT.md) 和当前 Apple change spec 为准。本页只记录服务端实现与配置边界。

`kitchen_server.auth.apple.AppleIdentityVerifier` 接收客户端的 identity token、一次性授权码、nonce 和流程 ID，使用 Apple `kid` 公钥验证 JWS，并检查 issuer、audience、expiry、iat、nonce 与流程状态。公钥通过 `AppleHttpKeyProvider` 缓存，遇到未知 `kid` 强制刷新一次；无法验证时失败关闭。

验证成功只产生共享 `VerifiedIdentityAssertion(provider="apple")`，账号创建和会话签发仍由共享 `AuthService` 处理。Apple subject 是唯一身份键；邮箱、姓名和私密中继地址只作为可选资料保存，后续登录不会用空值覆盖已保存资料。

`AppleRevocationHandler` 将撤销身份标记为 `revoked`，后续不能建立新会话，但不会撤销同一账号的其他身份。私钥、client secret 和签名材料不在仓库中，运行时只从秘密管理设施注入。

当前配置：

- `APPLE_CLIENT_ID`：开发环境可使用当前 Bundle ID `com.loop.kitchenNotes`，生产环境必须使用 Apple Developer 中已登记的正式 App ID / Services ID。
- `APPLE_ISSUER`：默认 `https://appleid.apple.com`。
- Apple 公钥：运行时从 Apple 公钥端点获取，不保存固定公钥文件。
