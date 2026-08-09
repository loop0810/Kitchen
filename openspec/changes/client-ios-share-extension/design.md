## Context

现有导入流程已经以持久化 ImportTask 作为内容整理入口，Android 分享通过原生暂存目录和版本化清单交给主 App。iOS 需要独立的 Share Extension 与 App Group 共享容器，但应保持同一套导入任务、受控媒体目录和恢复语义。详见 proposal.md 与 `docs/client/services/IMPORT_PIPELINE_SERVICE.md`、`docs/decisions/DECISION_LOG.md` 的 D-021/D-022。

## Goals / Non-Goals

**Goals:**

- 建立 iOS 原生分享扩展到 Flutter 主 App 的可靠交接链路。
- 让文字、HTTPS 链接、单图和多图在冷启动、重复通知和主 App 中断时仍可恢复。
- 让扩展只负责轻量接收与持久化，复用主 App 现有导入处理能力。
- 明确 App Group、共享清单、文件复制、幂等消费和清理的生命周期。

**Non-Goals:**

- 不在 Share Extension 中运行 OCR、网页提取、结构化解析或完整编辑 UI。
- 不新增服务端 API、云端存储、登录流程或账号数据绑定。
- 不改变 Android Share Intent 的既有协议。
- 不处理来源平台的登录、反爬或版权限制。

## Decisions

### 1. 使用 App Group 暂存，而不是直接把系统 URL 交给 Flutter

Share Extension 先把可读取内容复制到 App Group 下的受控暂存目录，再原子写入版本化 manifest。这样可以跨扩展进程、主 App 冷启动和系统授权生命周期保存原始内容。直接传递 `NSItemProvider` 或临时 URL 会在扩展结束后失效。

备选方案是使用自定义 URL Scheme 立即唤起主 App；它只能解决前台接管，不能覆盖主 App 未运行、系统终止或大文件异步复制，因此只作为可选的加速通知，不作为数据交接协议。

### 2. 一次分享对应一个稳定消费标识

manifest 使用随机高熵 `shareId`，并以原子写入完成标记区分“正在复制”和“可消费”。主 App 以 `shareId` 和本地接管记录实现幂等，避免前台通知、冷启动扫描和重试同时创建多个 ImportTask。

### 3. 先复制到主 App 受控媒体目录，再确认清单

主 App 接管时先验证 manifest、媒体摘要、数量和受控路径，再将媒体复制或移动到现有受控媒体目录，并在同一导入任务事务中保存引用。只有任务和引用成功持久化后才删除 App Group 暂存；任何失败都保留原始暂存以便恢复。

### 4. 共享 Dart 领域模型，平台层只负责载荷交接

新增 iOS 平台适配器应把原生清单转换为现有 Import Repository 可接受的输入，不让 `kitchen_import` 依赖 iOS 原生类型，也不复制 Android 的业务解析逻辑。根 App 统一负责启动扫描、任务创建、确认和清理。

### 5. 以系统声明的 UTI 类型做白名单接收

扩展只声明文字、URL 和常见图片类型，并对实际载荷再次校验。无法读取的类型、超出大小限制或不符合清单约束的内容进入失败状态，不允许通过宽泛类型猜测为图片或链接。

## Risks / Trade-offs

- [App Group entitlement 或签名配置不一致] → 在 Debug、Profile 和 Release 三种配置中统一 capability，增加真实设备冷启动验收；扩展不应默认为可用而静默丢弃内容。
- [分享扩展内存和执行时间有限] → 只做流式/分块复制和清单写入，禁止 OCR、网页请求和大对象一次性加载。
- [多图分享顺序依赖分享方实现] → 按系统提供的 item 顺序记录；无法确认顺序时保留原始索引并在导入箱允许用户调整。
- [App Group 暂存长期占用空间] → 清单包含创建时间和状态；只清理由主 App 确认成功或用户明确删除的项目，过期清理必须保留失败诊断信息。
- [主 App 接管和清理之间发生中断] → 任务创建与媒体引用采用可恢复状态；清理是幂等的后续动作，不能作为任务成功的前置条件。

## Migration Plan

1. 新增 iOS Share Extension target、App Group capability 和原生 manifest/暂存适配器。
2. 在主 App 启动与恢复前台流程中接入扫描、校验、导入任务创建和清理。
3. 先以文字、链接、单图、多图和冷启动场景在真实设备验证，再开放扩展显示。
4. 若扩展不可用，保留现有 App 内导入入口；关闭扩展 target 不影响既有本地导入任务。

当前由于 Personal Team 不支持相关签名能力，Runner 暂不嵌入 Share Extension，也不声明
App Groups 或 Sign in with Apple entitlement；扩展源代码和平台适配器保留，待开发者团队
可用后恢复工程引用和主 App 接管入口。

## Open Questions

- App Group 标识符应在 Bundle ID 最终确定后登记为项目配置，不能写死到共享业务文档或测试数据中。
