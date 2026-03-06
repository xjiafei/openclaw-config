# AI 驱动全流程研发框架 - 技术方案

> **作者：** Claw & Gary
> **日期：** 2026-03-04
> **版本：** v0.1-draft

---

## 1. 背景与目标

### 1.1 核心洞察

**Claude Code 的能力边界：**
- ✅ 已能覆盖：市场调研 → 需求分析 → 产品设计 → 技术设计 → 开发测试 → CI/CD
- ⚠️ 两个关键瓶颈：
  1. **上下文依赖**：需要用户输入全面、准确、清晰的业务上下文
  2. **执行确定性**：单次 LLM 处理存在不确定性，需要迭代优化

**OpenClaw 的独特优势：**
1. **记忆机制**：历史会话 + 知识库 + 自我学习，能持续积累上下文
2. **多模型编排**：agent 协调能力，可调度不同优势的模型

### 1.2 目标愿景

构建一个集成框架，让每位架构师拥有 **AI 研发团队**：
- 架构师只需描述业务目标
- AI 自动完成全流程研发工作
- 持续学习和优化

---

## 2. 系统架构

### 2.1 整体架构图

```
┌─────────────────────────────────────────────────────────────┐
│                      架构师 (Gary)                           │
│                   描述业务目标 / 反馈                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                  OpenClaw 编排层 (Orchestrator)              │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ 记忆系统     │  │ 任务分解     │  │ 质量检查     │      │
│  │ Memory       │  │ Task Split   │  │ QA Gate      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Agent 编排引擎                           │  │
│  │  • 任务分发  • 进度跟踪  • 结果聚合  • 迭代控制      │  │
│  └──────────────────────────────────────────────────────┘  │
└────────┬─────────────────────────────────────────────────────┘
         │
         │ sessions_spawn / ACP
         │
         ▼
┌─────────────────────────────────────────────────────────────┐
│                 Claude Code 执行层 (Workers)                 │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Agent 1  │  │ Agent 2  │  │ Agent 3  │  │ Agent N  │   │
│  │ 需求分析 │  │ 技术设计 │  │ 编码实现 │  │ 测试验证 │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                              │
│  每个 Agent 独立 workspace + session + 工具集               │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 核心组件

#### 2.2.1 记忆系统 (Memory System)

**职责：**
- 存储项目知识库（业务域、技术栈、历史决策）
- 积累架构师偏好和工作方式
- 为 Claude Code 准备上下文

**实现方式：**
- `MEMORY.md` - 长期记忆（架构决策、技术偏好）
- `memory/YYYY-MM-DD.md` - 日常记录
- `knowledge/` - 项目知识库目录
- `memory_search` - 语义检索相关上下文

**工作流程：**
```
架构师描述目标
    ↓
memory_search 检索相关上下文
    ↓
构建结构化 Prompt (业务背景 + 相关知识 + 历史决策)
    ↓
传递给 Claude Code Agent
```

#### 2.2.2 任务分解引擎 (Task Split Engine)

**职责：**
- 将复杂研发任务分解为可执行的子任务
- 识别任务依赖关系
- 分配给合适的 Agent

**实现方式：**
- 基于 Prompt 的任务分解（可后期用小模型优化）
- 任务依赖图管理
- Agent 能力匹配

**示例分解：**
```
原始任务：实现用户认证系统

分解结果：
├─ Task 1: 需求分析 (Agent: analyst)
├─ Task 2: 技术方案设计 (Agent: architect, depends: Task 1)
├─ Task 3: 数据库设计 (Agent: db-designer, depends: Task 2)
├─ Task 4: API 实现 (Agent: backend-dev, depends: Task 3)
├─ Task 5: 前端集成 (Agent: frontend-dev, depends: Task 4)
└─ Task 6: 测试编写 (Agent: qa, depends: Task 4, Task 5)
```

#### 2.2.3 质量检查门 (QA Gate)

**职责：**
- 验证 Claude Code 输出质量
- 决定是否需要迭代
- 收集反馈用于改进

**检查维度：**
- 功能完整性
- 代码质量
- 测试覆盖率
- 文档完整性

**迭代策略：**
```python
max_iterations = 3
iteration = 0
quality_score = 0

while quality_score < threshold and iteration < max_iterations:
    result = claude_code_agent.execute(task, context)
    quality_score = qa_gate.evaluate(result)
    
    if quality_score < threshold:
        # 生成改进建议
        feedback = qa_gate.generate_feedback(result)
        context = context + feedback
        iteration += 1
```

#### 2.2.4 Agent 编排引擎

**职责：**
- 管理 Agent 生命周期
- 协调多 Agent 协作
- 跟踪任务进度

**实现方式：**
- 使用 OpenClaw 的 `sessions_spawn` 生成子 agent
- 使用 `sessions_send` 进行 agent 间通信
- 使用 `subagents` 管理运行状态

---

## 3. 关键技术决策

### 3.1 Claude Code 集成方式

**方案 A：ACP 桥接（推荐）**

OpenClaw 已支持 ACP (Agent Client Protocol)，可以直接桥接 Claude Code。

**优势：**
- 标准化协议，易于扩展
- OpenClaw 已有完整实现
- 支持会话管理和上下文传递

**实现：**
```bash
# 在 OpenClaw 中配置 Claude Code Agent
openclaw acp --session agent:claude-code:main
```

**方案 B：sessions_spawn + runtime="acp"**

使用 OpenClaw 的 spawn 能力启动 Claude Code 会话。

```javascript
// 在编排 Agent 中调用
sessions_spawn({
  task: "实现用户登录 API",
  runtime: "acp",
  agentId: "claude-code",
  model: "claude-opus-4-6",
  cwd: "/path/to/project"
})
```

### 3.2 上下文传递策略

**结构化上下文模板：**

```markdown
# 任务上下文

## 1. 项目背景
[从记忆系统检索的项目信息]

## 2. 业务需求
[架构师描述的业务目标]

## 3. 相关决策
[从 MEMORY.md 检索的历史决策]

## 4. 技术约束
[技术栈、架构规范等]

## 5. 参考资料
[从知识库检索的相关文档]

## 6. 当前任务
[具体要完成的任务]

## 7. 质量要求
[验收标准]
```

### 3.3 迭代循环机制

**ReAct-Loop 实现：**

```
┌─────────────┐
│   开始任务   │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ Claude Code 执行     │
│ (第 N 次迭代)        │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐      不通过
│   QA Gate 检查       ├──────────────┐
└──────┬──────────────┘              │
       │ 通过                         │
       ▼                             ▼
┌─────────────┐              ┌──────────────────┐
│   完成任务   │              │ 生成改进反馈      │
└─────────────┘              │ 注入到上下文      │
                             │ iteration++       │
                             └────────┬─────────┘
                                      │
                                      │ if iteration < max
                                      │
                                      ▼
                             ┌─────────────────────┐
                             │ Claude Code 重新执行 │
                             │ (第 N+1 次迭代)      │
                             └─────────────────────┘
```

### 3.4 多 Agent 协作模式

**模式 1：流水线模式**

任务按依赖顺序执行，前一个 Agent 的输出作为后一个的输入。

```
Analyst → Architect → Developer → QA
```

**模式 2：并行模式**

多个 Agent 同时工作在不同模块上。

```
         ┌─ Backend Dev ─┐
Analyst ─┤               ├─ Integrator
         └─ Frontend Dev ─┘
```

**模式 3：审查模式**

一个 Agent 执行，另一个 Agent 审查。

```
Developer → Reviewer → (修改意见) → Developer
```

---

## 4. 实现路径

### 4.1 Phase 1：基础框架（2-3 周）

**目标：** 实现最小可用版本

**任务：**
1. 搭建项目结构
2. 实现记忆系统集成
3. 实现 Claude Code 单 Agent 调用
4. 实现基础 QA Gate
5. 端到端测试：简单功能的完整流程

**验收：**
- 能自动完成一个简单功能（如 CRUD API）
- 全程无需人工干预

### 4.2 Phase 2：任务分解（3-4 周）

**目标：** 支持复杂任务的自动分解

**任务：**
1. 实现任务分解 Prompt
2. 实现依赖图管理
3. 实现多 Agent 协作（流水线模式）
4. 测试：中等复杂度功能

**验收：**
- 能自动分解并完成包含 3-5 个子任务的功能

### 4.3 Phase 3：迭代优化（2-3 周）

**目标：** 实现 ReAct-Loop 机制

**任务：**
1. 实现质量评估指标
2. 实现反馈生成
3. 实现迭代控制逻辑
4. 测试：需要多轮迭代才能完成的任务

**验收：**
- 质量不达标时能自动迭代改进

### 4.4 Phase 4：工程化（2-3 周）

**目标：** 生产可用

**任务：**
1. 错误处理和容错
2. 进度可视化和通知
3. 文档和示例
4. 性能优化

---

## 5. 技术栈

### 5.1 核心组件

- **OpenClaw**: 编排层 + 记忆系统
- **Claude Code**: 执行引擎（通过 ACP）
- **Node.js/TypeScript**: 框架实现语言

### 5.2 配置示例

```json5
// openclaw.json
{
  agents: {
    list: [
      {
        id: "orchestrator",
        name: "Orchestrator",
        workspace: "~/.openclaw/workspace-orchestrator",
        model: "anthropic/claude-opus-4-6"
      },
      {
        id: "claude-code",
        name: "Claude Code Worker",
        workspace: "~/.openclaw/workspace-worker",
        model: "anthropic/claude-sonnet-4-5",
        tools: {
          allow: ["read", "write", "edit", "exec", "browser"],
          deny: ["sessions_spawn"] // Worker 不能再 spawn
        }
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
      allow: ["orchestrator", "claude-code"]
    }
  }
}
```

---

## 6. 风险与挑战

### 6.1 技术风险

| 风险 | 影响 | 缓解策略 |
|------|------|----------|
| Claude Code 输出不稳定 | 高 | 多轮迭代 + 质量检查 |
| 上下文窗口限制 | 中 | 智能摘要 + 分段处理 |
| 任务分解不准确 | 中 | 人工确认 + 逐步优化 Prompt |
| Agent 间通信复杂 | 低 | 标准化消息格式 |

### 6.2 工程挑战

- **成本控制**：多 Agent 调用会增加 API 成本
- **调试困难**：多 Agent 系统难以追踪问题
- **性能瓶颈**：串行任务耗时较长

---

## 7. 下一步行动

### 7.1 立即可做

1. **验证 Claude Code 集成**
   ```bash
   # 测试 OpenClaw ACP 桥接
   openclaw acp --session agent:claude-code:main
   ```

2. **设计第一个测试用例**
   - 目标：实现一个简单的 REST API
   - 预期：全流程自动化

3. **搭建项目结构**
   ```
   projects/ai-driven-dev-framework/
   ├── TECHNICAL_PROPOSAL.md (本文档)
   ├── IMPLEMENTATION.md (实现细节)
   ├── examples/ (示例项目)
   └── tests/ (测试用例)
   ```

### 7.2 需要讨论的问题

1. **Claude Code 的最佳调用方式是什么？**
   - ACP 桥接 vs 直接 spawn？
   - 是否需要定制 Claude Code 的 system prompt？

2. **质量检查的具体标准是什么？**
   - 自动化测试通过率？
   - 代码 review 要点？
   - 文档完整性？

3. **如何处理架构师的中间干预？**
   - 人工确认关键决策？
   - 迭代过程中的人工反馈？

---

## 8. 参考资源

- [OpenClaw 文档](https://docs.openclaw.ai)
- [Agent Client Protocol](https://agentclientprotocol.com/)
- [Claude Code 文档](https://www.anthropic.com/claude-code/)
- OpenClaw Multi-Agent Routing: `/concepts/multi-agent`
- OpenClaw Memory System: `/concepts/memory`
- OpenClaw Session Tools: `/concepts/session-tool`

---

**文档状态：** Draft v0.1
**待完善：** 实现细节、测试用例、成本估算
