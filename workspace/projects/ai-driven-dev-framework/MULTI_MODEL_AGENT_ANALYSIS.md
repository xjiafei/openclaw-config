# 多模型 Agent 能力分析

> **核心问题：** 产品设计、技术设计需要多轮审核，非 Claude 模型没有 agent 加持，效果会不会没那么好？
> **提问者：** Gary
> **日期：** 2026-03-04 19:05

---

## 1. 问题分析

### Claude Code 的 Agent 机制

```
Claude Code Agent:
  ✅ 持久化 Session（上下文连续）
  ✅ 自动工具调用（Bash, Read, Write, etc.）
  ✅ 多轮对话（agent loop）
  ✅ 多角色协作（--agents）
  ✅ 规划能力（plan mode）
```

### 其他模型的限制

```
GPT / Gemini (原生):
  ❌ 通常是对话式，没有 agent loop
  ❌ 没有自动工具调用
  ❌ 上下文有限
  ❌ 没有多角色机制
```

---

## 2. claude-code-skill 的多模型支持

### 官方文档

```bash
# 使用 Gemini
claude-code-skill session-start gemini-task -d ~/project \
  --model gemini-2.0-flash \
  --base-url http://127.0.0.1:8082

# 使用 GPT-4o
claude-code-skill session-start gpt-task -d ~/project \
  --model gpt-4o \
  --base-url https://api.openai.com/v1
```

### 关键问题

**这些非 Claude 模型能否获得 agent 能力？**

---

## 3. Agent 能力来源分析

### Agent 能力来自哪里？

```
Agent 能力 = 模型能力 + 框架能力

Claude Code:
  模型能力：Claude 的推理、规划能力
  框架能力：MCP 协议、工具调用、Session 管理
  = 完整的 Agent 能力 ✅
```

### 使用其他模型时

```
claude-code-skill + --base-url:

框架能力：✅ 仍然有
  • MCP 协议
  • 工具调用
  • Session 管理
  • --agents 多角色

模型能力：⚠️ 取决于代理实现
  • 如果代理只是简单转发 → GPT/Gemini 原生能力
  • 如果代理做了适配 → 可能有部分 agent 能力
```

---

## 4. 三种多模型方案

### 方案 A：Claude Code 原生（推荐）

**所有角色都用 Claude：**

```bash
claude-code-skill session-start team \
  --agents '{
    "pm": {"prompt": "产品经理"},
    "architect": {"prompt": "架构师"},
    "developer": {"prompt": "开发者"},
    "reviewer1": {"prompt": "审核员1"},
    "reviewer2": {"prompt": "审核员2"}
  }' \
  --model claude-opus-4-5
```

**优点：**
- ✅ 完整的 agent 能力
- ✅ 工具调用流畅
- ✅ 多轮审核效果好

**缺点：**
- ❌ 成本较高（全部用 Claude）
- ⚠️ 依赖单一模型

---

### 方案 B：混合模型（通过代理）

**核心角色用 Claude，审核用其他模型：**

```bash
# 1. 核心团队用 Claude
claude-code-skill session-start team \
  --agents '{
    "pm": {"prompt": "产品经理"},
    "architect": {"prompt": "架构师"},
    "developer": {"prompt": "开发者"}
  }' \
  --model claude-opus-4-5

# 2. 审核用其他模型（需要代理）
# 问题：是否能保持 agent 能力？
```

**代理方案：**

```
claude-code-skill
    ↓
claude-code-proxy (适配层)
    ↓ 转换 Claude 协议 → GPT/Gemini API
GPT / Gemini
```

**优点：**
- ✅ 成本可控
- ✅ 模型多样性

**缺点：**
- ⚠️ Agent 能力可能受限
- ⚠️ 工具调用可能不流畅
- ⚠️ 多轮审核效果未知

---

### 方案 C：OpenClaw 多模型编排

**利用 OpenClaw 的多模型能力：**

```bash
# OpenClaw Orchestrator
sessions_spawn({
  agentId: "pm-claude",      # Claude 做需求分析
  task: "分析用户登录需求"
})

sessions_spawn({
  agentId: "architect-claude", # Claude 做技术设计
  task: "设计认证方案"
})

sessions_spawn({
  agentId: "reviewer-gpt",    # GPT 做审核
  model: "openai/gpt-4o",
  task: "审核技术方案"
})
```

**优点：**
- ✅ 灵活的多模型编排
- ✅ 可以用不同模型做不同事
- ✅ 有记忆和知识库支持

**缺点：**
- ⚠️ 跨 session 上下文不连续
- ⚠️ OpenClaw 的 agent 能力不如 Claude Code

---

## 5. 多轮审核的最佳实践

### 审核需要什么能力？

```
产品设计审核：
  • 理解业务背景
  • 识别需求漏洞
  • 提出改进建议
  • 多角度思考

技术设计审核：
  • 理解技术架构
  • 识别技术风险
  • 评估可行性
  • 提出优化方案
```

### 能力需求分析

| 能力 | Claude Code Agent | GPT/Gemini 原生 |
|------|------------------|----------------|
| **上下文理解** | ⭐⭐⭐⭐⭐（持久化） | ⭐⭐⭐（有限） |
| **工具调用** | ⭐⭐⭐⭐⭐（自动） | ⭐⭐（手动） |
| **多角度思考** | ⭐⭐⭐⭐⭐（多角色） | ⭐⭐⭐（单一） |
| **迭代改进** | ⭐⭐⭐⭐⭐（多轮） | ⭐⭐⭐（有限） |

**结论：Claude Code Agent 在多轮审核上优势明显。**

---

## 6. 实践建议

### 🎯 推荐方案：核心用 Claude，审核也用 Claude

**理由：**
1. ✅ 多轮审核需要完整的 agent 能力
2. ✅ 上下文连续性很重要
3. ✅ 工具调用流畅性很重要
4. ✅ 非 Claude 模型可能效果不佳

**成本优化：**
```bash
# 核心角色用 Opus（能力强）
--model claude-opus-4-5

# 审核角色用 Sonnet（性价比高）
--model claude-sonnet-4-5

# 简单任务用 Haiku（成本低）
--model claude-haiku-3-5
```

---

### 备选方案：如果一定要用多模型

**场景：成本敏感，需要多模型**

**方案：OpenClaw + claude-code-skill 混合**

```bash
# 1. 核心团队用 Claude Code（完整 agent 能力）
claude-code-skill session-start team \
  --agents '{
    "pm": {"prompt": "产品经理"},
    "architect": {"prompt": "架构师"},
    "developer": {"prompt": "开发者"}
  }' \
  --model claude-opus-4-5

# 2. 审核用 OpenClaw（可接入多模型）
sessions_spawn({
  agentId: "reviewer",
  model: "openai/gpt-4o",
  task: "审核产品设计文档"
})

# 缺点：上下文不连续，需要手动传递
```

---

## 7. 成本分析

### 纯 Claude 方案

```
假设一个功能：
- PM 分析：1M tokens × $15/M = $15
- Architect 设计：2M tokens × $15/M = $30
- Developer 编码：5M tokens × $15/M = $75
- Reviewer 审核：1M tokens × $15/M = $15
- QA 测试：2M tokens × $15/M = $30

总计：$165/功能

优化后（Sonnet/Haiku）：
- PM (Sonnet): 1M × $3/M = $3
- Architect (Sonnet): 2M × $3/M = $6
- Developer (Sonnet): 5M × $3/M = $15
- Reviewer (Sonnet): 1M × $3/M = $3
- QA (Sonnet): 2M × $3/M = $6

总计：$33/功能（节省 80%）
```

### 混合模型方案

```
Claude (核心) + GPT (审核):
- PM (Claude Sonnet): $3
- Architect (Claude Sonnet): $6
- Developer (Claude Sonnet): $15
- Reviewer (GPT-4o): 1M × $2.5/M = $2.5
- QA (Claude Sonnet): $6

总计：$32.5/功能
节省：$0.5（不值得）
```

**结论：混合模型节省有限，但损失 agent 能力。**

---

## 8. 最终建议

### 🎯 推荐方案：纯 Claude + 模型分级

**理由：**
1. ✅ 多轮审核需要完整 agent 能力
2. ✅ 非模型节省有限（$0.5/功能）
3. ✅ 损失 agent 能力得不偿失

**实施方案：**

```bash
# 核心角色用 Opus（关键决策）
"architect": {
  "prompt": "架构师",
  "model": "claude-opus-4-5"
}

# 大部分角色用 Sonnet（性价比高）
"pm": {
  "prompt": "产品经理",
  "model": "claude-sonnet-4-5"
}
"developer": {
  "prompt": "开发者",
  "model": "claude-sonnet-4-5"
}
"reviewer": {
  "prompt": "审核员",
  "model": "claude-sonnet-4-5"
}

# 简单任务用 Haiku（成本低）
"qa": {
  "prompt": "QA",
  "model": "claude-haiku-3-5"
}
```

**预期成本：**
- Opus: $15/M tokens
- Sonnet: $3/M tokens
- Haiku: $0.25/M tokens

**优化后：$30-50/功能（vs $165/功能）**

---

## 9. 总结

### 核心结论

**Gary 的担忧是对的：**
- ✅ 非模型确实没有 agent 加持
- ✅ 多轮审核效果可能不如 Claude
- ✅ 工具调用、上下文连续性都很重要

**最佳实践：**
- ✅ 核心业务用 Claude（完整 agent 能力）
- ✅ 通过模型分级控制成本（Opus/Sonnet/Haiku）
- ⚠️ 不推荐混合模型（损失大，节省小）

---

**决策者：** Gary
**分析者：** Claw
**日期：** 2026-03-04

**关键洞察：** 多轮审核需要完整 agent 能力，Claude Code 是最佳选择。
