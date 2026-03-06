# OpenGoat 项目分析报告

> **项目地址：** https://github.com/marian2js/opengoat
> **分析日期：** 2026-03-04

---

## 1. 项目用途

### 1.1 核心定位

**OpenGoat 是一个构建 AI 自治组织（AI Autonomous Organizations）的平台**，基于 OpenClaw agents。

简单来说：**让你的 AI 团队有组织、有分工、有协作**。

### 1.2 解决的问题

传统 AI Coding 工具的问题：
- 单一 Agent，能力有限
- 没有角色分工
- 缺乏组织协调
- 无法处理复杂项目

OpenGoat 的解决方案：
```
传统模式：
你 → AI Agent → 输出

OpenGoat 模式：
你 → Goat (CEO) → CTO → Engineer 1
                           → Engineer 2
                           → Designer
                   → Product Manager → ...
```

### 1.3 典型使用场景

**场景 1：软件研发团队**
```bash
# 创建组织
opengoat agent create "CTO" --manager --reports-to goat
opengoat agent create "Engineer" --individual --reports-to cto --skill coding
opengoat agent create "Designer" --individual --reports-to cto

# 分配任务
opengoat agent cto --message "Plan the Q2 engineering roadmap"
opengoat agent engineer --message "Implement the auth middleware"
```

**场景 2：产品团队**
```
Goat (CEO)
  ├── Sage (Product Manager)
  │     ├── Alex (Developer)
  │     └── Designer
  └── QA Lead
        └── Tester
```

---

## 2. 核心概念

### 2.1 层级组织结构

```
            goat (CEO / Co-founder)
                    │
        ┌───────────┼───────────┐
        │           │           │
      CTO        Product      QA Lead
        │        Manager         │
   ┌────┼────        │           │
Engineer  Designer  Analyst    Tester
```

**角色类型：**
- **Manager（管理者）**：协调下级，分配任务，不直接执行
- **Individual（执行者）**：具体执行任务

### 2.2 多 Provider 支持

OpenGoat 可以调度多种 AI 工具：

| Provider | 用途 | 配置目录 |
|----------|------|---------|
| OpenClaw | 主要运行时（默认） | `skills/` |
| Claude Code | Anthropic 的编码工具 | `.claude/skills/` |
| Codex | OpenAI 的编码工具 | `.agents/skills/` |
| Cursor | AI 代码编辑器 | `.cursor/skills/` |
| GitHub Copilot CLI | 命令行助手 | `.copilot/skills/` |
| Gemini CLI | Google 的 AI 工具 | `.gemini/skills/` |
| OpenCode | 开源编码工具 | `.opencode/skills/` |
| Lovable | 产品开发工具 | - |

### 2.3 Skills 系统

**角色技能（Role Skills）：**

- **管理者技能：**
  - OpenClaw: `og-board-manager`
  - 其他: `og-boards`
  
- **执行者技能：**
  - OpenClaw: `og-board-individual`
  - 其他: `og-boards`

**技能安装：**
```bash
opengoat skill install og-boards --from /path/to/skill
opengoat skill list --agent goat
```

### 2.4 任务管理

```bash
# 创建任务
opengoat task create \
  --title "Ship auth" \
  --description "Finish middleware + tests" \
  --owner cto \
  --assign engineer

# 查看任务
opengoat task list --as engineer

# 更新状态
opengoat task status <task-id> doing
```

**任务分配规则：**
- 只能分配给自己或下属（直接或间接）
- 只能更新自己或下属的任务

---

## 3. 实现原理

### 3.1 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                      OpenGoat Platform                       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   CLI        │  │   UI Server  │  │   Core       │      │
│  │  (Command)   │  │  (Fastify)   │  │  (Business)  │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Provider Registry                        │  │
│  │  • OpenClaw  • Claude Code  • Codex  • Cursor ...   │  │
│  └──────────────────────────────────────────────────────┘  │
└────────┬─────────────────────────────────────────────────────┘
         │
         │ ACP (Agent Client Protocol)
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                    OpenClaw Gateway                          │
│  • Session 管理  • Agent 编排  • Memory  • Channels        │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 核心模块

**Monorepo 结构：**
```
packages/
├── core/           # 核心业务逻辑
│   ├── opengoat/   # 主门面（OpenGoatService）
│   ├── bootstrap/  # 初始化
│   ├── agents/     # Agent 管理
│   ├── orchestration/ # 编排（管理运行时）
│   ├── sessions/   # 会话管理
│   ├── skills/     # 技能管理
│   ├── providers/  # Provider 适配器
│   └── acp/        # ACP 协议支持
│
├── cli/            # 命令行工具
│   └── cli/
│
└── ui/             # Web UI
    ├── server/     # Fastify API
    └── client/     # React/Vite 前端
```

### 3.3 关键机制

#### 3.3.1 Agent 生命周期

```javascript
// 创建 Agent
opengoat agent create "CTO" --manager --reports-to goat
  ↓
1. 创建本地状态（agents/cto/config.json）
2. 同步创建 OpenClaw agent
3. 安装角色技能
  ↓
Agent 可用
```

```javascript
// 删除 Agent
opengoat agent delete cto
  ↓
1. 同步删除 OpenClaw agent
2. 删除本地状态
  ↓
Agent 已删除
```

#### 3.3.2 Session 映射

```
OpenGoat Session ID: "planning-session"
OpenClaw Session Key: "agent:goat:planning-session"

映射规则：agent:<agent-id>:<opengoat-session-id>
```

**会话连续性：**
```bash
# 同一会话多次对话
opengoat agent goat \
  --session saaslib-planning \
  --message "Create a release checklist for v1.2"

opengoat agent goat \
  --session saaslib-planning \
  --message "Now draft the changelog"
```

#### 3.3.3 任务路由

```
架构师："实现用户登录"
    ↓
Goat (CEO)
    ↓ 分配给
CTO
    ↓ 分解并分配给
Engineer 1: 后端实现
Engineer 2: 前端实现
Designer: UI 设计
```

**路由规则：**
- Manager 通过 Skills 决定如何分配
- 只能分配给直接或间接下属
- 每个 Agent 有独立的 workspace

### 3.4 文件系统布局

```
~/.opengoat/
├── config.json              # 全局配置
├── agents.json              # Agent 列表
├── agents/                  # Agent 状态
│   ├── goat/
│   │   ├── config.json      # Agent 配置
│   │   └── sessions/        # 会话存储
│   ├── cto/
│   └── alex/
│
├── workspaces/              # OpenClaw 工作空间
│   ├── goat/
│   ├── cto/
│   └── alex/
│
├── organization/            # 组织级文档
│   ├── ROLE.md
│   └── BOOTSTRAP.md
│
├── skills/                  # 技能存储
├── providers/               # Provider 配置
└── runs/                    # 运行记录
```

### 3.5 技术栈

**依赖：**
```json
{
  "@agentclientprotocol/sdk": "^0.14.1",  // ACP 协议
  "sql.js": "^1.13.0",                    // SQLite（任务存储）
  "fastify": "...",                       // UI Server
  "react": "...",                         // UI 前端
  "vite": "...",                          // 前端构建
  "typescript": "^5.9.3"                  // 类型系统
}
```

**运行时要求：**
- Node.js >= 20.11.0
- pnpm 10.18.2

---

## 4. 与 Gary 项目的对比

### 4.1 相似之处

| 特性 | OpenGoat | Gary 的项目 |
|------|----------|------------|
| **多 Agent 协作** | ✅ | ✅ |
| **层级组织** | ✅ Manager/Individual | ✅ Orchestrator/Worker |
| **Skills 系统** | ✅ | ✅ |
| **任务管理** | ✅ | ✅ |
| **记忆体系** | ✅（依赖 OpenClaw） | ✅ |
| **质量检查** | ❌ | ✅ QA Gate |
| **迭代机制** | ❌ | ✅ ReAct-Loop |
| **文档管理** | ❌ | ✅ docs/specs |

### 4.2 OpenGoat 的优势

1. **成熟的组织模型**
   - 已实现层级管理
   - 清晰的角色分工
   - 完善的任务分配

2. **多 Provider 支持**
   - 不局限于 OpenClaw
   - 可调度多种 AI 工具
   - 灵活的运行时选择

3. **UI 界面**
   - Web UI 可视化管理
   - 侧边栏组织视图
   - 实时任务状态

4. **生产就绪**
   - 完整的 CLI
   - Docker 支持
   - 文档完善

### 4.3 Gary 项目的优势

1. **研发流程聚焦**
   - 针对软件研发设计
   - 从需求到部署全覆盖
   - 规格文档管理

2. **质量保障**
   - QA Gate 检查机制
   - ReAct-Loop 迭代优化
   - 质量评分系统

3. **知识库管理**
   - 结构化知识库
   - 上下文构建系统
   - 领域知识积累

4. **零代码方案**
   - 纯 Skills + AGENTS.md
   - 易于定制和扩展

---

## 5. 可借鉴的设计

### 5.1 组织模型

```yaml
# Gary 项目可以借鉴的组织结构
goat:
  type: manager
  reports_to: null
  role: "AI Co-founder / CEO"
  
orchestrator:
  type: manager
  reports_to: goat
  role: "Dev Orchestrator"
  
analyst:
  type: individual
  reports_to: orchestrator
  role: "Requirements Analyst"
  
architect:
  type: individual
  reports_to: orchestrator
  role: "Technical Architect"
  
developer:
  type: individual
  reports_to: orchestrator
  role: "Code Developer"
  provider: claude-code
  
qa:
  type: individual
  reports_to: orchestrator
  role: "QA Engineer"
```

### 5.2 Provider 集成

OpenGoat 的多 Provider 模式可以用于：
- Claude Code 作为主要编码 Agent
- OpenClaw 作为编排和 QA Agent
- 其他工具作为辅助

### 5.3 Session 管理

```
OpenGoat 的 session 映射机制：
agent:<agent-id>:<session-id>

Gary 项目可以采用：
- orchestrator:planning
- developer:feature-001
- qa:feature-001-review
```

### 5.4 任务路由

OpenGoat 的任务分配规则：
- 只能分配给下属
- 管理者通过 Skills 协调

Gary 项目可以采用：
- Orchestrator 分配给 Worker
- Worker 执行后汇报给 Orchestrator
- Orchestrator 调用 QA Gate

---

## 6. 集成建议

### 6.1 方案 A：基于 OpenGoat 扩展

```
OpenGoat (基础)
    ↓ 添加
+ docs/specs/          # 规格文档
+ docs/knowledge/      # 知识库
+ skills/qa-gate/      # 质量检查
+ skills/context-builder/  # 上下文构建
+ AGENTS.md 工作流     # 研发流程
```

### 6.2 方案 B：借鉴设计，独立实现

```
Gary 项目
    ↓ 借鉴
+ 层级组织模型
+ 多 Provider 支持
+ Session 映射机制
+ 任务分配规则
```

### 6.3 方案 C：混合方案

```
OpenGoat 作为组织框架
    +
Gary 的 Skills + 知识库 + QA Gate
    ↓
完整的 AI 研发团队
```

---

## 7. 总结

### 7.1 OpenGoat 的核心价值

1. **组织化 AI** - 让 AI 有团队、有分工
2. **多工具协作** - 统一调度多种 AI 工具
3. **生产就绪** - 完整的 CLI + UI + 文档

### 7.2 适用场景

- ✅ 复杂软件项目
- ✅ 多角色协作
- ✅ 需要任务分配和跟踪
- ❌ 简单单 Agent 任务
- ❌ 不需要协作的场景

### 7.3 与 Gary 项目的融合建议

**推荐：方案 C（混合方案）**

```
OpenGoat
├── 提供组织框架
├── 提供 Provider 集成
├── 提供任务管理
└── 提供 UI

Gary 项目
├── 提供研发流程 Skills
├── 提供知识库管理
├── 提供 QA Gate
└── 提供上下文构建

融合结果：完整的 AI 研发团队平台
```

---

**文档状态：** 完成
**分析者：** Claw
**日期：** 2026-03-04
