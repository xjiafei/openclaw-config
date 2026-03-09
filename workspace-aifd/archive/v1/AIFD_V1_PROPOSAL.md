# AIFD V1 技术方案：AI 全流程研发框架

> **版本：** V1.1  
> **日期：** 2026-03-05  
> **作者：** Gary（架构）+ Claw（设计）  
> **原则：** 尽可能少写代码、配置驱动、3 周落地

---

## 1. 目标与范围

### V1 做什么

1. **研发全流程驱动**：需求→产品设计→技术设计→开发→测试，每个阶段由 AI 执行，人类在关键节点审批
2. **记忆管理**：跨 session 持久化项目经验、决策记录、教训
3. **上下文构建**：每次调用 Claude Code 前自动生成 CLAUDE.md，注入项目状态和任务指令
4. **质量把关**：单模型 Review，评估产物质量，不通过则修正重做
5. **ReAct-Loop**：执行→评估→修正，最多 3 轮自动收敛
6. **用 Todo 系统作为验证项目**，前后端分离（Spring Boot + React + MySQL），端到端走通全流程

### V1 不做什么

- ❌ 多模型交叉 Review（V2）
- ❌ 通用框架抽象、配置化引擎（V2）
- ❌ 向量化知识库检索（V2）
- ❌ 多 feature 并行（V2）
- ❌ 可观测性 dashboard、成本追踪（V2）

### 成功标准

用 AIFD 框架驱动 Claude Code，从一句话需求到可运行的 Todo 系统（前后端分离），全流程自动化完成，人类只在关键节点审批。

---

## 2. 整体架构

```
┌─────────────────────────────────────────────────────────┐
│                    用户（Gary）                          │
│                  飞书对话 / 审批                         │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              OpenClaw 层（编排 + 记忆 + 质量）            │
│              /root/.openclaw/workspace-aifd/             │
│                                                         │
│  ┌──────────┐ ┌──────────┐ ┌────────┐ ┌──────────────┐ │
│  │ AIFD     │ │ 记忆管理 │ │ 质量   │ │ ReAct-Loop   │ │
│  │ Agent    │ │ (Skills) │ │ 把关   │ │ 控制         │ │
│  │ (SOUL)   │ │          │ │(Skill) │ │              │ │
│  └────┬─────┘ └──────────┘ └────────┘ └──────────────┘ │
│       │                                                 │
│       │  exec `claude` CLI                              │
│       ▼                                                 │
│  ┌──────────────────────────────────────────────────┐   │
│  │ 上下文构建 Skill → 生成 CLAUDE.md + docs/         │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              Claude Code 层（执行）                       │
│              /root/todo-system/                          │
│                                                         │
│  读取 CLAUDE.md → 按指令执行 → 产物写入文件系统           │
│                                                         │
│  .claude/agents/   → 预定义 agent（PM、Arch、Dev、QA）   │
│  .claude/commands/  → 快捷命令                           │
│  CLAUDE.md          → 动态生成的任务指令                  │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│              项目层（产物 + 状态）                        │
│                                                         │
│  docs/specs/    → 需求、设计文档                         │
│  backend/       → Spring Boot 后端代码                   │
│  frontend/      → React 前端代码                         │
│  workspace/     → 流水线状态、session 记录               │
└─────────────────────────────────────────────────────────┘
```

**核心设计决策**：

- OpenClaw 层用 **Skills（提示词 + 配置 + 少量脚本）** 实现，不写应用代码
- Claude Code 层用 **agents + commands + CLAUDE.md** 驱动，不写框架代码
- 状态通过**文件系统** JSON 持久化，不引入额外数据库
- 两层之间通过 `exec claude CLI` + 文件系统交互
- AIFD 框架放 `/root/.openclaw/workspace-aifd/`，业务项目放 `/root/todo-system/`

---

## 3. 项目结构

### 3.1 AIFD 框架层

```
/root/.openclaw/workspace-aifd/        # AIFD Agent 工作空间
├── SOUL.md                            # AIFD agent 人格定义
├── USER.md                            # 用户信息
├── MEMORY.md                          # 长期记忆
├── AGENTS.md                          # 工作空间说明
├── TOOLS.md                           # 工具配置
├── skills/
│   ├── context-builder/
│   │   └── SKILL.md                   # 上下文构建 skill
│   ├── quality-gate/
│   │   └── SKILL.md                   # 质量把关 skill
│   ├── pipeline/
│   │   └── SKILL.md                   # 流程编排 skill
│   └── memory-sync/
│       └── SKILL.md                   # 记忆同步 skill
└── memory/
    └── YYYY-MM-DD.md                  # 当日日志
```

### 3.2 业务项目层

```
/root/todo-system/                     # 验证项目根目录
├── .claude/                           # Claude Code 配置
│   ├── agents/                        # 预定义 agent
│   │   ├── pm-agent.md                # 需求分析 agent
│   │   ├── architect-agent.md         # 技术设计 agent
│   │   ├── developer-agent.md         # 编码 agent
│   │   └── qa-agent.md                # 测试 agent
│   ├── commands/                      # 快捷命令
│   │   ├── stage-complete.sh          # 阶段完成命令
│   │   └── quality-check.sh           # 质量检查命令
│   └── skills/
├── CLAUDE.md                          # 动态生成，每次 session 前更新
├── docs/
│   ├── specs/                         # 规格文档（AI 生成 + 人工审批）
│   │   ├── requirements.md            # 需求规格
│   │   ├── product.md                 # 产品设计
│   │   ├── tech.md                    # 技术设计
│   │   ├── testing.md                 # 测试方案
│   │   └── deploy.md                  # 部署方案
│   └── knowledges/                    # 知识库
│       ├── standards/                 # 编码规范
│       │   ├── java-coding.md         # Java 编码规范
│       │   └── react-coding.md        # React 编码规范
│       ├── templates/                 # 设计模板
│       │   ├── api-design.md          # API 设计模板
│       │   └── db-design.md           # 数据库设计模板
│       └── domain/                    # 领域知识
│           └── todo-domain.md         # Todo 领域知识
├── workspace/                         # 流水线状态
│   ├── pipeline.json                  # 流水线状态机
│   └── sessions/                      # session 记录
├── backend/                           # Spring Boot 后端（待生成）
├── frontend/                          # React 前端（待生成）
└── README.md                          # 项目说明
```

---

## 4. OpenClaw 层设计

### 4.1 AIFD Agent 配置

AIFD Agent 是一个 OpenClaw workspace agent，配置在 `/root/.openclaw/workspace-aifd/`。

**SOUL.md**：

```markdown
# SOUL.md — AIFD 研发指挥官

你是 AIFD（AI Full-process Development）研发指挥官。你的职责是编排 AI 全流程研发。

## 核心职责
1. 接收用户需求，驱动研发流程（需求→产品设计→技术设计→开发→测试）
2. 每个阶段：构建上下文 → 调用 Claude Code → 评估产物 → 决定下一步
3. 在关键节点请求人工审批
4. 维护项目记忆（经验、决策、教训）

## 工作方式
- 读取 workspace/pipeline.json 了解当前进度
- 调用 skills 完成上下文构建、质量评估等
- 通过 exec `claude` CLI 调用 Claude Code 执行具体任务
- 评估产物后决定：通过→下一阶段 / 不通过→修正重做 / 卡住→请求人工

## 风格
- 务实、直接
- 主动推进，不等人催
- 遇到问题先尝试解决，解决不了再上报
- 每个动作都更新 pipeline 状态

## 约束
- 单次 ReAct 最多 3 轮，超过就上报人工
- 人工审批节点不能跳过
- 每次 Claude Code 调用前必须 git commit 存档
```

**USER.md**：

```markdown
# USER.md — 项目上下文

## 当前项目
- 项目名：Todo System
- 类型：前后端分离 Web 应用
- 技术栈：Spring Boot + React + MySQL
- 项目路径：/root/todo-system/
- 阶段：见 workspace/pipeline.json

## 项目负责人
- Gary — 审批需求、技术方案、部署
```

### 4.2 Skills 设计

V1 需要 4 个 OpenClaw skills，全部用**提示词 + 少量 shell 脚本**实现，不写应用代码。

#### Skill 1: `context-builder` — 上下文构建

**职责**：读取项目状态和文档，生成 CLAUDE.md

#### Skill 2: `quality-gate` — 质量把关

**职责**：评估 Claude Code 产物质量，输出结构化评审结果

#### Skill 3: `pipeline` — 流水线管理

**职责**：管理 workspace/pipeline.json 的状态流转

#### Skill 4: `memory-sync` — 记忆管理

**职责**：在每个 session 后提取关键信息写入记忆

### 4.3 记忆管理

V1 的记忆分三层：

| 层级 | 文件 | 内容 | 更新频率 |
|------|------|------|---------|
| 当日日志 | `memory/YYYY-MM-DD.md` | 每次 session 的原始记录 | 每次 session 后 |
| 项目记忆 | `{project}/workspace/memory.md` | 项目级经验、决策、教训 | 每次 session 后（有价值时） |
| Agent 长期记忆 | `workspace-aifd/MEMORY.md` | 跨项目的框架使用经验 | 每天或重大发现时 |

### 4.4 质量把关

V1 的质量把关完全由 OpenClaw agent 自身完成。

**评估维度**：
- 文档类：完整性、一致性、可执行性
- Java 代码类：编译检查（mvn compile）、单元测试（mvn test）、API 一致性
- React 代码类：构建检查（npm run build）、测试（npm test）、组件完整性
- 测试类：覆盖率、边界场景、可运行性

### 4.5 ReAct-Loop

- 最大轮次：3
- 失败超过 3 轮：通知 Gary 人工介入

---

## 5. Claude Code 层设计

### 5.1 CLAUDE.md 结构（模板，动态生成）

```markdown
# CLAUDE.md — AIFD 任务指令

## 项目概述
- 项目：{project_name}
- 类型：前后端分离 Web 应用
- 技术栈：Spring Boot + React + MySQL

## 当前阶段：{current_stage}

### 任务目标
{task_description}

### 输入文档
请阅读以下文件了解上下文：
{input_files_list}

### 输出要求
请产出以下文件：
{output_files_list}

### 质量标准
{quality_criteria}

### 约束
{constraints}

## Session 连续性
### 上次 Session 状态
- 状态：{last_session_status}
- 已完成：{completed_artifacts}
- 未完成：{pending_work}

### 修正指令
{must_fix_list}

## 相关经验
{从记忆中提取的与当前任务相关的经验}

## 编码规范
请参考 docs/knowledges/standards/ 下的编码规范文档。

## Agent 角色说明
你是 {agent_role}，负责 {role_responsibility}。
请在 .claude/agents/{agent_id}.md 中查看详细角色定义。
```

### 5.2 Agents 定义

参见 `.claude/agents/` 下各 agent 文件。

### 5.3 Commands 定义

- `stage-complete.sh` — 报告阶段完成状态
- `quality-check.sh` — 触发质量检查

---

## 6. 研发全流程

### 6.1 阶段定义（5 阶段）

| 序号 | 阶段 ID | 名称 | 输入 | 输出 | Agent | 人工审批 |
|------|---------|------|------|------|-------|---------|
| 1 | requirements | 需求分析 | 用户需求描述 | docs/specs/requirements.md | pm-agent | ✅ |
| 2 | product | 产品设计 | requirements.md | docs/specs/product.md | pm-agent | ✅ |
| 3 | tech | 技术设计 | product.md | docs/specs/tech.md | architect-agent | ✅ |
| 4 | implementation | 编码实现 | tech.md | backend/ + frontend/ | developer-agent | ❌ |
| 5 | testing | 测试验证 | 代码 + requirements.md | 测试代码 + 测试报告 | qa-agent | ❌ |

### 6.2 测试技术栈

- **后端测试**：JUnit 5 + Spring Boot Test + MockMvc
- **前端测试**：Jest/Vitest + React Testing Library
- **集成测试**：TestContainers（MySQL）

---

## 7. 验证计划

### 7.1 验证系统（Todo System）

| 维度 | 选择 |
|------|------|
| 项目 | 个人待办管理系统（Todo） |
| 类型 | 前后端分离 Web 应用 |
| 后端 | Spring Boot 3.x + MySQL |
| 前端 | React 18 + TypeScript |
| 测试 | JUnit 5 + Jest/Vitest |
| 功能 | CRUD + 状态管理 + 过滤筛选 |

### 7.2 三周逐步计划

#### 第 1 周：框架搭建 + 调用链验证

| 天 | 做什么 | 产出 | 验证目标 |
|----|--------|------|---------|
| Day 1 | 环境准备 + Claude Code CLI 调用验证 | 确认 CLI 可用 | 调用链可行 |
| Day 2 | 创建项目结构 + 写 agent 定义 | 完整目录结构 | 项目结构就绪 |
| Day 3 | 手写 CLAUDE.md + 跑通 requirements 阶段 | docs/specs/requirements.md | 上下文传递有效 |
| Day 4 | 跑通 product 阶段 | docs/specs/product.md | 产品设计闭环 |
| Day 5 | 跑通 tech 阶段 + 首次 quality-gate | docs/specs/tech.md + review | 质量把关闭环 |

#### 第 2 周：编码 + 测试阶段

| 天 | 做什么 | 产出 | 验证目标 |
|----|--------|------|---------|
| Day 6 | 跑通后端 implementation | Spring Boot 项目代码 | 后端代码生成 |
| Day 7 | 跑通前端 implementation | React 项目代码 | 前端代码生成 |
| Day 8 | 跑通 testing 阶段（后端） | JUnit 测试代码 + 通过 | 后端测试闭环 |
| Day 9 | 跑通 testing 阶段（前端） | Jest/Vitest 测试代码 + 通过 | 前端测试闭环 |
| Day 10 | 端到端集成验证 | 前后端联调通过 | 系统可运行 |

#### 第 3 周：自动化 + 全流程贯通

| 天 | 做什么 | 产出 | 验证目标 |
|----|--------|------|---------|
| Day 11 | 编写 context-builder + pipeline skills | Skills 实现 | 上下文自动化 |
| Day 12 | 编写 quality-gate + memory-sync skills | Skills 实现 | 质量和记忆自动化 |
| Day 13 | 全流程自动化端到端测试 | 全自动跑通 | 框架可用性 |
| Day 14-15 | 问题修复 + V2 规划 | 修复 + V2 清单 | 稳定性 |

---

## 8. 代码量评估

**V1 总代码量：~50 行脚本**（质量验证 + 构建命令）。

核心洞察：OpenClaw agent 本身就是一个有智能的编排器，不需要为它写"编排代码"——按照 SOUL.md 和 SKILL.md 的提示词指令自己编排。

---

## 9. V2 演进方向

| 妥协 | V2 如何补回 |
|------|-----------|
| 单模型 Review | 引入第二模型交叉 Review |
| 不用 Agent Teams | 验证 Agent Teams 行为后引入 |
| 不用 Hooks | 验证 Hook 机制后引入 |
| 无知识库检索 | 引入向量化知识库 |
| 无配置化 | 引入 aifd.yaml 配置文件 |

---

*文档结束。V1 核心策略：用 OpenClaw agent 的智能替代编排代码，用提示词和配置替代应用开发，3 周内从需求到可运行系统走通全流程。*
