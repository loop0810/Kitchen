## Why

Apple 登录是首个第三方登录方式，也是 iOS 在后续提供微信等社交登录时需要优先满足的审核边界。将它独立实现可以先验证共享账号会话契约，而不引入短信成本或额外手机号收集。

## What Changes

- 在 iOS 提供“通过 Apple 登录”，并由服务端验证授权码、identity token、nonce、签发方和受众。
- 首次 Apple 身份登录时自动创建账号，后续使用稳定 provider subject 找回同一账号。
- 支持隐藏邮箱和姓名仅首次返回的情况，不把邮箱作为账号主键。
- Apple 登录不要求填写或绑定手机号。
- 处理 Apple 凭证撤销、账号删除和重新授权后的会话行为。

## Capabilities

### New Capabilities

- `apple-login`：定义 Apple 授权、服务端验证、自动建号、隐私邮箱和撤销处理。

### Modified Capabilities

无。

## Impact

- 依赖 `shared-auth-account-session`。
- 影响 Flutter 登录入口、iOS entitlement/URL 配置、服务端 Apple 身份适配器及账号设置。
- 新增 Apple 登录客户端依赖和服务端密钥配置，但不得提交签名材料。
