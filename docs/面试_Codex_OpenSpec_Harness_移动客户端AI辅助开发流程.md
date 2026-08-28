# Codex + OpenSpec + Harness：AI 辅助移动客户端开发流程

> 面试使用版本｜项目案例：厨房手记 Flutter + iOS/Android 客户端
>
> 本文用于面试表达和经验沉淀，不替代项目中的 `AGENTS.md`、OpenSpec Change 或产品/contract 权威文档。实际开发时，以项目约束和真实验证结果为准。

## 一句话介绍

我把 Codex 当作一个能够阅读代码、分析依赖、实现修改、运行验证和整理证据的工程协作者，但不把它当作需求、架构和最终验收的决策者。

为了让 AI 在移动客户端项目中可控、可验证、可回溯，我用 OpenSpec 管理“为什么做、做什么、明确不做什么、做到什么算完成”，用 Harness 管理“如何开始、如何执行、如何验证、什么时候必须停止”。

移动客户端的难点不只是把页面写出来，还包括状态和生命周期、离线与恢复、本地数据库迁移、iOS/Android 差异、权限、分享扩展、性能和真实设备行为。因此，AI 生成代码的速度不是唯一指标，改动边界、可观察行为和验证证据更重要。

## 面试 30 秒版本

在“厨房手记”项目中，我使用 Codex 辅助 Flutter 客户端开发，同时保留 iOS/Android 平台适配能力。项目包含本地 SQLite、Riverpod、GoRouter、组件化 package、图片导入、OCR 草稿和平台桥接。早期如果只给 AI 一个“大目标”，它很容易把页面、数据库、路由和平台代码一起改掉，也容易把“能编译”误认为“功能完成”。

后来我把流程分成两层：OpenSpec 是变更合同，包含 proposal、design、spec、tasks 和 Acceptance Criteria；Harness 是执行纪律，规定任务开始前读取什么、一次只做哪个 Task、怎样按影响范围验证、如何记录 Report，以及什么情况下只能标记为 PARTIAL、BLOCKED 或 FAILED。

Codex 负责在明确范围内分析和执行，Flutter/原生工具负责构建和运行验证，Git 保留可回溯节点。这样 AI 提高了实现和排查速度，但产品目标、架构边界、跨平台取舍和最终验收仍由开发者负责。

## 面试 3 分钟版本

我的问题背景是：移动端经常同时涉及 UI、状态管理、持久化、平台 API 和真实设备行为。以厨房手记为例，一条“从图片导入菜谱”的需求，实际上会经过图片保存、任务持久化、Flutter 状态、iOS Vision、Android ML Kit、OCR 坐标归一化、版面分析、草稿生成和审核页面。如果直接让 AI 一次性完成，出现问题后很难判断是产品理解、架构设计、平台差异、数据库恢复还是页面状态的问题。

因此我建立了一个 AI 可执行的工程流程。

第一步是把需求写成 OpenSpec Change。`proposal.md` 说明 Why、What Changes 和 Non-goals；`design.md` 记录分层、平台差异、替代方案和风险；`specs/` 描述用户或系统能够观察到的行为；`tasks.md` 把工作拆成带有 Scope、Out of Scope、Acceptance Criteria、Validation Level 和 Reset/Verification 的小任务。这样 Codex 不需要从一段模糊对话中猜完整系统。

第二步是建立 Harness。全局 Harness 负责 Change 选择、Task 生命周期、验证证据、Report 和停止规则；项目扩展只补充 Flutter/Android、iOS 平台桥接、Drift/SQLite、路由边界、命令和工作区规则。它相当于移动客户端的执行护栏，避免每个会话都依赖临时提醒。

第三步是按最小纵向切片实现。例如图片导入不会一开始就实现云端 AI、登录、同步和完整编辑器，而是先完成“图片保存到受控目录 → 持久化导入任务 → 原生 OCR 返回统一结构 → Domain 生成待审核草稿 → 页面可以恢复任务”的闭环。每个 Task 完成后，分别做结构检查、逻辑测试、模拟器或实体设备验证，观察冷启动、退后台、进程重启、失败重试和取消恢复，再写 Task Report。

第四步是把工具职责分开。Codex 读取上下文、搜索代码、实现切片、运行命令和整理差异；OpenSpec 提供变更和任务上下文；Flutter、Xcode、Gradle、模拟器和实体设备提供真实验证；Git 负责现场归属和 checkpoint。只有验收条件满足、适用验证真实执行且修改范围可解释时，任务才能标记为 DONE。

这套方法的价值是把 AI 从“代码生成器”变成“受约束的移动端工程执行者”：它可以快，但不能跳过需求、边界、平台差异、失败恢复和验收证据。

## 1. 为什么移动客户端特别需要这套流程

移动客户端的“完成”通常不是一个编译结果，而是多个状态和环境共同成立：页面能否进入、数据能否保存、进程被系统杀死后能否恢复、权限拒绝后能否降级、不同平台返回的数据是否能被统一处理、用户重复点击是否会产生重复任务。

| 风险 | 典型表现 | 流程中的解决方式 |
| --- | --- | --- |
| 需求模糊 | AI 自行补全登录、同步、云端 AI 等非当前版本能力 | proposal 写清 Why、Scope 和 Non-goals |
| 架构漂移 | Feature 直接访问数据库，或跨 Feature 互相引用 | design 固定 Feature、Domain、Data、平台适配和根 App 边界 |
| 状态不完整 | 只验证首次打开，没有验证退后台、重启、取消和重试 | Acceptance Criteria 明确状态机、恢复点和 Reset |
| 平台差异被掩盖 | iOS 和 Android 的坐标、权限、生命周期行为不一致 | 用平台适配器统一输出 Domain 模型，并分别验证 |
| “看起来完成” | 只跑 `analyze` 或编译，未验证真实交互 | Validation Level + 模拟器/设备验收 + Task Report |
| 数据损坏或重复 | OCR 失败后任务丢失，重复点击产生重复导入 | 先持久化任务、定义幂等键、记录失败和恢复策略 |
| 路由失控 | Feature 内硬编码全局路径，重构后导航悄悄失效 | 根 App 集中注册路由，Feature 使用类型化导航扩展 |
| 生成文件被误改 | AI 直接修改 `*.g.dart` 或 Xcode/Gradle 派生目录 | Harness 规定只改生成源，修改后重新生成并检查差异 |
| 工作区污染 | 把其他功能或构建产物一起提交 | 开始前记录 Git 现场，结束时按 Task Scope 归属文件 |

我会把 AI 的工作拆成四个可审计的问题：

1. 这次到底要改变什么？
2. 明确不改变什么？
3. 如何证明它已经在 iOS、Android 或本地数据边界上完成？
4. 如果失败，下一次接手需要知道什么？

## 2. OpenSpec、Harness 和移动端工具的分工

它们不是重复维护三套需求，而是处于不同层次。

| 层次 | 负责的问题 | 典型内容 |
| --- | --- | --- |
| 产品/架构文档 | 为什么做、用户需要什么、长期边界是什么 | MVP 范围、用户行为、架构决策、共享 contract |
| OpenSpec Change | 当前这次变更要交付什么 | proposal、design、specs、tasks |
| Task | 这一次只实现哪一个最小结果 | Scope、Out of Scope、Acceptance Criteria、Validation Level |
| Harness | 执行时必须遵守什么 | 开始条件、上下文读取、验证方式、停止条件、状态规则 |
| Task Report | 实际做了什么、验证出了什么 | 文件、行为、命令、结果、偏差、遗留问题 |
| Flutter / Xcode / Gradle / 设备 | 代码和平台行为是否真实成立 | 编译、静态检查、测试、模拟器、实体设备、日志 |
| Git checkpoint | 哪个阶段可以安全回溯 | 按 Change 和 Task 归属的提交 |

可以用一句话区分：

> OpenSpec 定义正确的目标，Harness 保证执行不偏离目标，平台工具证明移动端行为，Report 记录事实，Git 保留可回溯节点。

## 3. 一次完整的移动端开发流程

```text
用户需求 / 问题
   ↓
读取产品、架构、contract 和当前客户端现场
   ↓
OpenSpec Change
proposal → design → specs → tasks
   ↓
任务前检查
工作区、Change、前序 Task、Scope、依赖、验证等级
   ↓
Codex 执行一个最小纵向切片
Flutter 代码 + 必要的原生平台适配
   ↓
验证
format / analyze / test / 数据库 / 模拟器或设备 / 生命周期
   ↓
Task Report + 状态判断
DONE / PARTIAL / BLOCKED / FAILED
   ↓
按授权建立 Git checkpoint
   ↓
Change 收尾和完整验证
```

### 3.1 先读上下文，不直接动手

开始任务前先确认：

- 当前工作的唯一 OpenSpec Change；如果有多个活动 Change，不能按最近修改时间猜选；
- 根 `AGENTS.md`、`client/AGENTS.md`、命中目录的专项 `AGENTS.md`；
- 当前 Task 的原生 ID、Scope、Out of Scope、依赖、Acceptance Criteria 和 Validation Level；
- 涉及的产品文档、contract、架构决策和学习记录；
- `git status --short` 中哪些修改属于当前任务，哪些是已有现场；
- 是否需要 Flutter 构建、代码生成、Xcode、Gradle、模拟器、实体设备或平台日志。

如果发现 proposal、design、spec 或实现冲突，不通过扩大代码范围自行解决，而是先回到 OpenSpec 修正文档。这是移动端工程判断的一部分：AI 可以提出候选方案，但不能在需求冲突时替产品和架构做决定。

### 3.2 用 Change 把模糊需求变成执行合同

一个适合移动端的 Change 至少回答：

- Why：为什么现在做；
- What：要交付什么用户或系统能力；
- Non-goals：当前版本明确不做什么；
- Decisions：为什么选择当前状态管理、数据边界或平台实现；
- Observable Behavior：用户、系统或测试可以观察到什么；
- Validation：代码、数据和真实设备分别怎么证明；
- Risks：权限拒绝、离线、迁移失败、平台差异或外部服务失败如何处理；
- Rollback/Reset：如何恢复任务和工作区。

例如，“支持图片导入菜谱”不是一个足够小的 Task。它可以拆成：

1. 建立持久化导入任务和状态枚举；
2. 将图片复制到 App 自己管理的目录；
3. 建立 iOS Vision 与 Android ML Kit 的 OCR 平台适配；
4. 统一 OCR 文本、坐标和置信度模型；
5. 在 Domain 层恢复版面并生成待审核草稿；
6. 在页面显示任务进度、失败和恢复入口。

每一项都有自己的边界和验证，不把“能导入”作为一个无法定位失败位置的大任务。

### 3.3 Task 必须小到可以验证

我会使用类似下面的结构：

```markdown
- [ ] 1.3 建立图片导入的持久化任务状态
  - Validation Level: Behavior
  - Goal: App 重启后仍能恢复未完成的导入任务
  - Scope: ImportTaskEntity、Drift 表、Repository、状态迁移和恢复测试
  - Out of Scope: OCR、云端 AI、菜谱编辑器和跨设备同步
  - Acceptance Criteria:
    - [ ] 创建任务后图片路径和任务状态可持久化
    - [ ] 进程重启后可以查询到未完成任务
    - [ ] 失败、取消和重试不会产生重复任务
    - [ ] 无效路径和未知状态有明确诊断
  - Reset / Verification: 清理测试数据库，创建任务，模拟失败、重启和重试
```

这个格式有两个作用：一是让 Codex 能够逐项执行，二是让面试官或团队成员快速判断“完成”是不是被夸大了。

### 3.4 先做最小纵向切片

移动端最小纵向切片不是只写一层 UI，也不是只写一个 Repository，而是从用户入口、状态、数据、平台能力到验证方式形成一个小闭环。它应该有：

- 一个明确的用户或系统可观察结果；
- 最少但真实的 UI、Domain、Data 和平台代码；
- 独立的验证入口；
- 可重复的 Reset 和恢复步骤；
- 不依赖尚未实现的登录、同步或云端服务。

例如，先验证“图片导入任务可以持久化并恢复到待审核状态”，再扩展自动分类、云端 AI 和跨设备同步。这样即使 OCR 或网络服务失败，已有数据也不会被伪装成成功。

## 4. 移动客户端的架构边界

### 4.1 Kitchen 的组件边界

项目使用 Flutter Pub Workspace 管理多个 package，根 App 负责组合和装配，业务 Feature 不直接依赖 Data 或其他 Feature：

```text
kitchen_notes 根 App
├── 路由、主题、依赖装配和跨 Feature 协调
├── kitchen_home / kitchen_import / kitchen_profile
│   └── Feature UI、Provider 和用户流程
├── kitchen_recipe_library / kitchen_recipe_editor
│   └── 菜谱展示与编辑
├── kitchen_recipe_domain
│   └── Entity、Value Object、UseCase、Repository 接口
├── kitchen_recipe_data
│   └── Drift、Mapper、Repository 实现和本地存储
├── kitchen_import_domain
│   └── 导入状态机、OCR 模型、版面分析和处理端口
├── kitchen_import_data
│   └── 媒体存储、网页提取、OCR 平台适配和导入数据库
└── kitchen_design_system / kitchen_app_core
    └── 视觉基础、导航契约和通用能力
```

依赖方向是：

```text
根 App → Feature → Domain
根 App → Data → Domain
Feature → App Core + Design System
Platform Adapter → Domain/Data 定义的端口
```

核心约束：

- Feature 之间禁止直接依赖；
- Presentation 不直接使用 Drift 生成类型或访问数据库；
- Data 不依赖 UI、Design System 或 Feature；
- 全局 GoRouter 只在根壳工程注册；
- Feature 使用类型化导航扩展，不在业务代码中硬编码全局路径；
- Riverpod 负责依赖注入和状态订阅，根 App 通过 override 装配真实实现；
- 生成文件只由生成源产生，不手工修改 `*.g.dart`。

这类边界的面试价值在于：我不是只描述“用了 Flutter”，而是能说明模块为什么这样拆、依赖为什么这样流动、以后如何替换存储或平台实现。

### 4.2 Riverpod、GoRouter 和 Drift 的职责

| 技术 | 在项目中的职责 | 不负责什么 |
| --- | --- | --- |
| Riverpod | 依赖注入、Repository/UseCase 装配、异步状态和 Stream 订阅 | 不替代业务状态机和持久化模型 |
| GoRouter | 根 App 的声明式路由、Shell、路径参数和导航契约 | 不让 Feature 自由拼接全局路径 |
| Drift/SQLite | 本地任务、菜谱和恢复数据的持久化与查询 | 不把数据库生成类型泄漏到 UI |
| Domain Entity/UseCase | 表达业务语义、状态迁移和平台无关规则 | 不直接调用 Flutter、Drift 或平台 SDK |
| Platform Adapter | 把 Vision、ML Kit、系统分享等平台能力转换为稳定端口 | 不在原生层理解完整菜谱业务 |

这种分工让测试可以替换数据库或平台实现，也让 iOS 和 Android 的差异收敛在适配层，而不是扩散到 Feature。

### 4.3 平台桥接的边界

以 OCR 为例，Flutter 侧只调用稳定的端口：

```text
ImportPipeline
  ↓
PlatformOcrAdapter
  ↓ MethodChannel
  ├── iOS Vision
  └── Android ML Kit
  ↓
OcrPageEntity / OcrLineEntity
  ↓
OcrLayoutAnalyzerService
  ↓
RecipeDraftEntity
```

iOS 和 Android 可以使用不同的识别库，但返回给 Domain 的结构必须统一，包括：

- 文字内容；
- 归一化后的 `left/top/right/bottom`；
- 置信度；
- 页面和行的关联信息；
- 失败原因和可重试性。

iOS Vision 的坐标原点和 Android 的像素坐标定义不同，不能把平台返回值直接传到业务层。项目把坐标统一成 0 到 1 的相对坐标，并约定左上角为原点。这样不同分辨率和不同平台可以使用同一套版面分析逻辑。

移动端面试中，我会强调：原生层负责调用平台能力和做数据转换，Domain 层负责解释数据的业务含义。例如 Vision 和 ML Kit 只负责识别文字，不应该知道“哪一行是食材、哪一行是步骤”。

## 5. 厨房手记的实际移动端案例

### 5.1 图片到菜谱草稿的完整链路

```text
用户选择图片
  ↓
复制到 App 受控目录
  ↓
持久化 ImportTask
  ↓
ImportPipeline.process(taskId)
  ↓
PlatformOcrAdapter
  ├── iOS Vision
  └── Android ML Kit
  ↓
文字行 + 坐标 + 置信度
  ↓
OcrDocumentEntity
  ↓
OcrLayoutAnalyzerService
  ↓
LocalRecipeStructurerService
  ↓
RecipeDraftEntity(awaitingReview)
  ↓
用户逐字段审核并保存
```

这个流程体现了几个移动端原则：

- 图片先复制到 App 受控目录，避免依赖相册或系统分享的临时路径；
- 导入任务先持久化，App 被杀死或进程重启后可以继续查询；
- OCR 失败时保留任务和失败原因，而不是把错误吞掉；
- 自动解析只产生待审核草稿，不把识别结果直接当成用户确认的数据；
- 平台差异停留在 Adapter，版面和菜谱语义进入纯 Dart Domain；
- 用户离线时仍可完成核心导入、整理、保存和查阅。

### 5.2 一个适合面试讲的纵向切片

可以把“图片导入恢复”作为一个切片来讲：

**目标**：用户选择图片后，即使 App 退后台、进程被系统终止或 OCR 失败，重新打开 App 仍能看到导入任务和明确的恢复入口。

**Scope**：

- 导入任务实体、状态和错误信息；
- 图片复制到 App 受控目录；
- Drift 表、Repository 和 Stream 查询；
- ImportPipeline 的状态迁移；
- 导入箱展示处理中、失败、可重试和待审核状态；
- 相关单元测试和重启恢复验证。

**Out of Scope**：

- 云端 AI 解析；
- 登录、同步和备份；
- 完整菜谱编辑器；
- OCR 识别准确率优化；
- iOS Share Extension 作为 V1 发布前置能力。

**Acceptance Criteria**：

1. 创建导入任务后，任务身份、图片路径和状态可持久化；
2. 任务失败时保留失败原因，用户可以重试或删除；
3. App 重启后未完成任务仍能显示；
4. 重试不会创建重复任务；
5. 进入待审核状态后，用户能打开草稿并逐字段确认；
6. iOS 和 Android 适配返回的 OCR 结构可以被同一 Domain 流程消费。

**验证**：

- 结构：format、analyze、相关 package 测试和数据库生成检查；
- 行为：真实图片导入、失败、重试、取消、退后台、重新打开；
- 数据：清理测试数据库后重复执行，确认任务 ID、状态和路径不产生错误重复；
- 平台：Android 模拟器/设备验证 V1 主流程，iOS 对应桥接和模拟器流程按当前 Change 范围记录；
- 证据：将真实命令、环境前提、观察结果和未运行项写入 Task Report。

### 5.3 跨平台坐标统一是一个好例子

iOS Vision 的 `boundingBox` 是 0 到 1 的相对坐标，原点在左下角；Android ML Kit 通常返回以左上角为原点的像素矩形。若不做统一，后续版面分析会在某个平台上出现上下颠倒或不同分辨率下偏移。

项目在平台边界转换为统一模型：

```text
left   = 相对于图片宽度的 0 到 1
top    = 相对于图片高度的 0 到 1
right  = 相对于图片宽度的 0 到 1
bottom = 相对于图片高度的 0 到 1
```

之后 Domain 只处理统一坐标，不关心数据来自 Vision 还是 ML Kit。这是一个很适合面试说明的例子：跨平台不是把两套代码复制一遍，而是先定义稳定的共享语义，再把差异限制在边界内。

### 5.4 当前实现中明确保留的事实边界

面试时不能把计划或接口名称说成已完成能力。例如当前学习记录中有这些需要诚实表达的边界：

- Dart 侧会传递 `rotationQuarterTurns`，但当前 iOS Vision 和 Android ML Kit 实现并未使用它；不能仅凭参数存在就声称原生 OCR 已处理旋转；
- OCR 行 ID 当前是本页结果中的序号，不应描述为跨重试、跨设备永久稳定 ID；
- Android 是当前 V1 的优先验证平台，iOS Share Extension 和账号/云端能力不是 V1 发布前置条件；
- 自动生成草稿仍需要用户审核，不能把 OCR 或本地结构化结果描述为百分之百准确；
- 未运行的实体设备、数据库集成或发布签名检查必须写成 `NOT RUN`，不能为了完整叙述而补写成 PASS。

我认为这种边界意识比把项目包装成“所有平台都已经完成”更能体现工程可靠性。

## 6. 验证和 Definition of Done

### 6.1 按风险选择验证等级

| 等级 | 适用场景 | 移动端最低证据 |
| --- | --- | --- |
| Structural | 类型、接口、目录、依赖、路由、文档和配置 | format、analyze、相关测试、结构/链接检查 |
| Behavior | 页面交互、导航、导入、状态恢复、平台桥接 | 自动化测试 + 模拟器或实体设备上的真实流程 |
| Critical | 数据库迁移、认证、同步、备份恢复、删除策略、安全边界 | 自动化测试 + 数据库集成 + 跨端/设备边界 + 失败恢复 |

移动端 Behavior 验证至少要考虑：

- 首次安装和已有数据升级；
- 冷启动、热启动、退后台和回前台；
- 进程被系统终止后重新进入；
- 无网络、弱网、超时、取消、重试和重复点击；
- 权限允许、拒绝和之后重新授权；
- 不同屏幕尺寸、文字缩放、深色模式和系统返回；
- iOS/Android 平台实现差异；
- 真实设备上的图片、文件、相机、通知或分享能力。

在 Kitchen 中，命令会根据 Task 范围选择，而不是每次机械执行全部命令：

```sh
dart format --output=none --set-exit-if-changed .
./tool/kitchen_flutter.sh analyze
./tool/kitchen_flutter.sh test packages/*/test
./tool/check_navigation_boundaries.sh
```

如果涉及 Drift 生成源，需要重新生成并检查生成差异；如果涉及数据库迁移、认证、同步或共享 contract，则提升到 Critical 范围，不能只做页面 Widget 测试。

### 6.2 什么时候才能标记 DONE

一个移动端 Task 只有同时满足以下条件才能标记 `DONE`：

- Scope 已完成，Out of Scope 没有被偷偷扩大；
- Acceptance Criteria 全部满足；
- 适用的格式、静态、自动化、平台或数据验证真实执行并记录结果；
- 用户可见行为、失败策略、恢复方式和 Reset 方法清楚；
- 没有未声明的重大偏差；
- Task Report 已记录实际文件、命令、环境前提和结果；
- 修改都能归属于当前 Task，未把已有工作区改动伪装成当前成果。

如果只完成一部分，标记 `PARTIAL`；受到模拟器、证书、设备、网络、数据库或外部服务阻塞，标记 `BLOCKED`；验证真实失败则保留 `FAILED`。状态不是为了让任务看起来漂亮，而是为了让下一次协作能正确判断风险。

### 6.3 Report 应该记录什么

Task Report 至少记录：

- Change 和 Task 身份；
- Status 和 Validation Level；
- 实际修改文件；
- 用户可见行为和系统责任；
- Acceptance Criteria 逐项结果；
- 真实命令、设备/模拟器、数据库和环境前提；
- 失败、重试、恢复、取消和幂等结果；
- 偏差、遗留问题和下一任务需要的上下文；
- 哪些验证是 `NOT RUN`，以及解除条件。

这样下一个开发者接手时，不需要重新猜测“AI 到底改了什么、哪些只是口头说过”。

## 7. 工具职责和开发者责任

### 7.1 工具职责分离

| 工具 | 在流程中的职责 |
| --- | --- |
| Codex | 阅读上下文、搜索调用链、提出方案、实现切片、运行命令、检查差异和整理证据 |
| OpenSpec | 提供 Change、Spec、Task 和 Report 的结构化上下文 |
| Harness | 约束开始条件、Task 生命周期、验证证据、状态和停止时机 |
| Flutter/Dart | format、analyze、Widget/单元测试和跨 package 验证 |
| Xcode/Simulator | iOS 编译、原生桥接、权限、生命周期和运行时观察 |
| Gradle/Android 工具 | Android 构建、Manifest/平台桥接和模拟器/设备验证 |
| Drift/SQLite 工具 | 代码生成、迁移、查询、事务和恢复验证 |
| Git | 现场归属、范围检查、checkpoint 和回溯 |

我不会让 AI 直接把平台差异扩散到所有 Feature，也不会让“测试命令执行成功”替代真实设备行为。平台写操作前先确认目标文件和入口，修改后通过构建、日志、模拟器或设备重新读取结果。

### 7.2 我负责什么，AI 负责什么

这是面试中容易被追问的一点。我的回答是：

我负责问题定义、优先级、架构边界、跨平台取舍、验收标准、工具权限和最终判断；AI 负责在明确上下文内进行代码搜索、调用链分析、方案草拟、重复性实现、测试执行、日志分析和差异检查。

| 责任 | 开发者 | Codex |
| --- | --- | --- |
| 确定产品目标和版本范围 | 负责 | 协助澄清、指出冲突 |
| 选择 Feature/Domain/Data/平台边界 | 负责 | 提供候选方案和风险 |
| 编写 OpenSpec | 负责最终内容 | 协助整理和一致性检查 |
| 实现 Flutter、Dart 和平台代码 | 审核范围和结果 | 执行主要修改 |
| 处理 iOS/Android 差异 | 负责取舍和契约 | 搜索现状、实现适配、提示风险 |
| 编译、测试和设备验收 | 定义证据是否足够 | 执行命令、汇总结果 |
| DONE/PARTIAL/BLOCKED 判断 | 负责 | 提醒缺口，不替代判断 |
| 提交和发布 | 明确授权、确认范围 | 不自行提交或发布 |

所以我不会把“AI 生成了多少代码”作为效率指标，更关注：从 Change 到可验证结果的时间、返工次数、范围外修改数量、失败能否复现，以及下一位开发者能否快速接手。

## 8. 面试中可以直接使用的移动端 Prompt

我不会只说“帮我实现图片导入”，而会把上下文、权限和验收条件显式化：

```text
背景：厨房手记是 Flutter 本地优先客户端，当前 V1 以 Android 为优先验证平台。
架构：Feature 不直接依赖 Data；Domain 保持纯 Dart；根 App 负责依赖装配和全局路由。
当前 Change：client-import-recovery。
当前 Task：1.3，建立图片导入的持久化任务状态。

目标：App 退后台或进程重启后，用户仍能看到导入任务并进行恢复。
范围：ImportTask Entity、Drift 表、Repository、状态迁移、错误信息和相关测试。
不做：OCR、云端 AI、登录、同步、完整菜谱编辑器和 iOS Share Extension。

验收：
1. 任务 ID、受控图片路径和状态可以持久化；
2. 失败、取消、重试状态可观察且有明确错误；
3. 重启后未完成任务仍能显示；
4. 重试不会产生重复任务；
5. Feature 不直接访问 Drift，路由不新增硬编码全局路径。

验证：先检查 git status 和当前 Change，再读取相关 AGENTS.md、proposal、design、tasks
和数据文档。实现后运行适用的 format、analyze、package test 和数据库检查；必要时在
Android 模拟器或设备执行冷启动、退后台、杀进程、重启、失败和重试。不要修改无关文件，
不要手工编辑生成文件。结束时输出实际修改文件、用户可见行为、验证命令和结果、偏差、
未运行验证和遗留问题，供 Task Report 使用。
```

这个 Prompt 的重点不是写得尽量长，而是让 AI 知道：它当前属于哪个 Change、只做哪个 Task、哪些行为必须成立、哪些内容绝对不应该顺手实现。

## 9. 常见追问与回答

### Q1：为什么不直接让 AI 一次性开发完整功能？

因为移动端完整功能往往同时包含 UI、状态、数据库、平台 API、权限、生命周期和发布配置。一次性实现会让错误难以定位，也无法判断是产品错、设计错、平台差异还是恢复逻辑错。最小纵向切片可以尽早得到真实反馈，并把返工限制在一个可理解的边界内。

### Q2：OpenSpec 和普通需求文档有什么区别？

普通需求文档主要描述产品目标；OpenSpec 更强调当前变更的执行闭环：为什么做、技术决策是什么、哪些行为可观察、每个任务怎么验收、完成后留下什么证据。它不是替代产品文档，而是把一个需求转换成开发者和 AI 都能执行的变更包。

### Q3：Harness 是不是增加了很多文档成本？

有成本，但它把成本从“反复解释上下文、排查错误修改和恢复失败现场”前移成稳定规则。通用生命周期由全局 skill 维护，项目只维护 Flutter、平台、数据库和验证命令等技术扩展；Task 和 Report 只记录当前变更，不会把每次聊天都变成一份长文档。

### Q4：怎样防止 AI 改错平台代码或路由？

先确认目标平台、入口文件和当前调用链，再限定 Scope；平台修改后执行对应构建和运行验证；路由修改后检查集中注册和导航边界；涉及权限、Share Extension、MethodChannel 或生命周期时，至少做一次真实模拟器/设备流程。不能只看 Dart 侧调用成功就断言原生能力完成。

### Q5：为什么“编译通过”还不够？

编译只能说明语法、类型和链接基本成立，不能证明页面状态正确、数据库迁移安全、进程重启可恢复、权限拒绝可降级、网络失败可重试，也不能证明 iOS 和 Android 返回了相同语义。因此我按任务类型选择结构、行为或关键验证。

### Q6：AI 写错了怎么办？

先判断错误属于需求、设计、实现还是环境。如果是需求或设计冲突，回到 OpenSpec 修正；如果是实现错误，在当前 Task 范围内修复并重新验证；如果是外部设备、证书、网络或数据库环境阻塞，记录为 BLOCKED；如果验证失败且当前结果不可交付，保留 FAILED。关键是保留失败事实，而不是让 AI 不断扩大范围“碰运气修好”。

### Q7：如何证明 AI 确实提高了效率？

不只看生成代码量，而看工程信号：任务是否更小、返工是否更少、验证是否更早、范围外修改是否减少、失败能否复现、Report 是否让下一次接手更快。团队化以后，还可以统计 Change 到 DONE 的时间、每个 Task 的返工次数、验证失败原因和人工修改比例。

### Q8：这套流程是否只适用于 Flutter？

不只适用于 Flutter。iOS 原生、Android 原生、React Native、Kotlin Multiplatform 或后端都可以使用同一套 OpenSpec + Harness 思路。变化的是项目扩展：iOS 增加 Xcode、Swift Concurrency、签名和系统生命周期；Android 增加 Gradle、Manifest、进程和设备矩阵；核心仍然是范围、依赖、验收、失败恢复和真实证据。

### Q9：AI 会不会让开发者的价值降低？

AI 降低的是搜索、样板代码、重复实现和初步排查的成本，但不会替代问题抽象、架构判断、平台取舍、风险控制和最终责任。移动端越接近数据、权限、生命周期和发布边界，越需要开发者判断“什么才算真的完成”。

## 10. 面试表达时的边界和措辞

建议使用这些表达：

- “我把 AI 纳入工程流程，而不是把工程决策交给 AI。”
- “OpenSpec 是变更合同，Harness 是执行护栏，Report 是事实证据。”
- “移动端的完成标准包含状态、恢复、平台差异和真实设备行为，不只是编译通过。”
- “我先定义稳定的 Domain 语义，再把 iOS/Android 差异限制在平台适配层。”
- “自动解析结果进入待审核状态，不能把 AI 或 OCR 结果直接当成用户确认数据。”
- “没有实现的能力会明确写成 Out of Scope，未运行的验证会写成 NOT RUN。”

避免这些容易引起误解的表达：

- “AI 自动完成了整个客户端”；
- “只要能编译就说明完成”；
- “平台桥接天然会在两端表现一致”；
- “所有测试和设备验收都自动化了”；
- “AI 自己决定了架构”；
- “规划中的 iOS、同步或云端能力已经交付”。

## 11. 最后的总结

这次实践让我形成了一个比较稳定的移动端 AI 辅助开发观：

> AI 的能力决定执行上限，工程流程决定结果下限。

当需求、设计、任务、架构边界、平台适配、验证和 Git 证据连成闭环后，Codex 不再只是生成代码的工具，而是可以参与代码理解、实现、测试、日志分析、运行时检查和文档沉淀的工程协作者。

开发者的价值没有消失，而是更集中在问题抽象、架构判断、跨平台取舍、风险控制和结果验收上。对移动客户端来说，真正值得面试表达的不是“我让 AI 写了多少代码”，而是“我如何让 AI 的修改可以被限定、被验证、被回溯，并最终对用户行为负责”。

## 参考资料

项目内：

- [项目通用约束](../AGENTS.md)
- [客户端约束](../client/AGENTS.md)
- [客户端 README](../client/README.md)
- [Kitchen Harness 扩展](Harness/README.md)
- [客户端工作流](client/workflow/CODEX_WORKFLOW.md)
- [OCR 导入流程学习记录](learning/client-import-ocr-to-recipe-draft.md)
- [Riverpod、GoRouter、Drift 学习记录](learning/client-riverpod-gorouter-drift-sqlite.md)
- [OpenSpec](../openspec/)

官方资料：

- [OpenAI Developers](https://developers.openai.com/)
- [Codex CLI](https://developers.openai.com/codex/cli)
- [Codex IDE extension](https://developers.openai.com/codex/ide)
