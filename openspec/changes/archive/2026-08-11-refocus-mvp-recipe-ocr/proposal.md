## Why

当前产品同时承诺菜谱整理和逐步烹饪运行时，后者缺少明确产品方案，却显著扩大了领域模型、平台能力和 MVP 验收范围。将产品重新聚焦于菜谱的导入、整理、保存与查阅，可以把资源投入目前最有价值但尚不完整的图片 OCR 失败降级和草稿确认闭环。

## What Changes

- **BREAKING**：从产品长期方向和 MVP 中移除逐步烹饪、计时器、通知、进度恢复、屏幕常亮、CookSession、CookRecord 和烹饪完成记录，不再规划独立烹饪 Feature 或运行时服务。
- **BREAKING**：移除依赖烹饪历史的“做过”筛选、“最近做过”和“最常制作”排序，以及菜谱详情中的“开始烹饪”入口；菜谱详情以完整查阅和编辑为终点。
- 保留菜谱自身有意义的准备时间、烹饪时间、步骤时长、火力、温度和长期笔记等内容字段，但它们只用于记录和展示，不触发运行时逻辑。
- 更新产品总纲、MVP、菜谱专项需求、服务导航、决策日志和验收清单，使“导入、整理、保存、搜索、翻阅、查看详情”成为完整核心闭环。
- 为图片导入补齐可恢复的失败降级：查看图片、调整顺序、裁剪或旋转、替换或追加、忽略或恢复单图、编辑 OCR 正文、补充说明，并从受影响阶段安全重新处理。
- 补齐结构化草稿确认：按区块展示字段值、来源、证据、可信等级和问题摘要，支持修改与排序、保存不完整菜谱、暂存稍后继续，且用户编辑或确认内容不得被重新识别覆盖。
- 在“我的 → 个性化食谱”集中管理分类、标签和难度；应用启动从账号服务拉取配置，服务端首次返回默认配置，客户端持久化缓存并让所有选择界面只读取缓存，用户修改后同步服务端与缓存。
- 将准备时间和制作时间改为小时、分钟双列选择器，分钟列循环滚动且总时长不超过两小时。
- 增加针对多图编辑、部分 OCR 失败、重试恢复、字段证据和用户编辑保护的自动化测试；当前 V1 完成 Android 无网络真机验收，iOS 验收按既有 Android-only 发布策略延期。

## Capabilities

### New Capabilities

- `recipe-product-scope`：定义聚焦菜谱导入、整理、管理与查阅的产品边界，并明确不提供烹饪运行时及其衍生状态。
- `ocr-import-recovery-review`：定义图片 OCR 导入的媒体修正、部分失败降级、可恢复重处理和可解释草稿确认行为。

### Modified Capabilities

无。当前 OpenSpec 主规格目录尚无已有 capability，本次以两个新 capability 建立行为基线。

## Impact

- 权威文档：`docs/product/PRODUCT_REQUIREMENTS.md`、`docs/product/MVP_REQUIREMENTS.md`、
  `docs/product/RECIPE_REQUIREMENTS.md`、`docs/decisions/DECISION_LOG.md`、
  `docs/client/services/README.md` 和 `docs/client/services/IMPORT_PIPELINE_SERVICE.md`。
- Recipe Domain/Data/UI：移除烹饪历史查询语义和详情入口；现有 SQLite 遗留列优先兼容保留但停止公开使用，避免无价值的破坏性表重建。
- Recipe Domain/Data/Profile：增加个性化食谱配置实体、Repository、服务端网关和本地缓存；Profile 提供集中管理入口，Import 与 Recipe Editor 只消费缓存快照。
- Import Domain/Data/UI：扩展媒体变更命令、OCR 失效与重处理规则、字段级确认状态和持久化草稿编辑；根 App 继续负责 Import Draft 到 Recipe Editor 的跨 Feature 协调。
- 平台能力：继续复用 iOS Vision 和 Android ML Kit OCR Adapter；裁剪、旋转和文件替换必须限制在应用受控媒体目录内。
- 不引入云端 AI、生产 API Key、烹饪通知或屏幕常亮依赖。
