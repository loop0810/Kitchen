# Codex 学习工作流

本文档用于通过“厨房手记”项目练习 Codex CLI 和 VS Code Codex 扩展。

## 不同使用界面的分工

### Codex CLI

适合：

- 理解整个仓库和依赖关系；
- 执行跨文件重构；
- 运行代码生成、静态检查和测试；
- 查看工作区差异并执行代码审查；
- 恢复之前的开发会话；
- 将可重复工作写成脚本或自动化流程。

### VS Code Codex 扩展

适合：

- 针对当前打开文件或选中代码提问；
- 实现范围明确的局部修改；
- 在编辑器旁检查改动；
- 调试具体 Widget、Provider 或测试；
- 边看源码边学习不熟悉的 Flutter API。

### ChatGPT / Codex 桌面端

适合：

- 产品需求讨论；
- 架构设计和较长的方案比较；
- 视觉方向、参考图和原型讨论；
- 长周期任务协调。

CLI 和 IDE 扩展都会读取项目中的 `AGENTS.md`，因此不需要分别维护两套
工程规则。

## 分层 AGENTS.md

项目约束按作用域分层：

```text
AGENTS.md
└── packages/AGENTS.md
    ├── kitchen_recipe_data/AGENTS.md
    ├── kitchen_recipe_domain/AGENTS.md
    └── kitchen_design_system/AGENTS.md
```

- 根文件保存所有任务都需要的架构红线、验证和修改纪律。
- `packages/AGENTS.md` 保存 package 公共 API、依赖和命名规则。
- 组件子文件保存 Drift、纯 Dart 或视觉系统等专项规则。
- 从组件目录启动 Codex 时，会按根目录到当前目录的顺序合并约束。
- 从项目根目录启动时，根文件要求在修改对应组件前主动读取子级约束。

这种结构避免无关任务长期携带数据库等专项说明，同时让规则靠近实际代码。

## 项目开始前

当前项目应纳入 Git 管理，以便查看差异、使用 `/review` 并建立可恢复的
开发检查点。

```sh
cd "/Users/loop/Desktop/My App"
git init
git add .
git commit -m "chore: establish Flutter MVP baseline"
```

执行前应先确认 `.gitignore` 没有遗漏密钥、签名文件或构建产物。

## CLI 基础练习

在项目根目录启动：

```sh
codex
```

建议依次练习：

1. `/status`：查看当前会话、模型和权限状态。
2. `总结你读取到的 AGENTS.md 约束，不修改文件。`
3. `/plan`：为“组件化 recipe domain”生成实施计划。
4. `/diff`：查看 Codex 完成修改后的工作区差异。
5. `/review`：对未提交改动执行一次代码审查。
6. `codex resume`：退出后恢复本项目最近的会话。

`/init` 会在当前目录生成 `AGENTS.md` 脚手架。本项目已经包含定制后的
`AGENTS.md`，因此现在不需要再次执行；可以在临时练习目录中运行它来观察
默认内容。

## VS Code 扩展练习

1. 使用 VS Code 打开项目根目录。
2. 打开 Codex 侧栏。
3. 打开
   `packages/kitchen_recipe_data/lib/src/kitchen_recipe_data_recipe_repository_impl.dart`，
   将文件加入当前对话。
4. 询问：

   > 解释这个 Repository 当前同时承担了哪些职责，并给出拆分到 domain 与
   > data package 的方案。只解释，不修改。

5. 选中 `_parseIngredient`，询问：

   > 为这个方法补充覆盖中文用量格式的单元测试，不修改生产逻辑。

6. 检查编辑器内 diff，确认后再保留修改。

## 推荐的单个需求开发循环

```text
需求文档确认
→ 让 Codex 输出计划
→ 人工检查组件边界
→ Codex 实现一个小切片
→ format / analyze / test
→ /diff
→ /review
→ 人工运行模拟器验收
→ Git commit
```

## 练习用提示词

### 解释架构

```text
阅读 AGENTS.md 和 MVP_REQUIREMENTS.md。
追踪“收藏菜谱”从 Widget 到数据库的完整调用链。
用文件和符号说明每一层职责，只解释，不修改代码。
```

### 规划组件化迁移

```text
根据 AGENTS.md 的目标依赖图，检查 `kitchen_recipe_domain` 与现有 Feature
之间的边界。
先输出迁移顺序、公共 API、风险和测试策略，不修改文件。
```

### 实现一个切片

```text
实现“为 `kitchen_recipe_domain` 增加一个 Recipe UseCase”这一个切片。
不要同时调整 UI。完成后运行相关测试，并解释 feature、domain、data
之间的依赖方向。
```

### 代码审查

```text
审查当前未提交修改，重点检查：
1. feature 是否跨包互相引用；
2. presentation 是否泄漏 Drift 类型；
3. Provider 生命周期是否合理；
4. 数据库迁移和测试是否完整。
只报告问题，不修改。
```

## 官方参考

- [Codex CLI](https://developers.openai.com/codex/cli)
- [Codex IDE extension](https://developers.openai.com/codex/ide)
- [AGENTS.md](https://developers.openai.com/codex/guides/agents-md)
- [Codex developer commands](https://developers.openai.com/codex/cli/slash-commands)
