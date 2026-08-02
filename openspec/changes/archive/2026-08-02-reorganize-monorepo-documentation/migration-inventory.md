# 文档与 OpenSpec 迁移盘点

## 基线

- 盘点日期：2026-08-02。
- Git 状态：Flutter 工程已由仓库根移动到 `client/`，但尚未暂存，因此 Git 当前显示原路径删除和 `client/` 未跟踪。
- 内容校验：Git `HEAD` 中 17 份 `docs/**/*.md` 与当前 `client/docs/**/*.md` 对应文件的 blob 哈希全部一致。
- OpenSpec 校验：Git `HEAD` 中 `refocus-mvp-recipe-ocr` 的 6 个变更文件与 `client/openspec` 副本哈希全部一致。
- 配置校验：根与客户端的 `openspec/config.yaml` 哈希一致。
- 变更冲突：根只有 `reorganize-monorepo-documentation`；嵌套客户端只有 `refocus-mvp-recipe-ocr`，不存在同名冲突。
- 链接基线：旧文档路径引用集中在 `client/README.md`、`client/AGENTS.md`、`client/packages/AGENTS.md` 和旧变更 proposal；迁移后必须统一修复。
- Rename 基线：未暂存状态下 Git 尚未将根到 `client/` 识别为 rename；最终以 `git diff --no-index` 内容等价、`git status` 和 `git diff --summary` 共同复核。

## 持久文档分类

| 当前路径 | 权威类型 | 迁移动作 | 目标路径 |
| --- | --- | --- | --- |
| `client/docs/README.md` | 旧客户端文档入口 | merge | `docs/README.md` 与各分区索引 |
| `client/docs/PRODUCT_REQUIREMENTS.md` | 共享产品 | move unchanged | `docs/product/PRODUCT_REQUIREMENTS.md` |
| `client/docs/MVP_REQUIREMENTS.md` | 共享产品 | move unchanged | `docs/product/MVP_REQUIREMENTS.md` |
| `client/docs/RECIPE_REQUIREMENTS.md` | 共享产品 | move unchanged | `docs/product/RECIPE_REQUIREMENTS.md` |
| `client/docs/FIGMA_DESIGN_BRIEF.md` | 客户端视觉实现 | move unchanged | `docs/client/design/FIGMA_DESIGN_BRIEF.md` |
| `client/docs/CODEX_WORKFLOW.md` | 客户端工程学习 | move unchanged | `docs/client/workflow/CODEX_WORKFLOW.md` |
| `client/docs/NAMING_CONVENTIONS.md` | 客户端工程约束 | move unchanged | `docs/client/engineering/NAMING_CONVENTIONS.md` |
| `client/docs/DECISION_LOG.md` | 跨项目决策 | move unchanged | `docs/decisions/DECISION_LOG.md` |
| `client/docs/services/README.md` | 客户端服务入口 | move and re-index | `docs/client/services/README.md` |
| `client/docs/services/LOCAL_DATA_SERVICE.md` | 客户端实现 | move unchanged | `docs/client/services/LOCAL_DATA_SERVICE.md` |
| `client/docs/services/IMPORT_PIPELINE_SERVICE.md` | 客户端实现 | move unchanged | `docs/client/services/IMPORT_PIPELINE_SERVICE.md` |
| `client/docs/services/MEDIA_ASSET_SERVICE.md` | 当前客户端实现 | move unchanged | `docs/client/services/MEDIA_ASSET_SERVICE.md` |
| `client/docs/services/TEMPLATE_SERVICE.md` | 当前客户端实现 | move unchanged | `docs/client/services/TEMPLATE_SERVICE.md` |
| `client/docs/services/SEARCH_SERVICE.md` | 当前客户端实现 | move unchanged | `docs/client/services/SEARCH_SERVICE.md` |
| `client/docs/services/AI_ORCHESTRATION_SERVICE.md` | 混合边界 | move, then split | 客户端说明保留；共享请求与幂等语义进入 `docs/contracts/AI_REQUEST_CONTRACT.md` |
| `client/docs/services/BACKUP_SYNC_SERVICE.md` | 混合边界 | move, then split | 客户端说明保留；个性配置同步语义进入 `docs/contracts/PERSONALIZATION_SYNC_CONTRACT.md` |
| `client/docs/services/ENTITLEMENT_QUOTA_SERVICE.md` | 混合边界 | move, then split | 客户端说明保留；权益账本语义进入 `docs/contracts/ENTITLEMENT_CONTRACT.md` |
| `client/README.md` | 客户端项目入口 | retain locally and relink | `client/README.md` |
| `client/ios/**/README.md` | 平台资源说明 | retain locally | 原路径 |
| `client/**/AGENTS.md` | 就近工程约束 | retain locally and relink | 原路径 |

## OpenSpec 迁移

| 当前路径 | 动作 | 目标路径 | 安全条件 |
| --- | --- | --- | --- |
| `client/openspec/changes/refocus-mvp-recipe-ocr` | move intact | `openspec/changes/refocus-mvp-recipe-ocr` | 无同名目录；移动后 status 与 strict validate 通过 |
| `client/openspec/config.yaml` | remove duplicate after verification | `openspec/config.yaml` | 两份配置哈希一致 |
| `client/openspec/changes/archive` | remove empty duplicate | `openspec/changes/archive` | 根 archive 已存在且二者均无文件 |

## 迁移验收

- 所有目标分区都有说明权威范围、排除范围和阅读者的索引。
- 旧路径引用扫描为空，或只出现在记录历史路径的迁移说明中。
- 根 `openspec list` 能同时看到文档治理与客户端变更。
- 两个变更都通过严格校验。
- 产品文档机械移动阶段与 Git `HEAD` 内容一致；后续契约提取是独立、可审阅的语义编辑。

## 阅读路由演练

| 代表任务 | 默认上下文 | 升级上下文 | 结果 |
| --- | --- | --- | --- |
| 调整 Flutter 菜谱卡片布局 | 根与客户端 AGENTS、当前 change、客户端相关设计/组件约束 | 用户行为变化时再读 product | 不读取 server，符合最小集 |
| 增加 Vapor 健康检查 | 根与服务端 AGENTS、当前 change、服务端入口 | 无 | 不读取 client/product，符合最小集 |
| 修改个性配置 revision | 当前 change、个性同步 contract、两端适配边界 | 并发或迁移变化时读安全/数据文档 | 同时覆盖共享权威与受影响端 |
| 调整 MVP 是否包含云同步 | product 总纲与 MVP、当前 change、decision | 范围确认后读取备份 contract 与两端入口 | 先产品后实现，符合升级条件 |

## 服务端迭代完成流程演练

1. 假设 `server-example-change` 的实现与验证任务全部完成。
2. 根 `AGENTS.md` 和 `server/AGENTS.md` 都会将完成流程路由到
   `docs/learning/server/README.md`。
3. 有学习增量时，从 `iterations/TEMPLATE.md` 建立带序号的记录，并链接 change、
   contract、最终代码、migration 和测试。
4. 只有确实没有新概念、权衡、失败教训或可复用流程时，才在 change tasks 完成说明中
   写明“学习记录豁免”及原因。
5. 归档前检查学习记录或豁免二者之一存在；演练结果满足规格的两个出口，且不会要求
   本次非服务端文档治理 change 创建伪学习记录。
