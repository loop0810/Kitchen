# 客户端 Apple 登录

Apple 授权只在 iOS 入口展示；“不登录继续使用”始终保留。`KitchenNotesAppleSignInCoordinator` 为每次授权生成高熵 nonce，传入 Apple 原生授权请求，并将 identity token、授权码、nonce、流程 ID 和可选资料交给服务端网关。客户端 `userIdentifier`、邮箱和姓名不作为认证依据。

取消授权返回 `cancelled`，不显示账号错误、不创建会话，也不影响本地菜谱。姓名和邮箱可能只在首次授权返回，客户端不要求手机号补充；服务端负责保存已验证的可选资料。

iOS entitlement 位于 `client/ios/Runner/Runner.entitlements`。Apple Developer App ID、生产受众和服务端秘密不写入仓库；开发 Bundle ID 仍以工程配置为准。

账号设置通过共享会话仓储读取服务端身份摘要，只展示已确认的 Apple provider/status；解绑请求交给服务端校验近期认证和最后身份约束。
