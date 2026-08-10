## Why

当前 MVP 规划同时包含 OCR、登录、服务端同步、备份、iOS 分享和多项外围整理能力，导致核心菜谱闭环迟迟无法形成可发布版本。现在需要把 V1 收口为 Android 单平台、本地优先、无需登录即可独立使用的最小产品，以便先完成真实验收和稳定性验证。

## What Changes

- **BREAKING**：将 V1 发布目标限定为 Android；iOS 客户端、iOS Share Extension 和 App Store 发布延期到稳定版本之后。
- **BREAKING**：V1 不依赖登录、服务端、账号配置、云端备份或多设备同步。
- 保留并优先完成 Android 分享、相册图片导入、文字导入、导入箱持久化、端侧 OCR、OCR 失败降级和手动补充。
- 保留菜谱确认、待完善保存、手动创建、编辑、本地搜索、收藏、标签、完整详情和离线查阅。
- V1 保留一套稳定的免费视觉模板；复杂模板扩展和商业化延期。
- 将 Apple/微信/手机号登录、个性化配置同步、本地备份恢复、iOS 分享扩展、社区、付费 AI 和烹饪运行时标记为 V1 后工作。
- 调整现有 OCR 主线和产品验收清单，使 Android 无网络核心流程成为唯一发布门槛。

## Capabilities

### New Capabilities

- `android-v1-recipe-core`: 定义 Android 无登录、无网络条件下从导入到菜谱查阅的 V1 核心闭环和发布边界。

### Modified Capabilities

无。当前 `openspec/specs/` 没有可修改的主规格；现有进行中的 change 将按本 change 的范围重新排序或延期。

## Impact

- 客户端根 App、首页、导入、菜谱库、编辑器和详情页的发布范围与验收入口。
- `refocus-mvp-recipe-ocr` 的任务排序：OCR 恢复、确认和 Android 验收优先；个性化配置和外围能力延期。
- 登录、备份恢复、iOS Share Extension 等已有 change 不进入 V1 实施队列，但保留规划以便后续恢复。
- `docs/product/MVP_REQUIREMENTS.md`、客户端 README、决策日志和 V1 验收清单需要同步版本边界。
- 不新增服务端依赖、第三方 AI、账号系统或生产环境配置。
