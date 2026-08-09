# 005 手机号模拟登录与风险预检

> OpenSpec change：`shared-cn-phone-auth-risk`  
> 完成日期：2026-08-09（模拟模式阶段）

## 本轮目标

在不接入真实短信供应商的前提下，贯通中国大陆手机号校验、风控预检、OTP challenge 和共享账号
会话。固定验证码 `111111` 只允许模拟配置使用。

## 架构与数据流

```text
Flutter phone gateway -> challenge route
                           ↓
      normalize + mock CAPTCHA + in-memory atomic preflight
                           ↓
          mock sender (no network) -> OTP challenge
                           ↓
             verify 111111 -> AuthService -> session
```

## 验证方法

- 服务端 Ruff、mypy 和 31 项非集成测试通过。
- Flutter analyze 和手机号 gateway/会话测试通过。
- 测试确认无效 CAPTCHA 和限额失败不会进入 sender；sender 只记录脱敏号码和 intent ID。
- PostgreSQL/真实短信/Redis/CAPTCHA 供应商尚未执行或接入。

## 下一步

补充 PostgreSQL repository、Redis 原子脚本、真实 CAPTCHA/SMS 适配器和安全/费用演练；在资质与
白名单号码验收前保持 `PHONE_AUTH_MODE=mock` 或 `disabled`，禁止切到 live。
