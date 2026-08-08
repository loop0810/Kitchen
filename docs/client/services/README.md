# 厨房手记：基础服务目录

## 1. 文档目的

基础服务是多个 Feature 复用的能力边界，用于明确职责、接口、状态和降级策略。
“服务”不自动意味着：

- 必须建立独立 Flutter package。
- 必须建立后端微服务。
- 必须通过网络访问。
- 必须一次性全部实现。

当一项能力需要被多个 Feature 使用、具有独立生命周期、需要替换实现或需要
单独测试时，才考虑进一步拆包。

## 2. 服务地图

```text
Feature
├── 菜谱库 / 编辑器 / 导入箱
│
├── LocalDataService
├── MediaAssetService
├── ImportPipelineService
│   └── AiOrchestrationService
│       └── EntitlementQuotaService
├── TemplateService
│   └── EntitlementQuotaService
├── SearchService
└── BackupSyncService
```

## 3. 服务清单

| 服务 | 主要职责 | 阶段 | 文档 |
| --- | --- | --- | --- |
| 本地数据服务 | 数据库、事务、迁移、Repository | 已开始 | `LOCAL_DATA_SERVICE.md` |
| 媒体资源服务 | 图片、缩略图、模板资源和清理 | 近期 | `MEDIA_ASSET_SERVICE.md` |
| 导入处理服务 | 分享接收、任务状态机和恢复 | MVP | `IMPORT_PIPELINE_SERVICE.md` |
| AI 编排服务 | 未来付费 AI 的授权、路由和草稿 | 后续 | `AI_ORCHESTRATION_SERVICE.md` |
| 模板服务 | 模板注册、渲染、缓存和版本 | 当前核心 | `TEMPLATE_SERVICE.md` |
| 搜索服务 | 本地索引与未来联合搜索 | 已开始 | `SEARCH_SERVICE.md` |
| 权益与额度服务 | 未来 AI 付费权益和模板权益 | 后续 | `ENTITLEMENT_QUOTA_SERVICE.md` |
| 备份与同步服务 | 本地逻辑导出、覆盖恢复、云备份和同步 | 本地导出恢复首版已实现 | `BACKUP_SYNC_SERVICE.md` |

## 4. 通用服务约束

- Feature 依赖抽象，不直接依赖平台或远端 SDK。
- 本地能力优先，网络能力提供明确降级。
- 客户端不保存服务端密钥。
- 服务返回业务可理解的 Result 和 Failure，不泄漏底层异常。
- 长任务具有可观察状态、取消、重试和恢复策略。
- 写入操作明确事务和幂等边界。
- 用户数据和分析数据分开。
- 服务接口保持小而明确，不建立全局万能 Manager。

## 5. 依赖原则

推荐方向：

```text
Feature → Domain Port
Data / Platform / Remote Adapter → Domain Port
App → 依赖装配
```

跨服务协作由 UseCase 或根 App 协调，不能通过全局 EventBus 隐式串联。

## 6. 何时拆成独立 package

满足以下两项以上时再评估拆包：

- 被两个或更多 Feature 使用。
- 需要替换本地、端侧或远端实现。
- 有独立数据模型和迁移。
- 需要单独发布或大量独立测试。
- 依赖大型平台 SDK，需要隔离传递依赖。
- 生命周期与调用方明显不同。

仅有一个类或一个页面使用时，优先保留在所属 Feature 或现有 Data package。

## 7. 文档维护

- 服务职责改变时更新对应服务文档。
- 当前版本范围改变时同步 `../../product/MVP_REQUIREMENTS.md`。
- 用户行为改变时同步相应专项需求文档。
- 新增服务前先确认现有服务不能承担，避免服务碎片化。
