## 1. 配置与秘密边界

- [x] 1.1 生产环境校验 `AUTH_SIGNING_SECRET` 和 `PHONE_OTP_PEPPER` 已显式注入、长度不低于 32 字符且不是仓库示例值
- [x] 1.2 生产环境拒绝 `PHONE_AUTH_MODE=mock`
- [x] 1.3 空 `APPLE_CLIENT_ID` 归一化为未配置，Apple 校验在缺少 client id 时失败关闭
- [x] 1.4 更新 `docs/server/DEVELOPMENT.md` 配置表、失败策略与验证方式

## 2. 鉴权边界

- [x] 2.1 近期重新认证改用设备会话建立时间，不再使用访问令牌 `iat`
- [x] 2.2 会话校验拒绝已过期的设备会话
- [x] 2.3 Apple nonce 比较使用常量时间比较
- [x] 2.4 更新 `docs/server/AUTH.md` 说明近期重新认证判据

## 3. 资源边界

- [x] 3.1 Apple 授权流程状态存储回收过期条目并设置容量上限
- [x] 3.2 手机号模拟登录幂等缓存改为带 TTL 和容量上限的实现

## 4. 验证

- [x] 4.1 补充生产密钥、模拟模式、空 client id 和状态存储回收的单元测试
- [x] 4.2 运行 `make format-check`、`make typecheck` 和 `make test`
- [ ] 4.3 运行 `make integration-test`（本次未连接 PostgreSQL 容器，变更不涉及 schema）
- [ ] 4.4 创建服务端学习记录或写明豁免原因
