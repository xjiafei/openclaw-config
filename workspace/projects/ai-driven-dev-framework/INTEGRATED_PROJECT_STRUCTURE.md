# OpenClaw + Claude Code 集成项目结构

> **设计原则：**
> - OpenClaw 作为编排层（记忆、IM、知识库、Agent 协调）
> - Claude Code 作为执行层（实际编码工作）
> - 两者共享知识库和规范

---

## 完整目录结构

```
project-root/
│
├── .openclaw/                          # OpenClaw 工作空间（编排层）
│   ├── workspace/                      # 主工作空间
│   │   ├── AGENTS.md                   # OpenClaw 工作流约定 ⭐
│   │   ├── SOUL.md                     # Orchestrator 角色
│   │   ├── USER.md                     # 架构师偏好
│   │   ├── MEMORY.md                   # 长期记忆（架构决策） ⭐
│   │   ├── IDENTITY.md                 # AI 身份
│   │   │
│   │   ├── memory/                     # 日常记忆 ⭐
│   │   │   ├── 2026-03-04.md
│   │   │   └── heartbeat-state.json
│   │   │
│   │   ├── skills/                     # OpenClaw Skills ⭐
│   │   │   ├── dev-orchestrator/       # 主编排器
│   │   │   │   └── SKILL.md
│   │   │   ├── context-builder/        # 上下文构建
│   │   │   │   └── SKILL.md
│   │   │   ├── qa-gate/                # 质量检查
│   │   │   │   └── SKILL.md
│   │   │   ├── analyst/                # 需求分析
│   │   │   │   └── SKILL.md
│   │   │   ├── architect/              # 技术设计
│   │   │   │   └── SKILL.md
│   │   │   ├── developer/              # 开发实现
│   │   │   │   └── SKILL.md
│   │   │   └── reviewer/               # 代码审查
│   │   │       └── SKILL.md
│   │   │
│   │   ├── hooks/                      # OpenClaw Hooks（可选）
│   │   │   ├── task-complete/
│   │   │   │   ├── HOOK.md
│   │   │   │   └── handler.ts
│   │   │   └── session-archived/
│   │   │       ├── HOOK.md
│   │   │       └── handler.ts
│   │   │
│   │   └── .claude/                    # Claude Code 配置（在 OpenClaw 内）
│   │       ├── settings.json           # Claude Code 设置
│   │       └── commands/               # Claude Code 斜杠命令
│   │           ├── analyze.md
│   │           ├── design.md
│   │           ├── implement.md
│   │           └── review.md
│   │
│   ├── agents/                         # 多 Agent 配置
│   │   ├── main/                       # 主 Orchestrator
│   │   │   └── agent/
│   │   │       └── auth-profiles.json
│   │   ├── claude-worker/              # Claude Code Worker
│   │   │   └── workspace/
│   │   │       └── .claude/
│   │   └── qa-agent/                   # QA Agent
│   │       └── workspace/
│   │
│   └── openclaw.json                   # OpenClaw 主配置 ⭐
│
├── .claude/                            # Claude Code 工作目录（执行层）
│   ├── CLAUDE.md                       # Claude Code 主配置 ⭐
│   │
│   ├── agents/                         # Claude Code Agents
│   │   ├── analyst.md                  # 需求分析 Agent
│   │   ├── architect.md                # 架构师 Agent
│   │   ├── developer.md                # 开发 Agent
│   │   ├── tester.md                   # 测试 Agent
│   │   └── reviewer.md                 # 审查 Agent
│   │
│   ├── skills/                         # Claude Code Skills
│   │   ├── backend/
│   │   │   └── SKILL.md
│   │   ├── frontend/
│   │   │   └── SKILL.md
│   │   ├── database/
│   │   │   └── SKILL.md
│   │   └── testing/
│   │       └── SKILL.md
│   │
│   ├── commands/                       # Claude Code 斜杠命令
│   │   ├── /analyze.md
│   │   ├── /design.md
│   │   ├── /implement.md
│   │   ├── /test.md
│   │   ├── /review.md
│   │   └── /deploy.md
│   │
│   └── hooks/                          # Claude Code Hooks
│       ├── pre-commit.sh
│       └── post-merge.sh
│
├── docs/                               # 项目文档（共享） ⭐
│   │
│   ├── specs/                          # 全量规格文档
│   │   ├── requirements/               # 需求规格
│   │   │   ├── business-requirements.md
│   │   │   └── user-requirements.md
│   │   │
│   │   ├── product/                    # 产品规格
│   │   │   ├── prd/
│   │   │   │   ├── overview.md
│   │   │   │   └── features.md
│   │   │   ├── prototype/
│   │   │   │   └── wireframes.md
│   │   │   └── user-stories/
│   │   │       └── US-001-auth.md
│   │   │
│   │   ├── tech/                       # 技术规格
│   │   │   ├── architecture.md         # 系统架构
│   │   │   ├── backend-design.md       # 后端设计
│   │   │   ├── frontend-design.md      # 前端设计
│   │   │   ├── database-design.md      # 数据库设计
│   │   │   ├── api-design.md           # API 设计
│   │   │   └── test-design.md          # 测试设计
│   │   │
│   │   ├── testing/                    # 测试规格
│   │   │   ├── test-strategy.md
│   │   │   └── test-cases/
│   │   │
│   │   └── deploy/                     # 部署规格
│   │       ├── deployment.md
│   │       └── rollback.md
│   │
│   ├── features/                       # 特性规格（增量） ⭐
│   │   └── FEATURE-001-user-auth/
│   │       ├── requirements.md         # 需求分析
│   │       ├── product-design.md       # 产品设计
│   │       ├── tech-design.md          # 技术设计
│   │       ├── test-plan.md            # 测试计划
│   │       ├── deploy-plan.md          # 部署计划
│   │       │
│   │       └── reviews/                # 评审记录
│   │           ├── product-review.md
│   │           ├── tech-review.md
│   │           └── code-review.md
│   │
│   └── knowledge/                      # 知识库（共享） ⭐
│       │
│       ├── templates/                  # 模板
│       │   ├── backend-patterns/
│       │   │   ├── db-design.md
│       │   │   ├── api-patterns.md
│       │   │   └── service-patterns.md
│       │   │
│       │   ├── frontend-patterns/
│       │   │   ├── component-patterns.md
│       │   │   ├── state-patterns.md
│       │   │   └── hooks-patterns.md
│       │   │
│       │   └── testing-patterns/
│       │       ├── unit-test.md
│       │       ├── integration-test.md
│       │       └── e2e-test.md
│       │
│       ├── best-practices/             # 最佳实践
│       │   ├── coding-standards.md
│       │   ├── git-workflow.md
│       │   ├── code-review.md
│       │   └── security.md
│       │
│       ├── standards/                  # 规范
│       │   ├── coding-conventions.md   # 编码规范
│       │   ├── commit-conventions.md   # 提交规范
│       │   ├── api-conventions.md      # API 规范
│       │   └── ui-guidelines.md        # UI 规范
│       │
│       ├── domain/                     # 领域知识
│       │   ├── business-rules.md
│       │   ├── domain-models.md
│       │   └── glossary.md
│       │
│       └── tech-stack/                 # 技术栈
│           ├── backend.md
│           ├── frontend.md
│           ├── database.md
│           └── devops.md
│
├── workspace/                          # AI 工作区（临时文件） ⭐
│   ├── tasks/                          # 任务状态
│   │   ├── TASK-001.yaml
│   │   └── TASK-002.yaml
│   │
│   ├── artifacts/                      # 中间产物
│   │   ├── analysis/
│   │   ├── designs/
│   │   └── drafts/
│   │
│   ├── cache/                          # 缓存
│   │   └── context-cache.json
│   │
│   └── logs/                           # 日志
│       ├── agent-runs/
│       └── qa-results/
│
└── repos/                              # 代码仓库 ⭐
    ├── backend/                        # 后端代码
    │   ├── src/
    │   ├── tests/
    │   ├── package.json
    │   └── README.md
    │
    ├── frontend/                       # 前端代码
    │   ├── src/
    │   ├── tests/
    │   ├── package.json
    │   └── README.md
    │
    ├── testing/                        # 测试代码
    │   ├── integration/
    │   ├── e2e/
    │   ├── performance/
    │   └── reports/
    │
    └── devops/                         # DevOps 代码
        ├── docker/
        ├── k8s/
        ├── ci/
        └── scripts/
```

---

## 核心配置文件

### 1. OpenClaw 主配置

**文件：** `.openclaw/openclaw.json`

```json5
{
  agents: {
    list: [
      {
        id: "orchestrator",
        name: "Orchestrator",
        default: true,
        workspace: ".openclaw/workspace",
        model: "anthropic/claude-opus-4-6"
      },
      {
        id: "claude-worker",
        name: "Claude Code Worker",
        workspace: ".openclaw/agents/claude-worker/workspace",
        model: "anthropic/claude-sonnet-4-5",
        tools: {
          allow: ["read", "write", "edit", "exec", "browser"],
          deny: ["sessions_spawn"] // Worker 不能再 spawn
        }
      },
      {
        id: "qa-agent",
        name: "QA Agent",
        workspace: ".openclaw/agents/qa-agent/workspace",
        model: "anthropic/claude-sonnet-4-5"
      }
    ]
  },

  bindings: [
    {
      agentId: "orchestrator",
      match: { channel: "feishu" }
    }
  ],

  tools: {
    agentToAgent: {
      enabled: true,
      allow: ["*"]
    },
    sessions: {
      visibility: "tree"
    }
  },

  skills: {
    entries: {
      "dev-orchestrator": { enabled: true },
      "context-builder": { enabled: true },
      "qa-gate": { enabled: true }
    }
  }
}
```

### 2. OpenClaw 工作流约定

**文件：** `.openclaw/workspace/AGENTS.md`

```markdown
# AGENTS.md - AI 研发团队

## 角色定位

你是 **Claw**，AI 研发团队的 Orchestrator。

## 工作流程

### 1. 接收目标
从飞书接收架构师的开发需求。

### 2. 构建上下文
使用 `memory_search` 检索：
- 长期记忆：`.openclaw/workspace/MEMORY.md`
- 日常记忆：`.openclaw/workspace/memory/*.md`
- 知识库：`docs/knowledge/`

### 3. 任务分解
参考 `docs/specs/` 中的规格模板，分解为：
- requirements → analyst
- product-design → architect
- tech-design → architect
- implementation → claude-worker
- testing → qa-agent

### 4. 调度执行
使用 `sessions_spawn` 调度 Agent：

```javascript
sessions_spawn({
  task: "详细的任务描述",
  runtime: "acp",  // 或 "subagent"
  agentId: "claude-worker",
  cwd: "repos/backend"
})
```

### 5. 质量检查
调用 `qa-gate` skill，检查：
- 功能完整性
- 代码质量
- 测试覆盖率

### 6. 迭代优化
最多迭代 3 次，每次注入改进建议。

## 文档更新

完成后更新：
- `docs/features/FEATURE-XXX/` - 特性文档
- `workspace/tasks/TASK-XXX.yaml` - 任务状态
- `memory/YYYY-MM-DD.md` - 日常记录
- `MEMORY.md` - 重要决策（如有）

## 知识库路径

- 规格模板：`docs/specs/`
- 知识库：`docs/knowledge/`
- 特性文档：`docs/features/`
```

### 3. OpenClaw 长期记忆

**文件：** `.openclaw/workspace/MEMORY.md`

```markdown
# MEMORY.md - 长期记忆

## 项目信息

- **项目名称：** [待填写]
- **技术栈：** 见 `docs/knowledge/tech-stack/`
- **架构风格：** [待确定]

## 架构决策记录（ADR）

### ADR-001: [示例] 使用 PostgreSQL 作为主数据库
- **日期：** 2026-03-04
- **决策：** 选择 PostgreSQL
- **理由：** 事务支持、生态成熟、团队熟悉
- **影响：** 需要 ORM（Prisma）

## 技术偏好

- 后端：TypeScript + NestJS
- 前端：React + Next.js
- 数据库：PostgreSQL
- 测试：Jest + Playwright

## 工作习惯

- 架构师喜欢先看设计文档再编码
- 质量要求高，必须通过 QA Gate
- 偏好渐进式开发，小步快跑
```

### 4. Claude Code 主配置

**文件：** `.claude/CLAUDE.md`

```markdown
# CLAUDE.md - Claude Code 配置

## 项目概述

[项目描述]

## 技术栈

详见：`../docs/knowledge/tech-stack/`

## 工作流程

### 当被 Orchestrator 调用时：

1. **接收任务**
   从 OpenClaw Orchestrator 接收具体任务

2. **加载上下文**
   读取：
   - 任务描述（来自 Orchestrator）
   - 技术设计：`../docs/features/FEATURE-XXX/tech-design.md`
   - 代码规范：`../docs/knowledge/standards/`
   - 模式参考：`../docs/knowledge/templates/`

3. **执行任务**
   - 编写代码
   - 编写测试
   - 更新文档

4. **输出结果**
   - 代码变更
   - 测试结果
   - 注意事项

## 代码规范

遵循：`../docs/knowledge/standards/coding-conventions.md`

## Git 提交规范

遵循：`../docs/knowledge/standards/commit-conventions.md`

## 可用命令

- `/analyze` - 分析需求
- `/design` - 设计方案
- `/implement` - 实现代码
- `/test` - 编写测试
- `/review` - 代码审查
```

---

## 工作流程示意

### 端到端流程

```
┌─────────────────────────────────────────────────────────────┐
│  架构师（飞书）："实现用户登录功能"                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  OpenClaw Orchestrator                                       │
│  (skills/dev-orchestrator)                                   │
│                                                              │
│  1. memory_search("用户认证 登录")                           │
│  2. 读取 docs/knowledge/domain/                              │
│  3. 分解任务：                                               │
│     - 需求分析 → analyst                                     │
│     - 技术设计 → architect                                   │
│     - 代码实现 → claude-worker                               │
│     - 测试验证 → qa-agent                                    │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
        ▼            ▼            ▼
   ┌─────────┐  ┌─────────┐  ┌─────────┐
   │ Analyst │  │Architect│  │ Worker  │
   └────┬────┘  └────┬────┘  └────┬────┘
        │            │            │
        ▼            ▼            ▼
   ┌─────────────────────────────────────┐
   │  docs/features/FEATURE-001/         │
   │  ├── requirements.md                │
   │  ├── tech-design.md                 │
   │  └── code changes in repos/         │
   └─────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  QA Gate (skills/qa-gate)                                    │
│  - 检查功能完整性                                            │
│  - 检查代码质量                                              │
│  - 检查测试覆盖                                              │
│                                                              │
│  不通过？→ 迭代（最多3次）                                   │
│  通过？→ 完成，更新记忆                                      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│  更新记忆                                                    │
│  - memory/2026-03-04.md（日常）                              │
│  - MEMORY.md（如有重要决策）                                 │
│  - workspace/tasks/TASK-001.yaml（状态）                     │
│                                                              │
│  飞书通知架构师："✅ 用户登录功能已完成"                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 职责划分

| 层级 | 组件 | 职责 |
|------|------|------|
| **编排层** | OpenClaw Orchestrator | 接收需求、任务分解、Agent调度、质量把关、记忆管理 |
| **执行层** | Claude Code Worker | 实际编码、测试编写、文档更新 |
| **共享层** | docs/knowledge/ | 知识库、规范、模板（两者共享） |
| **存储层** | repos/ | 代码仓库 |
| **IM层** | OpenClaw Channels | 飞书等即时通讯 |

---

## 关键优势

### OpenClaw 贡献
- ✅ 记忆体系（MEMORY.md + memory/）
- ✅ 知识库管理（memory_search）
- ✅ IM 集成（飞书等）
- ✅ 多 Agent 编排（sessions_spawn）
- ✅ Skills 系统
- ✅ Hooks 事件驱动

### Claude Code 贡献
- ✅ 强大的编码能力
- ✅ 代码理解和重构
- ✅ 文件操作
- ✅ Git 操作
- ✅ 测试执行

### 融合优势
- ✅ 架构师只需通过飞书描述需求
- ✅ 自动从知识库构建上下文
- ✅ 多 Agent 协作
- ✅ 质量自动检查
- ✅ 持续学习和记忆积累

---

## 下一步实施

### Phase 1: 搭建骨架（1天）
1. 创建目录结构
2. 配置 `openclaw.json`
3. 编写基础 `AGENTS.md`

### Phase 2: 编写 Skills（2-3天）
1. `dev-orchestrator/SKILL.md`
2. `context-builder/SKILL.md`
3. `qa-gate/SKILL.md`

### Phase 3: 初始化知识库（1-2天）
1. 填写 `docs/knowledge/` 基础内容
2. 定义 `docs/specs/` 模板

### Phase 4: 端到端测试（2-3天）
1. 简单功能测试（CRUD）
2. 验证完整流程

---

**文档状态：** Draft v0.1
**更新时间：** 2026-03-04
