# 手机号登录（模拟模式）

当前只启用 `PHONE_AUTH_MODE=mock` 的本地模拟模式。它完整执行手机号规范化、一次性 CAPTCHA、
设备/IP/网段/号码/全局限额、预算预占、OTP challenge、HMAC 校验、过期、尝试上限、旧码失效、
单次使用和共享 `AuthService` 建号/会话流程，但最后使用进程内 `RecordingSmsSender`，绝不请求
真实短信供应商。

模拟配置：

- `PHONE_MOCK_OTP=111111`：固定验证码，仅用于本地开发。
- `PHONE_MOCK_CAPTCHA_TOKEN=local-captcha-ok`：本地固定 CAPTCHA token；模拟模式允许重复使用，生产实现仍必须使用真实的一次性 token。
- `PHONE_AUTH_MODE=disabled`：默认关闭；设置为 `mock` 才允许发送 challenge。
- `PHONE_AUTH_MODE=live` 当前仍失败关闭，不存在真实供应商旁路。

接口：

- `POST /v1/auth/phone/challenge`：提交手机号、CAPTCHA token、安装实例和幂等键。
- `POST /v1/auth/phone/verify`：提交 challenge ID、验证码和幂等键，成功后复用共享账号会话。

challenge 的验证不依赖短信发送开关，因此已有未过期验证码可以在发送能力关闭后继续完成验证。
当前 runtime 使用内存实现，重启后 challenge 和模拟限额清空；接入真实短信前必须替换为 PostgreSQL
challenge repository、Redis 原子预检和供应商适配器。
