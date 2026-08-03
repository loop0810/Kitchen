## Purpose

提供符合 Apple 隐私与审核边界的第三方登录能力，通过服务端验证稳定 Apple 身份自动创建或找回账号，并避免不必要的手机号收集。

## ADDED Requirements

### Requirement: Apple 凭证必须由服务端完整验证
系统 SHALL 只接受服务端成功验证签名、签发方、受众、有效期、nonce 和授权流程关联状态的 Apple 凭证；客户端声明的邮箱、姓名或 subject MUST NOT 单独构成认证依据。

#### Scenario: 有效 Apple 授权
- **WHEN** 服务端收到与本次授权请求匹配且全部声明有效的 Apple 凭证
- **THEN** 服务端使用已验证的 provider subject 继续账号登录

#### Scenario: nonce 不匹配
- **WHEN** Apple 凭证中的 nonce 与本次授权请求不匹配
- **THEN** 服务端拒绝登录且不创建账号或会话

### Requirement: Apple 首次登录自动创建账号且不要求手机号
系统 SHALL 在已验证 Apple 身份尚未绑定账号时自动创建账号，并 MUST NOT 要求用户填写或绑定手机号才能完成 Apple 登录。

#### Scenario: 隐藏邮箱首次登录
- **WHEN** 用户选择隐藏邮箱并首次通过 Apple 完成认证
- **THEN** 系统使用 Apple subject 创建账号并允许用户进入账号功能，不展示手机号补充步骤

### Requirement: Apple 资料字段是可选资料而非身份键
系统 SHALL 允许邮箱或姓名只在首次授权返回、为空或为私密中继地址，并 MUST 使用 provider subject 而不是邮箱作为 Apple 身份唯一键。

#### Scenario: 后续授权不再返回姓名
- **WHEN** 已有 Apple 身份再次登录且 Apple 不返回姓名
- **THEN** 系统仍通过 subject 找回原账号且不覆盖已有资料

### Requirement: 取消和撤销具有安全降级
用户取消 Apple 授权 SHALL 返回可恢复的取消状态而不创建账号；服务端得知 Apple 凭证撤销时 SHALL 阻止其建立新会话，并按账号剩余身份和当前会话策略处理访问。

#### Scenario: 用户取消授权
- **WHEN** 用户在 Apple 授权界面选择取消
- **THEN** 应用返回登录入口并保留本地功能，不显示账号错误或创建账号

