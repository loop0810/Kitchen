## Why

厨房手记已经具备导入箱和本地菜谱整理流程，但 iOS 用户仍无法从 Safari、相册或其他内容应用直接把菜谱内容送入应用。Android 已通过系统分享完成相同入口，因此现在补齐 iOS Share Extension，可以让跨平台的核心导入路径真正可用。

## What Changes

- 新增 iOS Share Extension，接收文字、HTTPS 链接、单张图片和多张图片。
- 使用 App Group 共享容器，将分享内容复制到受控暂存目录并写入版本化清单。
- 支持主 App 未启动、被系统中断或暂时无法接管时保留待处理分享内容。
- 主 App 启动或恢复前台时读取清单，创建持久化 ImportTask，并在成功接管后确认清理暂存内容。
- 复用现有导入领域模型、Repository 和 OCR 流程，不在扩展进程中执行 OCR、网页解析或账号登录。
- 对重复消费、无效清单、不可支持的类型、文件复制失败和暂存空间不足提供可恢复结果。
- 配置 iOS 原生 target、App Group entitlement、分享扩展图标和调试/归档构建边界。

## Capabilities

### New Capabilities

- `ios-share-extension`: 定义 iOS 系统分享内容的接收、受控暂存、主 App 接管、幂等消费和失败恢复行为。

### Modified Capabilities

无。

## Impact

- 影响 `client/ios` 原生工程、Share Extension target、App Group 配置和 Flutter 主 App 启动/前台恢复协调。
- 影响 `kitchen_import_data` 的平台分享适配器，但继续复用现有 `ImportTask` 创建和媒体受控存储边界。
- 不新增服务端 API、账号依赖、网络服务或生产依赖。
- 需要在真实 iOS 设备上验证来自文字、链接、单图、多图和冷启动场景的分享接管。

## 当前实施边界

由于当前使用免费的 Personal Team，无法为 iOS 真机签发 Sign in with Apple、App Groups
和 Share Extension 所需的 provisioning profile。本 change 的实现代码保留，但暂时从
Runner 的签名和启动流程中关闭；当前设备验收优先覆盖 Android，待获得付费开发者团队后
再恢复 iOS 能力并完成剩余真机任务。
