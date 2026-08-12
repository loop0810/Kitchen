# 导入流水线：从截图、文案和链接到菜谱草稿

本文用于学习当前客户端的真实实现，重点回答三个问题：输入先保存在哪里、不同输入怎样变成同一种结构化文本、自动结果怎样成为可恢复且不会覆盖用户修改的菜谱草稿。

权威行为和约束仍以[导入处理服务需求](../client/services/IMPORT_PIPELINE_SERVICE.md)为准；本文只解释代码如何实现这些约束，不重新定义需求。

## 1. 先建立一个心智模型

导入不是“调用一次 OCR，然后直接保存菜谱”，而是两个有明确人工边界的转换：

```text
截图 / 文案 / 链接
        │
        ▼
持久化 ImportTask ── 原始材料与处理中间结果，可失败、重试和恢复
        │
        ▼
获得可结构化文本 ── 图片走 OCR + 布局分析，链接走网页提取，文案直接使用
        │
        ▼
RecipeDraftEntity ── 自动候选、证据、置信等级和用户修改都在这里
        │
        ▼
用户审核并继续到菜谱编辑器
        │
        ▼
正式 Recipe ── 由菜谱领域的 CreateRecipeUseCase 保存
```

最重要的边界是：

- `ImportTask` 是可恢复处理任务，不是正式菜谱。
- `RecipeDraftEntity` 是需要用户审核的候选，不是权威菜谱内容。
- 正式保存仍由菜谱领域完成，Import Feature 不直接写菜谱数据库。
- 服务端不参与当前默认导入；截图 OCR、网页整理、草稿生成和保存都可以在客户端完成。

## 2. 三个 package 各负责什么

| 层 | package | 主要职责 | 不负责 |
| --- | --- | --- | --- |
| Presentation | `kitchen_import` | 选择图片、粘贴文案、显示任务状态、校对 OCR、审核草稿 | Drift、平台 OCR、正式菜谱保存 |
| Domain | `kitchen_import_domain` | 任务状态、OCR 领域模型、流水线编排、布局分析、本地结构化、草稿合并 | Flutter UI、数据库、HTTP 和平台通道 |
| Data | `kitchen_import_data` | Drift 持久化、媒体受控存储、网页提取、平台 OCR 适配、系统分享适配 | 页面展示、菜谱领域规则 |

根 App 是组合根。它创建 Data 实现，将其注入 Import Feature，并在导入草稿与菜谱编辑器之间做跨 Feature 协调。这个依赖方向让 Domain 可以使用纯 Dart 测试，也避免 Import Feature 直接依赖 Recipe Feature。

关键装配入口：

- [`client/lib/main.dart`](../../client/lib/main.dart)：创建 `ImportDataModule`、`ImportPipeline`，恢复中断任务并消费 Android 分享。
- [`kitchen_import_dependencies.dart`](../../client/packages/kitchen_import/lib/src/shared/providers/kitchen_import_dependencies.dart)：Import Feature 使用的依赖端口。
- [`kitchen_notes_app_router.dart`](../../client/lib/src/navigation/kitchen_notes_app_router.dart)：把确认草稿映射为 `CreateRecipeInput`。

## 3. 第一道保险：先保存原料，再开始处理

三种入口最终都会先调用 Repository 创建任务，拿到 `taskId` 后才异步调用 `pipeline.process(taskId)`：

| 输入入口 | 创建方法 | 首次持久化的核心内容 |
| --- | --- | --- |
| 粘贴文案或链接 | `createTextTask` | `originalText`、检测到的 HTTPS URL、`queued` 状态 |
| 相册截图 | `createImageTask` | 已复制到受控目录的媒体路径、用户顺序、`queued` 状态 |
| 系统分享 | `createSharedTask` | 分享文字、受控媒体路径、`sourceShareId` 幂等键、`queued` 状态 |

对应入口分别在：

- [`kitchen_import_paste_article_page.dart`](../../client/packages/kitchen_import/lib/src/article_import/pages/kitchen_import_paste_article_page.dart)
- [`kitchen_import_image_import_page.dart`](../../client/packages/kitchen_import/lib/src/image_import/pages/kitchen_import_image_import_page.dart)
- [`main.dart`](../../client/lib/main.dart) 的 `_consumePendingAndroidShares`

图片不能把相册或分享来源给出的临时路径直接写进任务。`ImportDataModule.persistPickedImages` 先把文件复制到应用支持目录中的 `import_media`，全部复制成功后才创建任务；复制中途失败会清理本次临时目录。这样应用重启或系统回收临时 URI 后，任务仍然能找到原图。

任务由独立的 Drift 表 `ImportTasks` 保存。它把原文、媒体、机器 OCR、用户校对文字、补充说明和草稿分列保存，因此后一个阶段失败不会覆盖前一个阶段的材料。表定义见 [`kitchen_import_data_app_database.dart`](../../client/packages/kitchen_import_data/lib/src/import_task/database/kitchen_import_data_app_database.dart)。

## 4. `ImportPipeline.process` 是主状态机

主编排器位于 [`kitchen_import_domain_import_pipeline.dart`](../../client/packages/kitchen_import_domain/lib/src/import_pipeline/services/kitchen_import_domain_import_pipeline.dart)。它只依赖四个抽象能力：

```text
ImportTaskRepository     读取和持久化任务状态
OcrAdapter               把一页图片变成带坐标的 OCR 行
PublicContentExtractor   把公开 HTTPS 页面变成正文
RecipeStructurer         把文本和证据变成 RecipeDraftEntity
```

因此 `ImportPipeline` 不知道 Drift、ML Kit、Vision 或 Flutter 页面。构造时由根 App 注入具体实现。

一次 `process` 的公共骨架是：

1. 读取任务；任务不存在或已取消就停止。
2. 记录当前 `processingGeneration`，作为这次处理的快照版本。
3. 根据任务材料走图片分支、链接分支或纯文本分支。
4. 进入 `structuring`，调用本地结构化器生成候选草稿。
5. 如果已有草稿，先通过 `RecipeDraftMergeService` 合并并保护用户字段。
6. `saveDraft` 将 JSON 草稿落库，并把状态变为 `awaitingReview`。
7. 可预期错误保存稳定错误码和可行动文案；原始材料继续保留。

纯文本没有额外提取步骤，直接进入第 4 步。图片和链接分支的差异如下。

## 5. 截图怎样变成草稿

### 5.1 平台 OCR 只产出“行 + 坐标”

`PlatformOcrAdapter` 通过 `kitchen_notes/import_ocr` MethodChannel 调用平台实现：

- Android 使用 ML Kit 中文文字识别器。
- iOS 使用 Vision `VNRecognizeTextRequest`。

平台结果在 [`kitchen_import_data_platform_ocr_adapter.dart`](../../client/packages/kitchen_import_data/lib/src/ocr/adapters/kitchen_import_data_platform_ocr_adapter.dart) 中统一成 `OcrPageEntity`。每行包含：

- 稳定行 ID；
- 原始文字；
- 可选识别置信度；
- 以左上角为原点、范围为 `0...1` 的归一化矩形。

统一坐标非常关键：后面的 Domain 逻辑不需要知道 Android 和 iOS 的原始坐标系，也不依赖图片像素尺寸。

### 5.2 每页独立处理和恢复

流水线按用户的 `position` 排序图片，并跳过 `ignored` 页面。每页都具有 `pending / processing / succeeded / failed` 状态：

- 已成功且带 `ocrPage` 的页面直接复用。
- 未完成页面才调用 OCR。
- 单页失败只写回该页错误，不清空其他成功页。
- 至少有一页成功时，仍可生成不完整草稿。

这就是为什么多张截图中一张模糊图不会使整批材料丢失。

### 5.3 布局分析把坐标恢复为阅读顺序

OCR 引擎识别了文字，却不一定给出适合菜谱的阅读顺序。`OcrLayoutAnalyzerService` 在 Domain 中做第二层整理：

- 按坐标恢复行和区域顺序；
- 识别“食材 / 步骤 / 小贴士”等分区；
- 配对左右排列的食材名和用量；
- 重排多栏步骤卡片；
- 过滤低置信噪声；
- 移除跨页重复的页眉、页脚和重复正文；
- 检测一页中可能包含多道菜的情况。

代码入口是 [`kitchen_import_domain_ocr_layout_analyzer_service.dart`](../../client/packages/kitchen_import_domain/lib/src/ocr/services/kitchen_import_domain_ocr_layout_analyzer_service.dart)。输出的 `normalizedText` 给结构化器消费，`visibleLines` 则保留下来做字段证据。

### 5.4 本地结构化器做保守分类

`LocalRecipeStructurerService` 不调用 AI。它使用分区标题、步骤编号、用量、动作词、标题特征和平台噪声规则，尝试得到：

- 菜名；
- 食材自然语言行；
- 烹饪步骤；
- 质量等级和警告。

规则刻意偏保守：不能可靠判断时保持为空，并添加“请手动填写/确认”的警告，而不是为了填满字段把动作句猜成食材。图片自动结果还会标记为需要确认。

## 6. 文案怎样变成草稿

粘贴的完整文章、分享文案和纯文字都保存在 `originalText`。如果没有图片、也没有检测到可提取链接，流水线直接把这段文字交给本地结构化器。

结构化前会统一处理常见行分隔符和空行，再识别菜谱分区。与截图相比，这条路径没有 OCR 坐标，因此通常没有 `DraftFieldEvidence`；字段来源仍会记录为 `source` 或 `inferred`。

注意“分享文案 + 图片”走图片分支：最终结构化文本会按以下顺序组合，三者仍分别持久化：

```text
originalText

correctedOcrText（没有则用机器 ocrText）

supplementalText
```

用户校对不会改写机器 OCR，补充说明也不会混入原文。这种分层让重新 OCR、重新整理和用户修改可以独立演进。

## 7. 链接怎样变成草稿

Repository 会从原文中检测第一个 URL。HTTP 只在本地升级为 HTTPS 后尝试，绝不会发送明文 HTTP 请求。

`SafePublicContentExtractor` 先限制网络边界：

- 只允许公开 HTTPS；
- 拒绝本机、私网和链路本地地址；
- 最多 3 次重定向；
- 只接受 HTML；
- 最多读取 2 MB；
- 连接及等待响应头超时为 10 秒。

随后按信息可靠性从高到低提取：

1. Schema.org Recipe JSON-LD；
2. Article JSON-LD；
3. Open Graph 标题和描述；
4. `<article>` / `<main>` / 页面纯文本降级。

提取出的文本不是草稿，它仍会进入同一个 `LocalRecipeStructurerService`。如果输入只有 URL，URL 不会作为第一行参与菜名候选；如果分享文案还有额外说明，则把说明与网页正文一起结构化。实现见 [`kitchen_import_data_public_content_extractor.dart`](../../client/packages/kitchen_import_data/lib/src/content/adapters/kitchen_import_data_public_content_extractor.dart)。

链接读取失败时，任务进入 `failed`，但 `originalText` 和 URL 仍在数据库中，用户可以重试、粘贴正文或转手动创建。

## 8. 草稿为什么不是普通 DTO

[`RecipeDraftEntity`](../../client/packages/kitchen_import_domain/lib/src/recipe_draft/entities/kitchen_import_domain_recipe_draft_entity.dart) 的每个字段都由 `DraftFieldValue<T>` 包裹。除了值本身，它还保存：

| 元数据 | 作用 |
| --- | --- |
| `origin` | 区分原文、推断、用户编辑和用户确认 |
| `needsConfirmation` | 告诉确认页哪些字段仍需注意 |
| `confidence` | 使用高/中/低离散等级，避免伪精确百分比 |
| `evidence` | 指回 OCR 页码、行 ID 和摘录 |
| `conflictCandidate` | 重新处理产生新候选时，保留冲突但不覆盖用户值 |

`RecipeDraftMergeService` 的保护规则是：自动字段可以被新自动结果刷新；`userEdited` 和 `userConfirmed` 字段不能被覆盖。食材、步骤和标签按整个列表保护，避免用户已调整的顺序被重新识别打乱。

草稿通过 `ImportTaskMapper` 编码为版本化 JSON，存入 `draftJson`。确认页中的每次编辑或确认都会调用 `saveReviewDraft` 自动持久化，所以退出后可以继续。

## 9. `processingGeneration` 解决什么问题

考虑这个时序：

```text
第 0 代开始识别图片 A
        │
        ├── 用户旋转/替换/重排图片，任务进入第 1 代
        │
        └── 第 0 代 OCR 较晚返回
```

如果旧结果直接写回，新的图片状态就会被污染。仓库因此为任务保存单调递增的 `processingGeneration`：

- 流水线开始时记住当前代次；
- 媒体内容、顺序、用户校对或草稿修改会推进代次；
- 所有异步状态和 OCR 写回携带 `expectedGeneration`；
- Repository 发现代次不一致时丢弃旧结果。

它可以理解为轻量的乐观并发控制，不是展示给用户的版本号。

## 10. 草稿怎样交给正式菜谱

确认页先将当前字段保存为 `RecipeDraftEntity`，然后通过 callback 把草稿交回根 App 的 `_ImportDraftCoordinatorPage`。根 App 将它映射为菜谱领域的 `CreateRecipeInput`，包括来源快照和 `importTaskId`，再打开 `CreateRecipePage`。

正式保存成功后，回调调用 `markSaved(taskId, recipeId)`：

- 导入任务状态变为 `saved`；
- `finalRecipeId` 建立任务到正式菜谱的追踪关系；
- 再次打开同一确认路由会直接进入已保存的菜谱；
- `importTaskId` 也作为正式菜谱创建的幂等边界，避免重复确认产生重复菜谱。

这段跨 Feature 映射必须留在组合根，而不是让 `kitchen_import` 依赖 `kitchen_recipe_editor`。

## 11. 推荐的代码阅读顺序

第一次学习时不要从最长的正则文件开始。按下面顺序更容易建立完整链路：

1. `ImportTaskEntity`：先认识任务状态和持久化材料。
2. `ImportPipeline.process`：只看状态转换与三个输入分支。
3. `ImportTaskRepository` 和 `ImportTaskRepositoryImpl`：理解每次写回如何落库和拒绝过期结果。
4. `OcrPageEntity` 与 `OcrLayoutAnalyzerService`：理解“识字”和“恢复布局”是两件事。
5. `LocalRecipeStructurerService.structure`：再研究标题、食材、步骤的保守规则。
6. `RecipeDraftEntity` 与 `RecipeDraftMergeService`：理解用户值保护。
7. `ImportDraftReviewPage` 和 `_ImportDraftCoordinatorPage`：最后看草稿怎样交给菜谱编辑器。

## 12. 用测试验证理解

测试名基本就是流水线的行为目录：

- [`kitchen_import_domain_import_pipeline_test.dart`](../../client/packages/kitchen_import_domain/test/kitchen_import_domain_import_pipeline_test.dart)：编排、单页失败、校对重整和删除竞态。
- [`kitchen_import_domain_ocr_layout_analyzer_service_test.dart`](../../client/packages/kitchen_import_domain/test/kitchen_import_domain_ocr_layout_analyzer_service_test.dart)：坐标、双栏、去重与噪声过滤。
- [`kitchen_import_domain_local_recipe_structurer_service_test.dart`](../../client/packages/kitchen_import_domain/test/kitchen_import_domain_local_recipe_structurer_service_test.dart)：文案和截图规则。
- [`kitchen_import_domain_recipe_draft_merge_service_test.dart`](../../client/packages/kitchen_import_domain/test/kitchen_import_domain_recipe_draft_merge_service_test.dart)：用户字段保护。
- [`kitchen_import_data_import_task_repository_impl_test.dart`](../../client/packages/kitchen_import_data/test/kitchen_import_data_import_task_repository_impl_test.dart)：持久化、generation、媒体安全和网页提取。
- [`kitchen_import_domain_ocr_replay_test.dart`](../../client/packages/kitchen_import_domain/test/kitchen_import_domain_ocr_replay_test.dart)：真实 OCR 回放样本。

可以从客户端目录运行：

```sh
./tool/kitchen_flutter.sh test packages/kitchen_import_domain/test
./tool/kitchen_flutter.sh test packages/kitchen_import_data/test
./tool/kitchen_flutter.sh test packages/kitchen_import/test
```

调试单个任务时，建议依次检查 `status`、`processingGeneration`、每页 `ocrStatus`、`effectiveOcrText`、`draft.warnings` 和字段 `origin`。这六处通常能定位问题发生在输入持久化、识字、布局、结构化、合并还是审核阶段。

## 13. 容易混淆的几点

- OCR 成功不等于结构化成功：OCR 只负责识字，布局分析和语义分类是后续步骤。
- `ocrText` 不等于用户最终采用的文字：`correctedOcrText` 优先，且两者分开保存。
- 网页提取不直接构造草稿：所有输入最终复用同一本地结构化器。
- `awaitingReview` 不表示内容已经确认：它只表示草稿已生成，可以进入人工审核。
- 重试不创建新任务：同一个 `taskId` 保留原始材料、恢复信息和正式菜谱关联。
- 默认流水线不调用 AI，也不会把图片或 OCR 正文上传到服务端。
