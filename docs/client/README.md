# 客户端文档

## 权威范围

本分区面向 Flutter 客户端开发，包含端侧架构、离线数据、导入流水线、媒体、模板、搜索、视觉输入、命名规范和客户端学习工作流。

## 不负责

- FastAPI 服务端内部结构和腾讯云部署。
- 跨端字段、幂等及服务端权威状态；这些由 `docs/contracts` 定义。
- 产品范围；这些由 `docs/product` 定义。

## 阅读路由

- 修改端侧服务：从 `services/README.md` 进入，只读相关服务文档。
- 新增或重命名 Dart/Flutter 文件：读取 `engineering/NAMING_CONVENTIONS.md`。
- 视觉设计：读取 `design/FIGMA_DESIGN_BRIEF.md` 和相关设计系统约束。
- Codex/Flutter 学习流程：读取 `workflow/CODEX_WORKFLOW.md`。
- 涉及共享接口时再读取对应 contract；默认不读取 `docs/server`。
