# 多角色 Agent 托管决策

> **核心问题：** 产品经理、架构师等角色，应该由 OpenClaw 还是 Claude Code 扮演？
> **决策日期：** 2026-03-04

---

## 1. 两种方案对比

### 方案 A：所有角色都在 OpenClaw

```yaml
OpenClaw Agents:
  - orchestrator (编排器)
  - product-manager (产品经理)
  - architect (架构师)
  - developer (开发者)
  - qa (QA工程师)

协作方式：
  orchestrator → product-manager → architect → developer → qa
  （通过 sessions_spawn 依次调用）
```

**优点：**
- ✅ 统一平台，易于管理
- ✅ 记忆体系完善（MEMORY.md）
- ✅ 知识库共享
- ✅ 飞书集成方便

**缺点：**
- ❌ 编码能力弱（OpenClaw 的编码能力 < Claude Code）
- ❌ 每个 agent 独立 session，上下文不连续
- ❌ 需要手动传递上下文
- ❌ developer 角色不够强

---

### 方案 B：所有角色都在 Claude Code

```bash
claude-code-skill session-start team \
  --agents '{
    "pm": {"prompt": "产品经理"},
    "arch": {"prompt": "架构师"},
    "dev": {"prompt": "开发者"},
    "qa": {"prompt": "QA"}
  }'

# 共享 session，上下文连续
```

**优点：**
- ✅ 编码能力最强（Claude Code）
- ✅ 共享 session，上下文连续
- ✅ 多角色无缝切换
- ✅ 自动工具调用

**缺点：**
- ❌ 缺少记忆体系（Claude Code 没有持久化记忆）
- ❌ 知识库管理弱
- ❌ 每次都要重新加载上下文
- ❌ 不适合长期项目

---

### 方案 C：分层托管（推荐）⭐

**核心思想：规划角色在 OpenClaw，执行角色在 Claude Code**

```yaml
OpenClaw 层（规划 + 记忆）:
  - orchestrator: 编排器，负责任务分解和调度
  - product-manager: 产品经理，负责需求分析
  - architect: 架构师，负责技术设计

Claude Code 层（执行）:
  - developer: 开发者，负责编码实现
  - qa: QA工程师，负责测试验证

协作流程：
  orchestrator (OpenClaw)
      ↓ 任务分解
  product-manager (OpenClaw)
      ↓ 需求文档
  architect (OpenClaw)
      ↓ 技术设计
  claude-code-skill --agents team
      ↓ 启动 Claude Code 团队
  developer (Claude Code)
      ↓ 编码实现
  qa (Claude Code)
      ↓ 测试验证
```

**优点：**
- ✅ 各司其职（OpenClaw 擅长规划，Claude Code 擅长执行）
- ✅ 记忆 + 知识库（OpenClaw 层）
- ✅ 最强编码能力（Claude Code 层）
- ✅ 上下文连续（Claude Code 团队内部）

**缺点：**
- ⚠️ 两层架构，稍复杂
- ⚠️ 需要定义清晰的接口

---

## 2. 角色能力分析

| 角色 | 核心能力 | 需求 | 最佳托管 |
|------|---------|------|---------|
| **产品经理** | 需求分析、PRD 编写 | 记忆、知识库 | OpenClaw |
| **架构师** | 技术设计、API 设计 | 记忆、知识库 | OpenClaw |
| **开发者** | 编码实现 | 编码能力、工具调用 | Claude Code |
| **QA** | 测试、质量检查 | 编码能力、工具调用 | Claude Code |
| **Orchestrator** | 任务分解、调度 | 记忆、编排能力 | OpenClaw |

**关键洞察：**
- **规划角色**（产品、架构）需要记忆和知识库 → OpenClaw
- **执行角色**（开发、QA）需要编码和工具 → Claude Code

---

## 3. 决策矩阵

### 3.1 能力匹配度

| 能力 | OpenClaw | Claude Code |
|------|----------|-------------|
| **记忆体系** | ⭐⭐⭐⭐⭐ | ⭐ |
| **知识库** | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **编码能力** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **工具调用** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **多 Agent 协调** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **上下文连续性** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

### 3.2 角色适配度

| 角色 | OpenClaw | Claude Code | 推荐 |
|------|----------|-------------|------|
| Orchestrator | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | OpenClaw |
| Product Manager | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | OpenClaw |
| Architect | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | OpenClaw |
| Developer | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Claude Code |
| QA | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | Claude Code |

---

## 4. 推荐方案：分层托管

### 🎯 方案 C：规划在 OpenClaw，执行在 Claude Code

**架构图：**

```
┌─────────────────────────────────────────────────────────────┐
│              OpenClaw 层（规划 + 记忆）                       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Orchestrator │  │ Product Mgr  │  │ Architect    │      │
│  │              │  │              │  │              │      │
│  │ • 任务分解   │  │ • 需求分析   │  │ • 技术设计   │      │
│  │ • Agent调度  │  │ • PRD编写    │  │ • API设计    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Memory + Knowledge Base                             │  │
│  │  • MEMORY.md (长期记忆)                              │  │
│  │  • knowledge/ (知识库)                               │  │
│  │  • memory/ (日常记录)                                │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ claude-code-skill CLI
                     │ sessions_spawn({ runtime: "acp" })
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│            Claude Code 层（执行）                             │
│                                                              │
│  claude-code-skill session-start team \                     │
│    --agents '{                                              │
│      "dev": {"prompt": "开发者"},                           │
│      "qa": {"prompt": "QA工程师"}                           │
│    }'                                                       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐                        │
│  │ Developer    │  │ QA Engineer  │                        │
│  │              │  │              │                        │
│  │ • 编码实现   │  │ • 测试验证   │                        │
│  │ • 代码重构   │  │ • 质量检查   │                        │
│  └──────────────┘  └──────────────┘                        │
│                                                              │
│  共享 Session，上下文连续                                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. 工作流程示例

### 完整流程

```bash
# 1. Orchestrator (OpenClaw) 接收需求
架构师："实现用户登录功能"

# 2. Orchestrator 分解任务
memory_search("用户认证 登录")
读取 knowledge/domain/business-rules.md

# 3. Product Manager (OpenClaw) 分析需求
sessions_spawn({
  agentId: "product-manager",
  task: "分析用户登录需求，编写 PRD"
})

# 输出：docs/features/FEATURE-001/requirements.md

# 4. Architect (OpenClaw) 设计方案
sessions_spawn({
  agentId: "architect",
  task: "设计认证方案，编写技术设计文档"
})

# 输出：docs/features/FEATURE-001/tech-design.md

# 5. Orchestrator 调用 Claude Code 团队
claude-code-skill session-start feature-001 -d ~/project \
  --agents '{
    "dev": {"prompt": "开发者，根据 tech-design.md 实现"},
    "qa": {"prompt": "QA，编写测试"}
  }' \
  --permission-mode plan

# 6. Developer (Claude Code) 实现
claude-code-skill session-send feature-001 \
  "根据 docs/features/FEATURE-001/tech-design.md 实现登录 API" \
  --stream

# 7. QA (Claude Code) 测试
claude-code-skill session-send feature-001 \
  "@qa 编写测试用例并运行" \
  --stream

# 8. Orchestrator (OpenClaw) 质量检查
qa-gate skill 检查输出

# 9. 更新记忆
更新 memory/2026-03-04.md
更新 MEMORY.md（如有重要决策）
```

---

## 6. 配置示例

### OpenClaw 配置

**~/.openclaw/openclaw.json:**
```json5
{
  agents: {
    list: [
      {
        id: "orchestrator",
        name: "Orchestrator",
        default: true,
        workspace: "~/.openclaw/workspace",
        model: "anthropic/claude-opus-4-6"
      },
      {
        id: "product-manager",
        name: "Product Manager",
        workspace: "~/.openclaw/workspace-pm",
        model: "anthropic/claude-sonnet-4-5"
      },
      {
        id: "architect",
        name: "Architect",
        workspace: "~/.openclaw/workspace-arch",
        model: "anthropic/claude-opus-4-6"
      }
    ]
  }
}
```

**workspace/skills/dev-orchestrator/SKILL.md:**
```markdown
---
name: dev-orchestrator
description: AI研发流程编排器
---

# Dev Orchestrator

## 角色定义

- **Orchestrator** (我)：任务分解、Agent调度、质量把关
- **Product Manager** (OpenClaw)：需求分析、PRD编写
- **Architect** (OpenClaw)：技术设计、API设计
- **Developer** (Claude Code)：编码实现
- **QA** (Claude Code)：测试验证

## 工作流程

1. 接收架构师需求
2. 使用 memory_search 检索上下文
3. 调用 product-manager 分析需求
4. 调用 architect 设计方案
5. 使用 claude-code-skill 启动 Claude Code 团队
6. 质量检查（qa-gate）
7. 更新记忆
```

---

## 7. 优势总结

### 为什么分层托管最好？

| 维度 | 分层托管方案 | 全在 OpenClaw | 全在 Claude Code |
|------|------------|--------------|-----------------|
| **记忆能力** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ |
| **知识库** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **编码能力** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **上下文连续** | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **灵活性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

**核心理由：**
1. ✅ **各司其职**：规划角色用 OpenClaw，执行角色用 Claude Code
2. ✅ **最佳能力组合**：记忆 + 知识库（OpenClaw）+ 编码（Claude Code）
3. ✅ **清晰分层**：规划层 → 执行层
4. ✅ **可扩展**：每层可以独立扩展

**Gary 的核心洞察（2026-03-04 17:48）：**

**OpenClaw 优势：**
- ✅ **记忆管理**：MEMORY.md + memory_search
- ✅ **搜索更多外部信息**：web_search, web_fetch
- ⚠️ **执行能力不确定**：需要不断完善
- ✅ **可以不断完善**：持续优化

**Claude Code 优势：**
- ✅ **Agent 执行能力已经过实践证明很棒**

**结论：分层托管是最佳方案**
- OpenClaw：规划 + 记忆 + 外部信息
- Claude Code：执行 + 编码 + 测试

---

## 8. 最终决策

### 🎯 决策：采用分层托管方案

**角色分配：**

| 角色 | 托管平台 | 理由 |
|------|---------|------|
| Orchestrator | **OpenClaw** | 需要记忆、知识库、编排能力 |
| Product Manager | **OpenClaw** | 需要记忆、知识库、需求分析 |
| Architect | **OpenClaw** | 需要记忆、知识库、技术决策 |
| Developer | **Claude Code** | 需要最强编码能力 |
| QA Engineer | **Claude Code** | 需要编码、工具调用、测试能力 |

**架构：**
```
OpenClaw (规划层：记忆 + 知识 + 编排)
    ↓
Claude Code (执行层：编码 + 测试)
```

---

## 9. 实施建议

### 立即行动

1. **定义 OpenClaw Agents**
   - orchestrator
   - product-manager
   - architect

2. **编写 Skills**
   - dev-orchestrator（调用 claude-code-skill）
   - qa-gate
   - context-builder

3. **配置 Claude Code 团队**
   ```bash
   claude-code-skill session-start team \
     --agents '{
       "dev": {"prompt": "开发者"},
       "qa": {"prompt": "QA"}
     }'
   ```

4. **设计知识库**
   ```
   knowledge/
   ├── tech-stack.md
   ├── api-conventions.md
   └── domain/
   ```

---

**决策者：** Gary
**决策支持：** Claw
**决策日期：** 2026-03-04
