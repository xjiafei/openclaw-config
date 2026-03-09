# AIFD 落地方案

> **版本：** v1.0  
> **日期：** 2026-03-05  
> **原则：** 务实、最小可行、快速验证

---

## 1. 问题整合（从 4 份文档提炼的核心问题清单）

从主方案 v0.2、Review 报告、跨会话分析、可扩展性评估中提取，去重合并后的核心问题：

| # | 问题 | 来源 | 对 V1 的影响 |
|---|------|------|-------------|
| P1 | **OpenClaw → Claude Code 调用链未验证**：exec CLI 方式能否可靠工作、输出如何回收，全是假设 | 主方案 §4.2 | 🔴 阻塞性——V1 第一件事必须验证 |
| P2 | **Hook 机制未验证**：stdin JSON 格式、exit code 语义都是文档推测 | Review MF-4 | 🟡 V1 可绕过——不依赖 Hook 也能跑通 |
| P3 | **Agent Teams 行为未验证**：Team Lead 是否真的按 CLAUDE.md 描述创建 teammates | Review MF-2 | 🟡 V1 可绕过——先不用 Agent Teams，单 agent 即可 |
| P4 | **方案过度设计**：800-1500 行代码才能实现完整框架引擎 | 可扩展性评估 §3 | 🔴 V1 必须砍到几乎零代码 |
| P5 | **Pipeline 状态机需要写代码实现** | 可扩展性评估、跨会话 G3 | 🟡 V1 用手动 JSON + OpenClaw 对话驱动 |
| P6 | **上下文构建器需要写代码实现** | 可扩展性评估 | 🟡 V1 用手写 CLAUDE.md 模板 |
| P7 | **质量把关流程过重**（多模型 Review） | Review SF-3 | 🟢 V1 用 OpenClaw 自身做单次 Review |
| P8 | **配置驱动不足**，新项目接入需改代码 | 可扩展性评估 §要求4 | 🟢 V2 解决 |
| P9 | **框架 vs 系统**：当前是软件研发系统设计，不是通用框架 | 可扩展性评估总评 | 🟢 V2 解决 |
| P10 | **跨 session 状态管理机制复杂** | 跨会话分析 G1-G8 | 🟡 V1 极简版——一个 JSON 文件足够 |

**V1 的核心判断**：4 份文档设计的是一个完整的自动化框架（Phase 1-5，几个月工期），但 Gary 需要的是**1-2 周内验证核心假设**。V1 要做的不是实现框架，而是**手动走通一遍流程，确认技术假设成立**。

---

## 2. V1 MVP 设计（最小可行框架）

### 2.1 验证目标

V1 要回答 3 个核心问题：

| # | 假设 | 验证方式 | 成功标准 |
|---|------|---------|---------|
| H1 | OpenClaw 能通过 exec 可靠调用 Claude Code CLI 并获取输出 | 实际执行一次 | 命令执行成功，输出可解析 |
| H2 | 通过 CLAUDE.md + docs/ 传递上下文，Claude Code 能产出符合预期的代码 | 用 CLAUDE.md 驱动生成一个 CRUD API | 生成的代码能跑起来 |
| H3 | OpenClaw 能基于 Claude Code 产物做质量评估并决定是否重做 | 对生成的代码做一次 Review，发现问题后重做 | ReAct 闭环能跑通 |

**不验证的**：Agent Teams 多 agent 协作、多阶段 Pipeline 自动流转、Hook 机制、多模型 Review、记忆同步。这些全部推到 V2。

### 2.2 验证系统（小项目选型）

**选型：Todo API**（待办事项管理 REST API）

| 维度 | 选择 | 理由 |
|------|------|------|
| 类型 | 后端 CRUD API（不含前端） | 最小化验证范围 |
| 技术栈 | Python + FastAPI + SQLite | Claude Code 最擅长，生成质量高 |
| 功能 | 4 个端点：GET/POST/PUT/DELETE /todos | 标准 CRUD，足够验证代码生成 |
| 复杂度 | 单 model、单 router、无认证 | 一次 session 能完成 |

不选前后端分离——前端引入 Node.js 生态、组件库选型等复杂度，与验证目标无关。

### 2.3 最小框架组成

**V1 不写框架代码。** 全部用 OpenClaw 现有能力 + 手动文件操作。

| 组件 | V1 实现方式 | 代码量 |
|------|-----------|--------|
| 上下文构建 | 手写 CLAUDE.md 文件 | 0（纯文档） |
| Claude Code 调用 | OpenClaw `exec` 工具直接执行 CLI | 0（用现有工具） |
| 结果回收 | 读取文件系统产物 | 0（用现有工具） |
| 质量评估 | OpenClaw 自身（作为 AI）阅读产物并评估 | 0 |
| 状态管理 | 手动维护 `workspace/state.json` | 0（手动编辑） |
| ReAct 闭环 | OpenClaw 自身决策：评估不通过 → 更新 CLAUDE.md → 重新 exec | 0 |
| Git checkpoint | 手动 exec `git commit` | 0 |

**总代码量：0 行。** V1 完全是「人工编排 + AI 执行」模式，OpenClaw（Claw）就是编排器。

### 2.4 最小项目结构

```
projects/ai-driven-dev-framework/
├── AIFD_TECHNICAL_PROPOSAL.md     # 主方案（已有）
├── AIFD_LANDING_PLAN.md           # 本文件
├── REVIEW_REPORT.md               # Review 报告（已有）
├── CROSS_SESSION_ANALYSIS.md      # 跨会话分析（已有）
├── EXTENSIBILITY_REVIEW.md        # 可扩展性评估（已有）
└── v1-todo-app/                   # V1 验证项目
    ├── CLAUDE.md                  # 动态手写，每次 session 前更新
    ├── docs/
    │   └── tech-spec.md           # Todo API 技术规格（1 个文件够了）
    ├── workspace/
    │   └── state.json             # 极简状态（手动维护）
    └── src/                       # Claude Code 生成的代码
        ├── main.py
        ├── models.py
        ├── routes.py
        └── requirements.txt
```

**砍掉的目录**：`.openclaw/workspace-aifd/`、`docs/knowledges/`、`docs/specs/`（多文件）、`testing/`、`devops/`、`frontend/`、`backend/`、`.claude/hooks/`、`.claude/commands/`、`workspace/sessions/`、`workspace/archive/`。

### 2.5 核心流程（简化版）

V1 的完整流程，全部由 Claw（OpenClaw AI）手动驱动：

```
Gary: "用 AIFD 框架生成一个 Todo API"
        │
        ▼
Step 1: Claw 手写 tech-spec.md（Todo API 规格）
        │
        ▼
Step 2: Claw 手写 CLAUDE.md（任务指令 + 规格引用）
        │
        ▼
Step 3: Claw exec `git add -A && git commit -m "pre-session"`
        │
        ▼
Step 4: Claw exec `claude --print -p "按照 CLAUDE.md 执行" --model claude-sonnet-4-20250514`
        │         cwd = v1-todo-app/
        │
        ▼
Step 5: Claw 读取生成的 src/ 文件，评估质量
        │
        ├── 质量 OK → Step 6
        └── 质量不行 → 更新 CLAUDE.md 含修正指令 → 回到 Step 4（最多 3 轮）
        │
        ▼
Step 6: Claw exec `cd v1-todo-app/src && pip install -r requirements.txt && python -c "from main import app; print('OK')"`
        │
        ├── 能跑 → 验证成功 ✅
        └── 报错 → 更新 CLAUDE.md 含错误信息 → 回到 Step 4
        │
        ▼
Step 7: Claw 更新 state.json，记录验证结果
Step 8: Claw exec `git add -A && git commit -m "session completed"`
```

### 2.6 逐日实施计划

#### Day 1：环境准备 + 调用链验证（H1）

**上午：**
1. 创建 `v1-todo-app/` 目录结构
2. 确认 `claude` CLI 已安装可用：`which claude && claude --version`
3. 确认环境变量配置（ANTHROPIC_API_KEY 或 Bedrock 配置）

**下午：**
4. 最小调用测试——不写 CLAUDE.md，直接测 exec：
   ```bash
   cd v1-todo-app && claude --print -p "创建一个 hello.py，内容是 print('hello world')" --model claude-sonnet-4-20250514
   ```
5. 确认：文件是否生成？输出格式是什么？退出码？耗时？
6. 记录发现到 `workspace/state.json`：
   ```json
   {
     "day": 1,
     "h1_verified": true/false,
     "cli_output_format": "...",
     "issues": ["..."],
     "next_step": "..."
   }
   ```

**Day 1 产出**：确认 OpenClaw exec → Claude Code CLI 调用链是否可行。如果不行，Day 2 排查替代方案（sessions_spawn、直接 API 调用等）。

#### Day 2：上下文传递验证（H2）

1. 手写 `docs/tech-spec.md`：

   ```markdown
   # Todo API 技术规格

   ## 概述
   一个简单的待办事项 REST API。

   ## 技术栈
   - Python 3.11+, FastAPI, SQLite (via sqlite3 标准库)
   - 不使用 ORM，直接 SQL

   ## 数据模型
   todos 表：id (INTEGER PK AUTOINCREMENT), title (TEXT NOT NULL), done (BOOLEAN DEFAULT FALSE), created_at (TIMESTAMP DEFAULT CURRENT_TIMESTAMP)

   ## API 端点
   - GET /todos → 列表，支持 ?done=true/false 过滤
   - POST /todos → 创建，body: {"title": "..."}
   - PUT /todos/{id} → 更新，body: {"title": "...", "done": true/false}
   - DELETE /todos/{id} → 删除

   ## 要求
   - 启动时自动建表
   - 统一错误返回格式 {"error": "..."}
   - 代码放在 src/ 目录：main.py (入口), models.py (数据库操作), routes.py (路由)
   ```

2. 手写 `CLAUDE.md`：

   ```markdown
   # CLAUDE.md

   ## 任务
   根据 docs/tech-spec.md 实现 Todo API。

   ## 输出要求
   - 所有代码放在 src/ 目录
   - 文件：main.py, models.py, routes.py, requirements.txt
   - 代码可直接运行：`cd src && pip install -r requirements.txt && uvicorn main:app`

   ## 约束
   - Python 3.11+, FastAPI, sqlite3 标准库
   - 不使用 ORM
   - 代码简洁，不过度工程化
   ```

3. 执行：`git commit` → `claude --print -p "读取 CLAUDE.md 和 docs/tech-spec.md，按要求实现" --model claude-sonnet-4-20250514`

4. 检查生成的 src/ 文件，记录：
   - Claude Code 是否读取了 CLAUDE.md？
   - 是否按 tech-spec 实现？
   - 代码质量如何？

**Day 2 产出**：确认 CLAUDE.md + docs/ 上下文传递是否有效。

#### Day 3：ReAct 闭环验证（H3）

1. 尝试运行 Day 2 生成的代码
2. 如果有 bug 或不符合预期：
   - Claw 阅读代码，写出具体问题
   - 更新 CLAUDE.md 增加「修正指令」段落：
     ```markdown
     ## 修正指令（基于上一轮 Review）
     以下问题需要修复：
     1. models.py 第 15 行：建表 SQL 缺少 created_at 字段
     2. routes.py：DELETE 端点缺少 404 处理
     3. requirements.txt 缺少 uvicorn
     ```
   - 重新 exec Claude Code
3. 验证修正后的代码是否解决了问题
4. 记录 ReAct 循环的实际效果：几轮收敛？修正指令的粒度需要多细？

**Day 3 产出**：确认 ReAct（评估→修正→重做）闭环是否有效。

#### Day 4-5：总结 + V2 规划

1. 整理 3 个假设的验证结果
2. 记录实际遇到的问题和解决方案
3. 更新 `AIFD_TECHNICAL_PROPOSAL.md`，用实际数据替换假设
4. 输出 V2 的详细计划（基于 V1 的发现）

### 2.7 V1 中的妥协（明确砍掉什么、为什么）

| 砍掉的功能 | 原方案位置 | 为什么砍 | V2 是否恢复 |
|-----------|-----------|---------|------------|
| Agent Teams 多 agent | §4.3, §11 | 单 agent 足以验证核心假设；多 agent 引入额外不确定性 | V2 验证 |
| Pipeline 状态机 | §4.5 | V1 只有一个阶段（编码），不需要状态机 | V2 实现 |
| Hook 脚本 | §8 | V1 用 post-session 文件检查代替实时 Hook | V2 验证 |
| 多模型 Review | §9.3 | V1 用 OpenClaw 自身做 Review，零成本 | V3 |
| 记忆同步 | §10 | V1 手动记录到 state.json | V2 实现 |
| 上下文构建器（代码） | §5 | V1 手写 CLAUDE.md | V2 模板化 |
| 任务拆分 | §6.5 | V1 任务足够小，不需拆分 | V2 实现 |
| Session 恢复 | §4.5 | V1 任务小，失败直接重做 | V2 实现 |
| 前端 | §11 P4 | 与验证目标无关 | V2 |
| 测试/部署 | §11 P5-P6 | 与验证目标无关 | V3 |
| 知识库 | §3 docs/knowledges/ | V1 不需要 | V2 |
| 多 feature 并行 | Review SF-5 | V1 只有一个 feature | V3 |
| 配置化（aifd.yaml） | 可扩展性评估 | V1 不需要框架，手动操作 | V2 |

---

## 3. V2 改进路线图（Review 意见的排期）

### V2（第 3-4 周）：单阶段自动化

基于 V1 验证结果，选择性实现：

| 优先级 | 改进项 | 来源 | 具体内容 |
|--------|-------|------|---------|
| P0 | CLAUDE.md 模板化 | 可扩展性 | 用 shell 模板生成 CLAUDE.md，减少手写 |
| P0 | Session state 自动记录 | 跨会话 G1 | 自动写入 session 结果到 state.json |
| P1 | Agent Teams 验证 | Review MF-2 | 测试 Team Lead 创建 teammates 的实际行为 |
| P1 | Hook 机制验证 | Review MF-4 | 最简 Hook 脚本测试参数传递 |
| P1 | Git checkpoint 自动化 | Review SF-1 | pre/post session 自动 commit |
| P2 | 单模型 Review 自动化 | Review SF-3 | spawn subagent 做质量评估 |
| P2 | 最小 Pipeline（2 阶段） | 跨会话 G3 | 设计→编码 两阶段自动流转 |

### V3（第 5-8 周）：多阶段 Pipeline

| 改进项 | 来源 |
|--------|------|
| Pipeline 状态机引擎 | 跨会话 G3 |
| 大任务拆分 | Review MF-3 |
| 多模型 Review | Review SF-3 |
| 记忆同步自动化 | 主方案 §10 |
| 前后端分离项目验证 | 主方案 §11 |
| 配置驱动（aifd.yaml） | 可扩展性评估 |

### V4（第 9+ 周）：框架化

| 改进项 | 来源 |
|--------|------|
| 通用状态机引擎（不绑定 P1-P6） | 可扩展性评估 §要求1 |
| OpenClaw skill 打包（context-builder, quality-gate） | 可扩展性评估 §要求3 |
| 场景模板（软件研发 / 内容创作等） | 可扩展性评估 §架构建议 |
| 新项目零代码接入 | 可扩展性评估 §要求4 |
| 可观测性 | Review NH-2 |
| 成本追踪 | Review NH-1 |

---

## 4. 风险与应对

| # | 风险 | 概率 | 影响 | 应对 |
|---|------|------|------|------|
| R1 | **Claude Code CLI 在 OpenClaw exec 中无法正常工作**（权限、环境变量、交互式提示等） | 中 | 🔴 阻塞 V1 | Day 1 最先验证。备选：直接用 Anthropic API + 文件系统操作脚本 |
| R2 | **`--print` 模式不写文件**，只输出到 stdout | 中 | 🔴 阻塞 V1 | 测试 `--print` 是否仍然执行文件写入。如果不行，去掉 `--print` 用 `--dangerously-skip-permissions` 非交互执行 |
| R3 | **Claude Code 不读 CLAUDE.md**（需要在项目根目录？需要特定文件名？） | 低 | 🟡 需调整 | 测试 CLAUDE.md 的读取行为。备选：把内容直接放在 `-p` 参数中 |
| R4 | **生成的代码质量太低，多轮修正仍不行** | 低 | 🟡 影响验证结论 | 降低期望——V1 目标是验证「流程」而非「质量」。代码质量是模型能力问题，不是框架问题 |
| R5 | **API 成本超预期** | 低 | 🟢 可控 | V1 总共预计 5-10 次 Claude Code 调用，成本可控。用 Sonnet 而非 Opus |
| R6 | **Claude CLI 未安装或版本不兼容** | 中 | 🔴 阻塞 | Day 1 先检查。安装：`npm install -g @anthropic-ai/claude-code` |

### Day 1 阻塞时的降级方案

如果 `claude` CLI 在当前环境完全跑不通：

**降级方案 A**：不用 CLI，用 OpenClaw 的 subagent spawn 模拟。OpenClaw 自己就是 AI，可以 spawn 一个 subagent 扮演 Claude Code 的角色，读取 CLAUDE.md 生成代码。流程完全一样，只是执行层从 Claude Code CLI 换成 OpenClaw subagent。这能验证 H2（上下文传递）和 H3（ReAct 闭环），但无法验证 H1（调用链）。

**降级方案 B**：直接用 Anthropic Messages API。写一个 50 行的 shell 脚本调 API，传入 CLAUDE.md 内容，输出写入文件。本质上是手动实现 `claude --print` 的功能。

---

*方案到此为止。核心思路：V1 不写代码、不建框架，纯手动走通流程验证假设。用 5 天时间回答 3 个问题。有了答案再决定 V2 怎么做。*
