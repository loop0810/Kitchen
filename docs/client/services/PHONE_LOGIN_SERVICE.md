# 客户端手机号登录（模拟模式）

Debug 构建默认显示模拟手机号入口；Release 构建通过编译开关
`KITCHEN_NOTES_ENABLE_MOCK_PHONE_AUTH=true` 显示入口，并将 API 地址从
`KITCHEN_NOTES_API_BASE_URL` 注入。用户输入中国大陆手机号后，客户端请求 challenge，再
提交验证码 `111111`；成功响应交给现有安全会话仓储，和其他登录方式使用同一 authenticated 状态。

Release 默认编译开关关闭。客户端不保存 OTP，不调用短信供应商，也不把客户端倒计时作为安全判断；
服务端返回的 challenge 和限额结果才是权威状态。
