# AI 驱动全流程研发框架 - 零代码方案

> **核心理念：** 通过提示词 + Skill + 工作流约定，无需编写代码即可实现

---

## 1. 零代码可行性分析

### 1.1 OpenClaw 已有能力

| 能力 | 对应功能 | 用途 |
|------|---------|------|
| **Skills** | `SKILL.md` | 定义专业技能和工作流程 |
| **Hooks** | `HOOK.md` + `handler.ts` | 事件驱动自动化（需要少量 TS） |
| **Memory** | `MEMORY.md` + `memory/*.md` | 知识积累和上下文 |
| **AGENTS.md** | 工作空间约定 | 定义工作流程和行为规范 |
| **sessions_spawn** | 子 Agent 生成 | 多 Agent 编排 |
| **sessions_send** | Agent 间通信 | 协作和反馈 |
| **subagents** | 管理 | 状态跟踪和控制 |
| **Cron** | 定时任务 | 周期性检查 |

### 1.2 零代码程度

- ✅ **100% 零代码**：Skills + Memory + AGENTS.md 约定
- ⚠️ **少量代码**：Hooks（如果需要事件触发，约 10-20 行 TS）

**结论：核心功能可零代码实现，Hooks 可选**

---

## 2. 零代码架构

### 2.1 Skill 驱动设计

```
┌─────────────────────────────────────────────────────────────┐
│                    Orchestrator Skill                        │
│                                                              │
│  职责：接收架构师目标 → 分解任务 → 调度 Agent → 聚合结果      │
│                                                              │
│  触发词：/dev, /开发, "帮我实现", "开发一个"                 │
└────────────┬────────────────────────────────────────────────┘
             │
             │ 1. 分析任务
             │ 2. 检索上下文 (memory_search)
             │ 3. 分解为子任务
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│                   Worker Skills (可组合)                     │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Analyst      │  │ Architect    │  │ Developer    │      │
│  │ 需求分析     │  │ 技术设计     │  │ 编码实现     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ QA           │  │ Reviewer     │  │ DocWriter    │      │
│  │ 测试验证     │  │ 代码审查     │  │ 文档编写     │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 核心文件结构

```
workspace/
├── AGENTS.md              # 主工作流程定义
├── SOUL.md                # Orchestrator 角色
├── USER.md                # Gary 的偏好
├── MEMORY.md              # 长期记忆（架构决策、技术栈）
├── memory/                # 日常记录
│   └── 2026-03-04.md
│
├── skills/                # 技能定义（零代码）
│   ├── dev-orchestrator/  # 主编排器
│   │   └── SKILL.md
│   │
│   ├── analyst/           # 需求分析
│   │   └── SKILL.md
│   │
│   ├── architect/         # 技术设计
│   │   └── SKILL.md
│   │
│   ├── developer/         # 编码实现
│   │   └── SKILL.md
│   │
│   ├── qa-gate/           # 质量检查
│   │   └── SKILL.md
│   │
│   └── context-builder/   # 上下文构建
│       └── SKILL.md
│
├── knowledge/             # 项目知识库
│   ├── tech-stack.md      # 技术栈规范
│   ├── api-conventions.md # API 规范
│   └── best-practices.md  # 最佳实践
│
└── hooks/                 # 可选：事件驱动
    └── task-complete/
        ├── HOOK.md
        └── handler.ts     # 少量代码
```

---

## 3. 核心 Skill 设计

### 3.1 Orchestrator Skill

**文件：** `skills/dev-orchestrator/SKILL.md`

```markdown
---
name: dev-orchestrator
description: |
  AI驱动全流程研发的主编排器。当架构师描述开发目标时触发。
  触发词：/dev, /开发, "帮我实现", "开发一个功能", "实现一个系统"
  职责：任务分解、上下文准备、Agent调度、质量把关、迭代优化。
---

# Dev Orchestrator

你是 AI 研发团队的编排器，负责协调多个专业 Agent 完成软件研发任务。

## 工作流程

### 1. 接收目标
从架构师处接收业务目标描述。

### 2. 构建上下文
使用 `memory_search` 检索：
- 项目背景（MEMORY.md）
- 技术栈规范（knowledge/tech-stack.md）
- API 规范（knowledge/api-conventions.md）
- 历史决策（MEMORY.md 中的架构决策）

### 3. 任务分解
将复杂任务分解为子任务，格式：

```yaml
task_id: TASK-001
description: 实现用户认证 API
subtasks:
  - id: TASK-001-1
    type: analysis
    description: 分析认证需求
    agent: analyst
  - id: TASK-001-2
    type: design
    description: 设计认证方案
    agent: architect
    depends_on: [TASK-001-1]
  - id: TASK-001-3
    type: implementation
    description: 实现认证 API
    agent: developer
    depends_on: [TASK-001-2]
  - id: TASK-001-4
    type: testing
    description: 编写测试用例
    agent: qa
    depends_on: [TASK-001-3]
```

### 4. 调度执行
按依赖顺序调用 `sessions_spawn`：

```
sessions_spawn({
  task: "<子任务描述>",
  runtime: "subagent",
  agentId: "<agent类型>",
  model: "<模型>",
  cwd: "<项目路径>"
})
```

### 5. 质量检查
每个子任务完成后，调用 `qa-gate` skill 检查：
- 功能完整性
- 代码质量
- 测试覆盖率

### 6. 迭代优化
如果不通过质量检查：
- 生成改进建议
- 重新调度 Agent
- 最多迭代 3 次

## Agent 类型映射

| 子任务类型 | agentId | 说明 |
|-----------|---------|------|
| analysis | analyst | 需求分析 |
| design | architect | 技术设计 |
| implementation | developer | 编码实现 |
| testing | qa | 测试验证 |
| review | reviewer | 代码审查 |
| documentation | doc-writer | 文档编写 |

## 上下文模板

为每个 Agent 准备结构化上下文：

```markdown
# 任务上下文

## 1. 项目背景
{从记忆检索}

## 2. 当前目标
{架构师描述}

## 3. 相关决策
{历史决策}

## 4. 技术约束
{技术栈规范}

## 5. 具体任务
{子任务描述}

## 6. 验收标准
{质量要求}
```

## 示例对话

**架构师：** "帮我实现一个用户登录功能"

**Orchestrator：**
1. 检索上下文：找到用户系统相关的设计文档
2. 分解任务：
   - 分析登录需求（analyst）
   - 设计认证方案（architect）
   - 实现登录 API（developer）
   - 编写测试用例（qa）
3. 依次调度执行
4. 质量检查通过后，汇报完成
```

### 3.2 Context Builder Skill

**文件：** `skills/context-builder/SKILL.md`

```markdown
---
name: context-builder
description: |
  为 Claude Code 构建结构化上下文。从记忆和知识库检索相关信息，
  组织成 Claude Code 可理解的格式。由 dev-orchestrator 调用。
---

# Context Builder

## 职责
为执行层 Agent 准备全面、准确、清晰的上下文。

## 工作流程

### 1. 分析任务
理解任务类型和需求：
- 需求分析 → 检索业务背景
- 技术设计 → 检索架构决策
- 编码实现 → 检索技术栈和代码规范
- 测试验证 → 检索测试规范

### 2. 检索记忆
使用 `memory_search` 搜索：
- 项目相关记忆
- 技术决策
- 历史问题

### 3. 加载知识库
读取 `knowledge/` 目录：
- `tech-stack.md` - 技术栈
- `api-conventions.md` - API 规范
- `best-practices.md` - 最佳实践

### 4. 构建上下文
输出结构化上下文：

```markdown
# 任务上下文

## 项目信息
{项目名称、描述、当前阶段}

## 业务背景
{业务域知识、用户场景}

## 技术环境
- 技术栈：{从 knowledge/tech-stack.md}
- 代码规范：{从 knowledge/best-practices.md}
- API 规范：{从 knowledge/api-conventions.md}

## 相关决策
{从 MEMORY.md 检索的历史决策}

## 当前任务
{具体要完成的任务}

## 验收标准
{质量要求}
```

## 检索策略

```javascript
// 示例调用
memory_search({
  query: "用户认证 登录 JWT token",
  maxResults: 5
})
```
```

### 3.3 QA Gate Skill

**文件：** `skills/qa-gate/SKILL.md`

```markdown
---
name: qa-gate
description: |
  质量检查门。验证 Agent 输出质量，决定是否需要迭代。
  检查维度：功能完整性、代码质量、测试覆盖率、文档完整性。
---

# QA Gate

## 职责
验证执行结果，确保质量达标。

## 检查维度

### 1. 功能完整性
- [ ] 实现了所有需求点
- [ ] 边界情况已处理
- [ ] 错误处理完善

### 2. 代码质量
- [ ] 代码可读性好
- [ ] 命名清晰
- [ ] 没有明显 bug
- [ ] 符合项目规范

### 3. 测试覆盖
- [ ] 单元测试已编写
- [ ] 测试覆盖主要场景
- [ ] 边界情况有测试

### 4. 文档完整
- [ ] API 文档已更新
- [ ] README 已更新（如需要）
- [ ] 注释清晰

## 评分标准

```yaml
评分维度:
  功能完整性: 0-25分
  代码质量: 0-25分
  测试覆盖: 0-25分
  文档完整: 0-25分

通过线: 80分
优秀线: 90分
```

## 输出格式

### 通过
```json
{
  "status": "pass",
  "score": 85,
  "breakdown": {
    "功能完整性": 22,
    "代码质量": 21,
    "测试覆盖": 20,
    "文档完整": 22
  },
  "summary": "功能完整，代码质量良好，测试覆盖充分"
}
```

### 需要改进
```json
{
  "status": "needs_improvement",
  "score": 65,
  "breakdown": {
    "功能完整性": 20,
    "代码质量": 18,
    "测试覆盖": 12,
    "文档完整": 15
  },
  "issues": [
    "测试覆盖率不足，缺少边界情况测试",
    "API 文档未更新"
  ],
  "suggestions": [
    "添加更多测试用例，特别是错误场景",
    "更新 API 文档，说明新增接口"
  ]
}
```

## 迭代策略

如果 `status: needs_improvement`：
1. 将 `issues` 和 `suggestions` 注入上下文
2. 重新调度原 Agent
3. 最多迭代 3 次
```

---

## 4. 工作流约定（AGENTS.md）

**文件：** `AGENTS.md`

```markdown
# AGENTS.md - AI 研发团队工作空间

## 角色

你是 **Claw**，AI 研发团队的编排器。你的团队包括：
- **Analyst** - 需求分析专家
- **Architect** - 技术架构师
- **Developer** - 代码实现者
- **QA** - 质量保证工程师
- **Reviewer** - 代码审查员

## 工作流程

### 当架构师描述开发目标时：

1. **触发** `dev-orchestrator` skill
2. **遵循**该 skill 定义的工作流程
3. **不要**跳过质量检查环节

### 任务分解原则

- 每个子任务独立可测试
- 明确依赖关系
- 单个子任务不超过 2 小时工作量

### 质量标准

- 所有代码必须通过 QA Gate
- 最多迭代 3 次
- 达到 80 分才算通过

## Agent 调度

使用 `sessions_spawn` 调度子任务：

```javascript
sessions_spawn({
  task: "详细的任务描述",
  runtime: "subagent",
  agentId: "developer",  // 或 analyst, architect, qa
  model: "claude-sonnet-4-5",
  cwd: "/path/to/project"
})
```

## 记忆更新

每次完成任务后：
1. 更新 `memory/YYYY-MM-DD.md` 记录进展
2. 重要决策写入 `MEMORY.md`
3. 新知识补充到 `knowledge/` 目录

## 禁止事项

- 不要跳过质量检查
- 不要忽略测试
- 不要在没有上下文的情况下开始编码
- 不要超过 3 次迭代
```

---

## 5. 知识库结构

### 5.1 技术栈规范

**文件：** `knowledge/tech-stack.md`

```markdown
# 技术栈规范

## 后端
- 语言：TypeScript / Node.js
- 框架：NestJS
- 数据库：PostgreSQL + Prisma ORM
- 缓存：Redis
- 消息队列：Bull

## 前端
- 框架：React + Next.js
- 状态管理：Zustand
- UI 组件：Ant Design
- 样式：TailwindCSS

## 测试
- 单元测试：Jest
- E2E 测试：Playwright
- API 测试：Supertest

## 部署
- 容器：Docker
- CI/CD：GitHub Actions
- 监控：Prometheus + Grafana
```

### 5.2 API 规范

**文件：** `knowledge/api-conventions.md`

```markdown
# API 规范

## RESTful 约定
- 使用名词复数：`/users`, `/orders`
- HTTP 方法语义：GET 查询，POST 创建，PUT 更新，DELETE 删除
- 版本控制：`/api/v1/users`

## 响应格式
```json
{
  "code": 0,
  "message": "success",
  "data": { ... },
  "timestamp": 1709548800000
}
```

## 错误处理
```json
{
  "code": 40001,
  "message": "参数错误",
  "errors": [
    { "field": "email", "message": "邮箱格式不正确" }
  ]
}
```

## 认证
- 方式：JWT Bearer Token
- Header：`Authorization: Bearer <token>`
- 过期时间：Access Token 2h，Refresh Token 7d
```

---

## 6. 实施步骤

### Step 1: 创建 Skill 目录

```bash
mkdir -p skills/dev-orchestrator
mkdir -p skills/context-builder
mkdir -p skills/qa-gate
mkdir -p knowledge
```

### Step 2: 编写 Skills

按照上面的模板创建各 skill 的 `SKILL.md` 文件。

### Step 3: 配置 AGENTS.md

将工作流约定写入 `AGENTS.md`。

### Step 4: 初始化知识库

填写 `knowledge/` 下的规范文件。

### Step 5: 测试

```
你（架构师）：/dev 实现一个用户注册功能

Claw（Orchestrator）：
1. 检索上下文...
2. 分解任务...
3. 调度 Agent...
4. 质量检查...
5. 完成！
```

---

## 7. 可选：Hooks（如需事件驱动）

如果需要在特定事件时自动触发，可以添加 Hooks（需要少量 TypeScript 代码）。

### 示例：任务完成通知

**文件：** `hooks/task-complete/HOOK.md`

```markdown
---
name: task-complete
description: 任务完成时发送通知
metadata:
  { "openclaw": { "events": ["agent_end"] } }
---

# Task Complete Hook

当 Agent 完成任务时，发送飞书通知。
```

**文件：** `hooks/task-complete/handler.ts`

```typescript
// 约 10-20 行代码
export default async function handler(event: AgentEndEvent) {
  if (event.result?.status === 'ok') {
    // 发送飞书消息
    await sendFeishuMessage(`✅ 任务完成: ${event.task}`);
  }
}
```

---

## 8. 对比：零代码 vs 编码方案

| 方面 | 零代码方案 | 编码方案 |
|------|-----------|---------|
| **实现方式** | Skills + AGENTS.md | TypeScript 代码 |
| **灵活性** | 中等（受 Skill 机制限制） | 高（可任意编程） |
| **维护成本** | 低（修改 Prompt 即可） | 中（需要代码维护） |
| **调试难度** | 中（依赖 Prompt 调优） | 低（标准调试） |
| **扩展性** | 中等 | 高 |
| **上手难度** | 低 | 中 |
| **Hooks** | 可选（少量代码） | 需要 |

---

## 9. 总结

**零代码方案可行！**

核心三要素：
1. **Skills** - 定义专业能力和工作流程
2. **AGENTS.md** - 约定行为规范
3. **Memory + Knowledge** - 积累上下文

**建议：**
- 先用零代码方案快速验证
- 发现瓶颈后再考虑编码优化
- Hooks 按需添加（真正需要事件驱动时）

**下一步：**
1. 创建 Skill 目录结构
2. 编写核心 Skills
3. 用简单功能测试端到端流程
```

---

**文档状态：** Draft v0.1
**更新时间：** 2026-03-04
