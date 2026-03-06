# 重新思考：所有角色都在 Claude Code？

> **关键洞察（Gary）：**
> 1. PM 和 Architect 如果脱离代码库，很难做出很棒的工作
> 2. Claude Code 的 agent 也具备规划、搜索、分析的能力
>
> **决策日期：** 2026-03-04 17:52

---

## 1. 问题重新定义

### 之前的方案有问题

**分层托管的缺陷：**
```
OpenClaw 层：
  PM (产品经理) → 分析需求
  Architect (架构师) → 设计方案

问题：
❌ PM 和 Architect 脱离代码库
❌ 无法看到现有代码，难以做出好的决策
❌ 需求分析和设计可能与实际代码脱节
```

**Claude Code 的能力被低估：**
```
✅ 编码能力（已验证）
✅ 规划能力（具备）
✅ 搜索能力（WebFetch, WebSearch）
✅ 分析能力（具备）
✅ 直接访问代码库 ✅✅✅
```

---

## 2. 新的方案对比

### 方案 A：分层托管（之前的方案）

```
OpenClaw:
  Orchestrator (编排)
  Product Manager (需求分析)
  Architect (技术设计)
    ↓
Claude Code:
  Developer (编码)
  QA (测试)
```

**问题：**
- ❌ PM 和 Architect 脱离代码库
- ❌ 无法看到现有实现
- ❌ 设计可能与代码脱节

---

### 方案 B：所有角色都在 Claude Code ⭐ NEW

```bash
claude-code-skill session-start project-team \
  --agents '{
    "pm": {
      "description": "产品经理",
      "prompt": "负责需求分析、PRD编写。可以访问代码库理解现有实现。"
    },
    "architect": {
      "description": "架构师",
      "prompt": "负责技术设计、API设计。可以访问代码库理解现有架构。"
    },
    "developer": {
      "description": "开发者",
      "prompt": "负责编码实现。"
    },
    "qa": {
      "description": "QA工程师",
      "prompt": "负责测试验证。"
    }
  }'
```

**优势：**
- ✅ 所有角色都能访问代码库
- ✅ 共享 Session，上下文连续
- ✅ PM 和 Architect 能看到现有实现
- ✅ 设计基于实际代码

**问题：**
- ❌ 没有持久化记忆（Session 结束就忘了）
- ❌ 没有知识库管理
- ❌ 每次都要重新加载上下文

---

### 方案 C：OpenClaw 编排 + Claude Code 团队 ⭐⭐⭐ 推荐

```
OpenClaw (编排 + 记忆 + 知识库):
  Orchestrator
    ↓ 负责任务分解、上下文准备、质量检查
    ↓ 提供记忆和知识库支持
    ↓
Claude Code (完整团队):
  --agents '{
    "pm": "产品经理",
    "architect": "架构师",
    "developer": "开发者",
    "qa": "QA"
  }'
```

**工作流程：**

```bash
# 1. OpenClaw Orchestrator 接收需求
架构师："实现用户登录功能"

# 2. OpenClaw 准备上下文
memory_search("用户认证 登录")
读取 knowledge/domain/business-rules.md
读取 knowledge/tech-stack.md

# 3. OpenClaw 启动 Claude Code 团队
claude-code-skill session-start feature-001 -d ~/project \
  --agents '{
    "pm": {
      "prompt": "产品经理。项目背景：[从OpenClaw注入]。可以访问代码库理解现有实现。"
    },
    "architect": {
      "prompt": "架构师。技术栈：[从OpenClaw注入]。可以访问代码库理解现有架构。"
    },
    "developer": {
      "prompt": "开发者。"
    },
    "qa": {
      "prompt": "QA工程师。"
    }
  }' \
  --append-system-prompt "业务背景：[从OpenClaw注入]"

# 4. Claude Code 团队协作（共享 Session）
claude-code-skill session-send feature-001 "分析用户登录需求" --stream
# PM 分析（能访问代码库）

claude-code-skill session-send feature-001 "@architect 设计认证方案" --stream
# Architect 设计（能看到现有代码）

claude-code-skill session-send feature-001 "@developer 实现登录API" --stream
# Developer 编码

claude-code-skill session-send feature-001 "@qa 测试功能" --stream
# QA 测试

# 5. OpenClaw 质量检查 + 更新记忆
qa-gate skill
更新 memory/2026-03-04.md
更新 MEMORY.md
```

**优势：**
- ✅ 所有角色都能访问代码库（Claude Code）
- ✅ 共享 Session，上下文连续（Claude Code）
- ✅ 有持久化记忆（OpenClaw）
- ✅ 有知识库管理（OpenClaw）
- ✅ PM 和 Architect 能看到现有实现

**这是最佳方案！**

---

## 3. 方案对比

| 维度 | A. 分层托管 | B. 全在 Claude Code | C. OpenClaw + Claude 团队 ⭐ |
|------|-----------|-------------------|---------------------------|
| **访问代码库** | ⚠️ PM/Arch 不能 | ✅ 所有角色都能 | ✅ 所有角色都能 |
| **上下文连续** | ⚠️ 两层隔离 | ✅ 共享 Session | ✅ 共享 Session |
| **持久化记忆** | ✅ OpenClaw | ❌ 无 | ✅ OpenClaw |
| **知识库** | ✅ OpenClaw | ❌ 无 | ✅ OpenClaw |
| **执行能力** | ⚠️ OpenClaw 弱 | ✅ 强 | ✅ 强 |
| **质量保障** | ⚠️ 跨层困难 | ⚠️ 无记忆 | ✅ OpenClaw 把关 |

---

## 4. 推荐方案：C - OpenClaw 编排 + Claude Code 团队

### 架构图

```
┌─────────────────────────────────────────────────────────────┐
│              OpenClaw Orchestrator                           │
│                                                              │
│  职责：                                                      │
│  • 接收架构师需求                                            │
│  • 准备上下文（memory_search + knowledge）                  │
│  • 启动 Claude Code 团队                                    │
│  • 质量检查（qa-gate）                                       │
│  • 更新记忆（MEMORY.md）                                     │
│                                                              │
│  提供：                                                      │
│  • 持久化记忆                                                │
│  • 知识库管理                                                │
│  • 外部信息搜索                                              │
└────────────┬────────────────────────────────────────────────┘
             │
             │ claude-code-skill session-start \
             │   --agents '{pm, architect, developer, qa}' \
             │   --append-system-prompt "业务背景..."
             │
             ▼
┌─────────────────────────────────────────────────────────────┐
│            Claude Code Team (所有角色)                       │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ PM           │  │ Architect    │  │ Developer    │      │
│  │              │  │              │  │              │      │
│  │ • 需求分析   │  │ • 技术设计   │  │ • 编码实现   │      │
│  │ • 访问代码库 │  │ • 访问代码库 │  │ • 访问代码库 │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌──────────────┐                                          │
│  │ QA           │                                          │
│  │              │                                          │
│  │ • 测试验证   │                                          │
│  └──────────────┘                                          │
│                                                              │
│  特点：                                                      │
│  • 所有角色都能访问代码库 ✅                                 │
│  • 共享 Session，上下文连续 ✅                               │
│  • 能看到现有实现，设计更准确 ✅                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. 实施细节

### OpenClaw Orchestrator Skill

```markdown
---
name: dev-orchestrator
description: AI研发流程编排器
---

# Dev Orchestrator

## 角色定位

- **我（Orchestrator）**：任务分解、上下文准备、质量检查、记忆管理
- **Claude Code 团队**：PM、Architect、Developer、QA（所有角色）

## 工作流程

### 1. 接收需求
从架构师处接收业务需求。

### 2. 准备上下文
```bash
memory_search("相关关键词")
read knowledge/tech-stack.md
read knowledge/api-conventions.md
```

### 3. 启动 Claude Code 团队
```bash
claude-code-skill session-start feature-001 -d ~/project \
  --agents '{
    "pm": {
      "prompt": "产品经理。负责需求分析和PRD编写。可以访问代码库理解现有实现。"
    },
    "architect": {
      "prompt": "架构师。负责技术设计和API设计。可以访问代码库理解现有架构。"
    },
    "developer": {
      "prompt": "开发者。负责编码实现。"
    },
    "qa": {
      "prompt": "QA工程师。负责测试验证和质量检查。"
    }
  }' \
  --append-system-prompt "
    业务背景：${业务背景}
    技术栈：${tech-stack}
    API规范：${api-conventions}
  " \
  --permission-mode plan \
  --max-budget 5.00
```

### 4. 发送任务
```bash
# PM 分析需求（能看到现有代码）
claude-code-skill session-send feature-001 "分析用户登录需求，考虑现有实现" --stream

# Architect 设计方案（能看到现有架构）
claude-code-skill session-send feature-001 "@architect 基于现有代码设计认证方案" --stream

# Developer 实现
claude-code-skill session-send feature-001 "@developer 实现登录API" --stream

# QA 测试
claude-code-skill session-send feature-001 "@qa 编写测试并验证" --stream
```

### 5. 质量检查
```bash
# 使用 qa-gate skill 检查输出
# 如果不通过，注入反馈，重新发送任务
```

### 6. 更新记忆
```bash
# 更新日常记忆
write memory/2026-03-04.md

# 如果有重要决策，更新长期记忆
edit MEMORY.md
```
```

---

## 6. 关键优势

### 为什么这个方案最好？

**1. PM 和 Architect 能访问代码库** ✅
```
之前：OpenClaw PM → 无法访问代码 → 设计脱离实际
现在：Claude Code PM → 能访问代码 → 基于现有实现设计
```

**2. 所有角色共享上下文** ✅
```
之前：OpenClaw PM → OpenClaw Architect → 上下文不连续
现在：Claude Code Team → 共享 Session → 上下文连续
```

**3. 有持久化记忆** ✅
```
之前：Claude Code Session → 结束就忘了
现在：OpenClaw Orchestrator → 记录到 MEMORY.md → 下次能用
```

**4. 有知识库支持** ✅
```
OpenClaw 提供：
- knowledge/tech-stack.md
- knowledge/api-conventions.md
- knowledge/best-practices.md
```

---

## 7. 最终决策

### 🎯 决策：OpenClaw 编排 + Claude Code 团队

**角色分配：**

| 角色 | 平台 | 理由 |
|------|------|------|
| **Orchestrator** | OpenClaw | 记忆、知识库、编排 |
| **PM** | **Claude Code** | 能访问代码库 ✅ |
| **Architect** | **Claude Code** | 能访问代码库 ✅ |
| **Developer** | **Claude Code** | 执行能力强 ✅ |
| **QA** | **Claude Code** | 执行能力强 ✅ |

**关键改变：**
- ❌ 之前：PM 和 Architect 在 OpenClaw（脱离代码库）
- ✅ 现在：PM 和 Architect 在 Claude Code（能访问代码库）

**OpenClaw 的角色：**
- ✅ 编排器（Orchestrator）
- ✅ 记忆管理者
- ✅ 知识库提供者
- ✅ 质量把关者

**Claude Code 的角色：**
- ✅ 完整的研发团队（PM + Architect + Developer + QA）
- ✅ 所有角色都能访问代码库
- ✅ 共享 Session，上下文连续

---

**决策者：** Gary
**决策支持：** Claw
**决策日期：** 2026-03-04

**关键洞察：** PM 和 Architect 需要访问代码库才能做出好的工作！
