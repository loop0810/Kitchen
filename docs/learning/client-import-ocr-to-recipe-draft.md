# 从图片到菜谱草稿：OCR 导入流程

## 这篇文档解决什么问题

当用户导入一张菜谱截图时，系统并不是直接把图片交给菜谱解析器。它会先调用
手机平台提供的 OCR 能力，把图片转换成“文字行 + 每行在图片中的位置”，再由
领域层恢复截图版面，最后生成可以人工确认的菜谱草稿。

这条链路的核心入口是：

- [`PlatformOcrAdapter`](../../client/packages/kitchen_import_data/lib/src/ocr/adapters/kitchen_import_data_platform_ocr_adapter.dart)
- [`AppDelegate.swift`](../../client/ios/Runner/AppDelegate.swift)
- [`MainActivity.kt`](../../client/android/app/src/main/kotlin/com/example/kitchen_notes/MainActivity.kt)
- [`OcrPageEntity`](../../client/packages/kitchen_import_domain/lib/src/ocr/entities/kitchen_import_domain_ocr_document_entity.dart)
- [`OcrLayoutAnalyzerService`](../../client/packages/kitchen_import_domain/lib/src/ocr/services/kitchen_import_domain_ocr_layout_analyzer_service.dart)
- [`ImportPipeline`](../../client/packages/kitchen_import_domain/lib/src/import_pipeline/services/kitchen_import_domain_import_pipeline.dart)

## 一、先看完整调用链

```text
用户选择图片
  ↓
复制到 App 受控目录
  ↓
ImportPipeline.process(taskId)
  ↓
PlatformOcrAdapter.recognize(media)
  ↓
Flutter MethodChannel
  ├── iOS Vision
  └── Android ML Kit
  ↓
文字行 + 坐标 + 置信度
  ↓
OcrPageEntity / OcrLineEntity
  ↓
OcrLayoutAnalyzerService
  ↓
LocalRecipeStructurerService
  ↓
RecipeDraftEntity
```

这里有一个重要的分层原则：

> 原生平台负责“看懂图片中的文字”，Domain 负责“理解这些文字在菜谱中的位置和含义”。

因此 Vision 和 ML Kit 不需要知道什么是食材、步骤或菜名；它们只负责返回 OCR
结果。菜谱含义由 Flutter Domain 层继续处理。

## 二、Flutter 如何调用原生 OCR

`PlatformOcrAdapter` 使用固定的 MethodChannel 名称：

```text
kitchen_notes/import_ocr
```

调用的方法名是：

```text
recognizeDocument
```

发送的数据包括：

```text
path                   图片路径
rotationQuarterTurns   用户记录的旋转次数
```

其中图片路径必须是 App 自己保存的受控路径，不能依赖系统相册提供的临时路径。
这样后台 OCR、App 重启和任务恢复时，图片仍然可读。

Flutter 侧不直接处理图片像素，而是等待原生层返回这样的结构：

```json
{
  "width": 1000,
  "height": 2000,
  "lines": [
    {
      "id": "line-0",
      "text": "番茄炒蛋",
      "confidence": 0.98,
      "left": 0.1,
      "top": 0.05,
      "right": 0.8,
      "bottom": 0.1
    }
  ]
}
```

之后，适配器把每一项转换为 `OcrLineEntity`，把整页转换为 `OcrPageEntity`。

## 三、iOS 如何得到文字行和坐标

iOS 使用 Apple Vision 的 `VNRecognizeTextRequest`。

Vision 会返回多个 `VNRecognizedTextObservation`。每个 Observation 表示图片中
一个被识别出的文字区域。项目取其中最可信的候选：

```text
observation.topCandidates(1).first
```

因此每个 OCR 行可以得到：

```text
candidate.string       文字内容
candidate.confidence   识别置信度
observation.boundingBox 文字区域
```

Vision 的 `boundingBox` 已经是 0 到 1 的相对坐标，但坐标原点在左下角：

```text
(0, 0) 在左下角
```

而项目的 Domain 坐标统一采用左上角原点：

```text
(0, 0) 在左上角
```

因此 iOS 需要翻转垂直坐标：

```text
left   = Vision minX
right  = Vision maxX
top    = 1 - Vision maxY
bottom = 1 - Vision minY
```

例如 Vision 返回：

```text
minX = 0.10
maxX = 0.80
minY = 0.70
maxY = 0.85
```

转换成 Domain 坐标后：

```text
left   = 0.10
top    = 0.15
right  = 0.80
bottom = 0.30
```

这表示文字区域位于图片上方约 15% 到 30% 的位置。

Vision 识别在后台队列执行，完成后回到主线程调用 MethodChannel 的 `result`，
把结果交还给 Flutter。

## 四、Android 如何得到文字行和坐标

Android 使用 Google ML Kit 的中文识别器：

```text
ChineseTextRecognizerOptions
```

ML Kit 的结果有两层：

```text
textBlocks
  └── lines
```

项目只保留 `lines`。原因是后续菜谱布局分析需要知道每一行文字的位置，不需要
保存 ML Kit 的 Block 容器。

Android 返回的文字行包含：

```text
line.text
line.boundingBox
```

Android 的 `boundingBox` 是像素坐标，并且原点已经在左上角。例如：

```text
图片尺寸：1000 × 2000
像素矩形：left=100, top=400, right=900, bottom=500
```

需要除以图片宽高，转换成项目使用的相对坐标：

```text
left   = 100 / 1000 = 0.10
top    = 400 / 2000 = 0.20
right  = 900 / 1000 = 0.90
bottom = 500 / 2000 = 0.25
```

Android 不需要像 iOS 那样翻转上下方向。

## 五、为什么要使用归一化坐标

项目不直接保存像素坐标，而是保存 0 到 1 的比例：

```text
left、right   相对于图片宽度
top、bottom   相对于图片高度
```

这样做有三个好处：

1. iOS 和 Android 可以使用相同的 Domain 模型。
2. 不同分辨率的图片可以使用相同的布局算法。
3. 图片重新展示或缩放时，不需要重新计算文字位置。

`OcrRectValueObject` 还提供几个常用计算：

```text
centerX = (left + right) / 2
centerY = (top + bottom) / 2
height  = bottom - top
```

这些值会用于判断文字是否在同一行、哪一列以及上下间距。

## 六、为什么不能只保存 OCR 纯文本

如果只保存：

```text
番茄
2个
鸡蛋
3个
```

系统无法知道：

- `番茄` 和 `2个` 是否属于同一行
- `2个` 是番茄的用量还是鸡蛋的用量
- 图片是单列还是双列
- 哪些文字是顶部标题，哪些文字是平台按钮

保存坐标后，系统可以看到：

```text
番茄   centerX=0.20, centerY=0.30
2个    centerX=0.75, centerY=0.30
鸡蛋   centerX=0.20, centerY=0.36
3个    centerX=0.75, centerY=0.36
```

于是布局分析可以推断：

```text
番茄 2个
鸡蛋 3个
```

这也是 OCR 结果中同时保存文字、坐标和置信度的原因。

## 七、`OcrPageEntity.plainText` 做了什么

原生 OCR 返回顺序不能完全当作阅读顺序。不同平台和双列布局可能导致返回顺序
不同，因此 `OcrPageEntity.plainText` 会先按：

1. `top` 从上到下
2. `left` 从左到右

排序，然后用换行拼接文字。

它适合生成基础纯文本和兼容旧任务，但它不是完整的版面分析。更复杂的双列配对、
食材用量匹配、跨页去重和平台噪声过滤由 `OcrLayoutAnalyzerService` 完成。

## 八、从 OCR 行到菜谱草稿

`ImportPipeline` 识别完所有图片后，会创建一个 `OcrDocumentEntity`：

```text
OcrDocumentEntity
  └── pages
       └── OcrPageEntity
            └── lines: OcrLineEntity[]
```

随后：

1. 汇总 OCR 纯文本，保存到导入任务。
2. 保存每一页完整 OCR 结果，包括坐标和置信度。
3. `OcrLayoutAnalyzerService` 恢复图片中的版面关系。
4. `LocalRecipeStructurerService` 识别菜名、食材、准备工作和步骤。
5. 生成 `RecipeDraftEntity`。
6. 将草稿保存为 `awaitingReview`，等待用户确认。

草稿中的字段还会保存 OCR 证据，因此审核页可以说明某个菜名、食材或步骤来自
哪一页、哪一行图片文字。

## 九、当前实现需要注意的地方

### 1. 旋转参数还没有在原生层使用

Dart 调用时会传递：

```text
rotationQuarterTurns
```

但当前 iOS Vision 和 Android ML Kit 的实现都没有读取它。也就是说，是否已经
在 OCR 前应用旋转，需要结合图片编辑或预处理流程继续确认。不能仅凭这个参数名
判断原生 OCR 已经旋转图片。

### 2. 行 ID 目前是本页结果中的序号

iOS 和 Android 都使用：

```text
line-0
line-1
line-2
```

它可以在一次 OCR 结果和草稿证据中定位行，但不是跨次 OCR 永久稳定的 ID。图片
重新识别后，行顺序变化可能导致 ID 变化。

### 3. iOS 和 Android 的识别结果不是完全相同

Vision 和 ML Kit 的分行、语言纠正、置信度和返回顺序由各自平台决定。项目通过：

- 统一的 MethodChannel 返回结构
- 统一的 0 到 1 坐标
- Domain 层布局分析

把平台差异限制在适配器边界内。

## 十、通过 HTTPS 链接导入菜谱

图片导入和链接导入最后都会进入 `LocalRecipeStructurerService`，但前面的准备过程
不同。HTTPS 导入的目标是先把网页转换成普通文字，再交给菜谱结构化器。

### 1. “原始输入”“URL”和“网页正文”不是同一个东西

用户输入看起来可能只是一个 URL：

```text
https://example.com/recipe
```

但系统允许的输入不一定只有 URL。例如系统分享通常会同时包含标题、分享文案和
URL：

```text
标题：番茄炒蛋
分享文案：今天晚饭做这个
链接：https://example.com/recipe
```

因此任务中有几个不同用途的值：

| 概念 | 含义 | 用途 |
| --- | --- | --- |
| `originalText` | 用户最初交给 App 的全部文字 | 保留原始输入，支持恢复和重新处理 |
| `detectedPublicUrl` | 从 `originalText` 中找到的第一个 URL | 作为网页读取地址和来源地址 |
| 网页正文 | 通过 URL 读取并提取出的内容 | 提供给菜谱结构化器 |
| 最终 `text` | 原始分享文案与网页正文合并后的文字 | 实际交给结构化器 |

`originalText` 不会被网页正文覆盖。即使网页读取失败，原始输入仍然保留在任务中。

### 2. URL 检测不等于公开性验证

创建文本任务时，Repository 只做非常初步的 URL 检测：

```text
从原始文字中寻找 http:// 或 https:// 开头的地址
```

检测到 URL 后保存到 `detectedPublicUrl`。此时只能说明：

```text
输入中包含一个看起来像 URL 的字符串
```

还不能说明它一定公开、安全或无需登录。真正的验证发生在
`SafePublicContentExtractor` 开始访问网页时。

### 3. 什么条件下才算可以导入的公开 URL

当前实现会检查：

1. 地址必须使用 HTTPS。
2. 域名必须能够解析出地址。
3. 解析结果不能是本机、局域网或其他私有地址。
4. 每次 HTTP 重定向后都要重新检查目标地址。
5. 最多允许 3 次重定向。
6. 响应类型必须是 `text/html`。
7. 网页内容不能超过 2 MB。

因此这里的“公开”不是“字符串以 `https://` 开头”，而是：

```text
HTTPS
  + 地址可安全访问
  + 不指向本机或私网
  + 能够返回网页 HTML
  + 内容大小在限制内
```

当前实现并不处理需要登录后才能读取的网页。登录页通常无法提取出可用的菜谱内容，
也可能因为返回内容不符合预期而失败。

### 4. 为什么 HTTP 会先尝试升级为 HTTPS

当 Repository 发现输入是：

```text
http://example.com/recipe
```

它不会向这个 HTTP 地址发送请求，而是先在本地转换为：

```text
https://example.com/recipe
```

原因是导入器不希望通过未加密的 HTTP 传输网页内容。HTTP 内容可能被网络中的中间
设备读取或修改，而这些内容随后会参与菜谱草稿生成。

所以实际策略是：

```text
检测到 http://
  ↓
本地尝试替换为 https://
  ↓
按 HTTPS 规则验证和访问
```

如果网站确实支持 HTTPS，导入可以继续；如果网站只支持 HTTP，升级后的地址无法访问，
任务会失败。HTTP 不是被立即删除，而是被当作“可能存在 HTTPS 版本”的地址尝试处理。

### 5. 纯 URL 导入的实际过程

用户只粘贴：

```text
https://example.com/recipe
```

任务刚创建时大致是：

```text
originalText       = https://example.com/recipe
detectedPublicUrl  = https://example.com/recipe
status             = queued
```

此时还没有访问网页。

流水线开始后：

```text
queued
  ↓
extracting
  ↓
读取网页 HTML
  ↓
提取菜谱文字
  ↓
structuring
  ↓
生成草稿
  ↓
awaitingReview
```

网页内容会按以下优先级提取：

```text
Recipe JSON-LD
  ↓ 没有
Article JSON-LD
  ↓ 没有
Open Graph 元数据
  ↓ 没有
<title>、<article> 或 <main> 中的普通正文
```

例如网页中的结构化数据可能被转换成：

```text
番茄炒蛋
食材：
番茄 2个
鸡蛋 3个
步骤：
1. 番茄切块
2. 鸡蛋炒熟
```

因为用户原始输入只有 URL，流水线会把网页正文作为主要结构化文字，但仍然保留：

```text
originalText      = 原始 URL
detectedPublicUrl = 原始 URL
最终 text         = 网页正文
```

URL 不会作为菜名候选参与解析，但会保存在草稿来源快照中。

### 6. URL 和分享文案同时存在时

如果用户分享的是：

```text
这个做法很简单，今晚试试：
https://example.com/recipe
```

网页正文提取后，流水线会先从原文中移除 URL，再把剩余文案和网页正文拼接：

```text
这个做法很简单，今晚试试：

番茄炒蛋
食材：
番茄 2个
鸡蛋 3个
步骤：...
```

这里：

- 原始分享内容：用户提供的文案和 URL，完整保存。
- 网页正文：通过 URL 从网页读取的文字。
- 最终 `text`：用于结构化的组合结果。

### 7. 非公开或不可读取 URL 的处理

以下情况会导致网页提取失败：

```text
指向 localhost 或私网地址       unsafeUrl
不是 HTTPS 地址                  unsupportedUrl
重定向次数过多                   tooManyRedirects
网页不是 HTML                     nonHtml
网页超过 2 MB                     contentTooLarge
网络不可达                        unreachable
读取超时                          timeout
```

流水线会捕获这些错误，把任务保存为：

```text
status      = failed
errorCode   = 对应错误分类
errorMessage = 面向用户的说明
```

但以下信息不会丢失：

```text
originalText
detectedPublicUrl
```

这意味着“保留原文”是指原始输入仍然可以用于重试或后续人工处理，并不表示当前
`process` 调用会自动跳过网页错误、继续用原文生成草稿。按照当前实现：

```text
网页提取失败
  ↓
任务进入 failed
  ↓
保留原始输入
  ↓
等待用户重试或人工处理
```

## 十一、建议的阅读顺序

如果要继续理解这部分代码，可以按下面顺序阅读：

1. `PlatformOcrAdapter.recognize`
2. `AppDelegate.swift` 中的 `recognizeDocument`
3. `MainActivity.kt` 中的 `recognizeDocument`
4. `OcrRectValueObject` 和 `OcrLineEntity`
5. `OcrPageEntity.plainText`
6. `OcrLayoutAnalyzerService.analyze`
7. `ImportPipeline.process`
8. `LocalRecipeStructurerService.structure`

先理解“平台如何返回一行文字”，再理解“Domain 如何用坐标恢复菜谱版面”，会比
直接从菜谱字段解析规则开始更容易。

如果重点学习 HTTPS 导入，可以继续阅读：

1. `ImportTaskRepositoryImpl.createTextTask`
2. `ImportTaskRepositoryImpl._detectedPublicUrl`
3. `SafePublicContentExtractor.extract`
4. `SafePublicContentExtractor._validatePublicHttps`
5. `SafePublicContentExtractor.extractRecipeTextFromHtml`
6. `ImportPipeline.process` 中的网页提取分支
