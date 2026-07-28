# 厨房手记文档导航

## 产品与需求

| 文档 | 用途 |
| --- | --- |
| `PRODUCT_REQUIREMENTS.md` | 产品总纲、模块关系和长期规划 |
| `MVP_REQUIREMENTS.md` | 当前版本范围和验收标准 |
| `RECIPE_REQUIREMENTS.md` | 菜谱领域完整需求 |
| `FIGMA_DESIGN_BRIEF.md` | 手账菜谱第一轮视觉设计输入与验收 |
| `DECISION_LOG.md` | 已确认决策及原因 |

## 基础服务

入口：`services/README.md`

- `LOCAL_DATA_SERVICE.md`
- `MEDIA_ASSET_SERVICE.md`
- `IMPORT_PIPELINE_SERVICE.md`
- `AI_ORCHESTRATION_SERVICE.md`
- `TEMPLATE_SERVICE.md`
- `SEARCH_SERVICE.md`
- `ENTITLEMENT_QUOTA_SERVICE.md`
- `COOKING_RUNTIME_SERVICE.md`
- `BACKUP_SYNC_SERVICE.md`

服务文档描述能力边界，不自动要求建立同名 package 或后端微服务。

## 工程协作

| 文档 | 用途 |
| --- | --- |
| `CODEX_WORKFLOW.md` | Codex CLI 与 VS Code 学习流程 |
| `NAMING_CONVENTIONS.md` | Dart 与 Flutter 文件命名 |
| 根目录 `AGENTS.md` | 项目长期约束 |
| `packages/**/AGENTS.md` | 组件专项约束 |

## 按任务阅读

### 修改菜谱行为

1. `PRODUCT_REQUIREMENTS.md`
2. `MVP_REQUIREMENTS.md`
3. `RECIPE_REQUIREMENTS.md`
4. 与实现相关的服务文档

### 修改导入或 AI

1. `PRODUCT_REQUIREMENTS.md`
2. `MVP_REQUIREMENTS.md`
3. `services/IMPORT_PIPELINE_SERVICE.md`
4. `services/AI_ORCHESTRATION_SERVICE.md`
5. `services/ENTITLEMENT_QUOTA_SERVICE.md`

### 修改模板

1. `PRODUCT_REQUIREMENTS.md`
2. `RECIPE_REQUIREMENTS.md`
3. `FIGMA_DESIGN_BRIEF.md`
4. `services/TEMPLATE_SERVICE.md`
5. `packages/kitchen_design_system/AGENTS.md`

### 修改数据库

1. 相关需求文档
2. `services/LOCAL_DATA_SERVICE.md`
3. `packages/kitchen_recipe_data/AGENTS.md`

## 维护规则

- 产品方向变化：更新产品总纲和决策日志。
- 当前版本范围变化：更新 MVP 文档。
- 具体用户行为变化：更新对应专项需求。
- 基础能力边界变化：更新对应服务文档。
- 工程约束变化：更新 AGENTS.md 或专项约束。
- 避免在多个文档复制同一段详细规则；使用链接和权威文档归属。
