# 厨房手记文档导航

本目录保存 monorepo 的长期文档。阅读时先判断任务范围，只加载默认文档；命中跨端、产品范围、安全或数据迁移条件时，再读取条件文档。禁止默认遍历整个 `docs/`。

## 权威分区

| 分区 | 权威范围 | 不负责 |
| --- | --- | --- |
| [`product/`](product/README.md) | 产品目标、当前版本范围、用户行为和菜谱领域需求 | Flutter、FastAPI 或部署实现 |
| [`contracts/`](contracts/README.md) | 客户端与服务端共同依赖的 API、标识符、错误、幂等和同步语义 | 单端内部实现 |
| [`client/`](client/README.md) | Flutter 架构、端侧服务、视觉和工程工作流 | 服务端内部实现 |
| [`server/`](server/README.md) | Python/FastAPI 架构、模块、数据库、安全和运维 | Flutter 页面与端侧细节 |
| [`learning/`](learning/README.md) | 完成迭代后的学习复盘和代码导航 | 权威需求或接口定义 |
| [`decisions/`](decisions/README.md) | 已确认且需要长期保留的架构与产品决策及原因 | 任务进度 |

`AGENTS.md` 保留在它约束的代码目录旁；变更计划与规格保留在根 [`openspec/`](../openspec/)；项目启动说明保留在对应项目 README。

## 按任务阅读

| 任务范围 | 默认读取 | 条件读取 | 默认排除 |
| --- | --- | --- | --- |
| 客户端内部实现 | `client/AGENTS.md`、`client/README.md`、当前 change、相关客户端文档 | 涉及共享字段时读对应 contract；改变用户行为或版本范围时读 product | `server/`、无关产品全文 |
| 服务端内部实现 | `server/AGENTS.md`、`server/README.md`、当前 change、相关服务端模块文档 | 涉及 HTTP/共享模型时读 contract；改变用户行为或版本范围时读 product | `client/`、Figma、Flutter 细节 |
| 共享接口或同步 | 当前 change、相关 `contracts/` 文档、两端受影响边界 | 产品语义、安全、迁移与兼容文档 | 无关模块文档 |
| 产品需求或版本范围 | `product/README.md` 及对应权威需求、当前 change | 受影响的 contract 和两端入口 | 无关实现细节 |
| 腾讯云或部署 | `server/operations`、`infra/`、当前 change | 安全、数据库、备份 contract | 客户端视觉与本地功能细节 |
| 学习复盘 | 对应 change、最终代码与测试、学习模板 | 相关 contract、decision | 全量需求复制 |

## 升级读取条件

出现以下任一情况时，任务不能继续停留在单端上下文：

- HTTP 请求或响应、共享标识符、错误语义、幂等键或同步规则变化。
- 用户可见行为、MVP 范围、隐私授权或商业权益变化。
- 数据 schema、迁移、兼容窗口、删除策略或安全边界变化。
- 一个决策同时约束客户端、服务端或基础设施中的两个以上范围。

只需定位术语时先使用 `rg` 搜索文件和标题，再读取命中的最小文档。
