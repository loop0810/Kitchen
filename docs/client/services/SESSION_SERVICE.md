# 会话服务

客户端会话语义以 [`docs/contracts/AUTH_CONTRACT.md`](../../contracts/AUTH_CONTRACT.md) 为准；本页只说明 Flutter 端边界。

`kitchen_auth_domain` 暴露 `AuthSessionRepository` 和 `AuthSessionState`。Feature 只观察匿名、认证中、已登录、刷新和失效状态，不直接访问 refresh token 或平台安全存储。启动恢复必须异步进行，不能阻塞本地菜谱首屏；认证服务失败时本地创建、导入、编辑、搜索和查阅继续工作。

当前已完成纯 Dart domain 端口、根 App 装配、账号页面和 `flutter_secure_storage` 安全存储适配。具体 HTTP 网关仍由 Apple、手机号和微信登录 change 提供；未接入网关前应用保持匿名可用，不能把凭证写入 Drift 或普通偏好。
