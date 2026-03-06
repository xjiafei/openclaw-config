# AI 全流程研发框架：技术决策报告

> **决策者：** Gary
> **决策日期：** 2026-03-04
> **决策背景：** AI全流程研发框架涉及产品经理、架构师等多个角色协作

---

## 1. 决策背景

### 1.1 核心需求

AI全流程研发框架需要：
- **多角色协作**：产品经理、架构师、开发者、QA等
- **流程自动化**：需求→设计→开发→测试→部署
- **质量保障**：QA Gate、迭代优化
- **知识管理**：上下文、知识库、记忆

### 1.2 可用技术

| 技术 | 能力 | 定位 |
|------|------|------|
| **OpenClaw** | 多Agent、记忆、IM、Skills | 编排层 |
| **Claude Code** | 强大的编码能力 | 执行层 |
| **claude-code-skill** | OpenClaw→Claude Code 桥梁 | 集成层 |
| **OpenGoat** | 组织框架、UI、任务管理 | 平台层 |

---

## 2. 决策选项

### 选项 A：纯 OpenClaw + Skills（零代码）

**架构：**
```
OpenClaw (Orchestrator)
    ├── Skills (提示词)
    │   ├── dev-orchestrator
    │   ├── qa-gate
    │   └── context-builder
    ├── Memory (MEMORY.md)
    ├── Knowledge (knowledge/)
    └── Sessions (sessions_spawn)
```

**多角色实现：**
```yaml
agents:
  - id: orchestrator
    role: 编排器
    type: manager
    
  - id: product-manager
    role: 产品经理
    skills: [requirements-analysis, prd-writing]
    
  - id: architect
    role: 架构师
    skills: [tech-design, api-design]
    
  - id: developer
    role: 开发者
    type: individual
    # 使用 OpenClaw 内置编码能力
    
  - id: qa
    role: QA工程师
    skills: [qa-gate, test-writing]
```

**优点：**
- ✅ 完全零代码（纯 Skills + AGENTS.md）
- ✅ 学习成本低（只用 OpenClaw）
- ✅ 灵活度高（完全自主）
- ✅ 记忆体系完善

**缺点：**
- ❌ 编码能力不如 Claude Code
- ❌ 多 Agent 编排需要手动管理
- ❌ 没有 UI（用飞书代替）

**工作量：** 5-8 天

---

### 选项 B：OpenClaw + claude-code-skill（推荐）

**架构：**
```
OpenClaw (Orchestrator)
    ├── Skills
    │   ├── dev-orchestrator      # 调用 claude-code-skill
    │   ├── qa-gate
    │   ├── context-builder
    │   └── claude-code-skill     # ✅ 直接用
    ├── Memory
    ├── Knowledge
    └── Sessions
         ↓
    claude-code-skill CLI
         ↓
    backend-api → MCP → Claude Code
```

**多角色实现：**
```yaml
# OpenClaw Agents (编排层)
orchestrator:
  role: 编排器
  type: manager
  responsibility: 分解任务、调度Agent、质量把关

# Claude Code Agents (执行层，通过 claude-code-skill)
claude-code-skill session-start team \
  --agents '{
    "product-manager": {
      "prompt": "产品经理，负责需求分析和PRD编写"
    },
    "architect": {
      "prompt": "架构师，负责技术设计和API设计"
    },
    "developer": {
      "prompt": "开发者，负责编码实现"
    },
    "qa": {
      "prompt": "QA工程师，负责测试和质量检查"
    }
  }'
```

**优点：**
- ✅ 最佳编码能力（Claude Code）
- ✅ 持久化 Session（上下文连续）
- ✅ 多 Agent 团队（--agents）
- ✅ 工具控制（安全限制）
- ✅ 成熟的集成方案

**缺点：**
- ❌ 需要运行 backend-api
- ❌ 依赖外部项目
- ❌ 稍复杂（两层架构）

**工作量：** 4-7 天

---

### 选项 C：OpenGoat + 自定义 Skills

**架构：**
```
OpenGoat (平台)
    ├── goat (CEO)
    │   ├── orchestrator (Manager)
    │   │   ├── product-manager (Individual)
    │   │   ├── architect (Individual)
    │   │   ├── developer (Individual)
    │   │   └── qa (Individual)
    ├── Web UI
    ├── Task Management
    └── Custom Skills
        ├── dev-orchestrator
        ├── qa-gate
        └── claude-code-skill
```

**多角色实现：**
```bash
# OpenGoat 原生组织
opengoat agent create "Orchestrator" --manager --reports-to goat
opengoat agent create "Product-Manager" --individual --reports-to orchestrator
opengoat agent create "Architect" --individual --reports-to orchestrator
opengoat agent create "Developer" --individual --reports-to orchestrator --skill coding
opengoat agent create "QA" --individual --reports-to orchestrator

# 分配任务
opengoat task create \
  --title "实现用户登录" \
  --owner orchestrator \
  --assign developer
```

**优点：**
- ✅ 完整的组织模型
- ✅ Web UI 可视化
- ✅ 任务管理系统
- ✅ 多 Provider 支持

**缺点：**
- ❌ 80% 功能用不上（UI、任务管理）
- ❌ 学习成本高
- ❌ 依赖重
- ❌ 定制受限

**工作量：** 11-17 天

---

## 3. 多角色协作对比

### 3.1 角色定义方式

| 方案 | 角色定义 | 灵活度 |
|------|---------|--------|
| **A. OpenClaw** | Skills + AGENTS.md | ⭐⭐⭐⭐⭐ |
| **B. OpenClaw + claude-code-skill** | Skills + --agents | ⭐⭐⭐⭐⭐ |
| **C. OpenGoat** | agent create | ⭐⭐⭐ |

### 3.2 角色协作方式

#### 选项 A：OpenClaw 原生

```bash
# Orchestrator 调度
sessions_spawn({
  agentId: "product-manager",
  task: "分析用户登录需求"
})

sessions_spawn({
  agentId: "architect",
  task: "设计认证方案"
})

sessions_spawn({
  agentId: "developer",
  task: "实现登录API"
})
```

**特点：** 每个 Agent 独立 Session，需要手动传递上下文。

#### 选项 B：OpenClaw + claude-code-skill

```bash
# 启动团队 Session
claude-code-skill session-start team -d ~/project \
  --agents '{
    "pm": {"prompt": "产品经理"},
    "arch": {"prompt": "架构师"},
    "dev": {"prompt": "开发者"},
    "qa": {"prompt": "QA"}
  }'

# 在同一 Session 中协作（共享上下文）
claude-code-skill session-send team "分析用户登录需求"
claude-code-skill session-send team "@arch 设计认证方案"
claude-code-skill session-send team "@dev 实现登录API"
claude-code-skill session-send team "@qa 测试功能"
```

**特点：** 共享 Session 上下文，无缝协作。

#### 选项 C：OpenGoat

```bash
# 层级分配
opengoat agent orchestrator --message "实现用户登录"
# orchestrator 自动分配给 product-manager、architect、developer
```

**特点：** 自动路由，但缺少上下文共享。

### 3.3 上下文管理

| 方案 | 上下文管理 | 评分 |
|------|-----------|------|
| **A. OpenClaw** | Memory + 手动传递 | ⭐⭐⭐ |
| **B. OpenClaw + claude-code-skill** | 共享 Session | ⭐⭐⭐⭐⭐ |
| **C. OpenGoat** | 独立 Session | ⭐⭐ |

---

## 4. 决策矩阵

### 4.1 核心维度评分

| 维度 | A. OpenClaw | B. OpenClaw + claude-code-skill | C. OpenGoat |
|------|------------|--------------------------------|------------|
| **编码能力** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **多角色协作** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **上下文管理** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **质量保障** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **易用性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **灵活性** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **工作量** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **维护成本** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

### 4.2 需求匹配度

| 需求 | A. OpenClaw | B. OpenClaw + claude-code-skill | C. OpenGoat |
|------|------------|--------------------------------|------------|
| 多角色协作 | ✅ 80% | ✅ 100% | ✅ 90% |
| 编码能力 | ⚠️ 60% | ✅ 100% | ✅ 80% |
| 上下文连续 | ⚠️ 70% | ✅ 100% | ⚠️ 60% |
| 质量保障 | ✅ 100% | ✅ 100% | ⚠️ 70% |
| 知识管理 | ✅ 100% | ✅ 100% | ✅ 90% |

---

## 5. 推荐方案

### 🎯 推荐：选项 B（OpenClaw + claude-code-skill）

**核心理由：**

#### 1. 最佳的多角色协作

```bash
# 产品经理、架构师、开发者、QA 在同一 Session
claude-code-skill session-start team \
  --agents '{
    "pm": {"prompt": "产品经理，负责需求"},
    "arch": {"prompt": "架构师，负责设计"},
    "dev": {"prompt": "开发者，负责编码"},
    "qa": {"prompt": "QA，负责测试"}
  }'

# 共享上下文，无缝切换
claude-code-skill session-send team "分析需求"     # pm 回应
claude-code-skill session-send team "@arch 设计"  # arch 回应
claude-code-skill session-send team "@dev 实现"   # dev 回应
claude-code-skill session-send team "@qa 测试"    # qa 回应
```

#### 2. 最强的编码能力

- Claude Code 是目前最强的编码 AI
- 持久化 Session 保持上下文
- 自动调用工具（Bash, Read, Write, etc.）

#### 3. 完善的质量保障

```bash
# Plan 模式（预览变更）
--permission-mode plan

# 工具限制（安全）
--allowed-tools "Bash(git:*),Read,Edit,Write"

# 预算控制
--max-budget 2.00
```

#### 4. 最少的工作量

- claude-code-skill：0 天（直接用）
- dev-orchestrator：1-2 天
- qa-gate：1-2 天
- context-builder：1 天
- **总计：4-7 天**

---

## 6. 实施路径

### Phase 1：安装和配置（1 天）

```bash
# 1. 安装 claude-code-skill
cd ~/.openclaw/workspace/skills
git clone https://github.com/Enderfga/openclaw-claude-code-skill.git
cd openclaw-claude-code-skill
npm install && npm run build

# 2. 启动 backend-api（需要运行在 :18795）
# (参考项目文档)

# 3. 测试
claude-code-skill session-start test -d ~/test-project
claude-code-skill session-send test "测试连接" --stream
```

### Phase 2：编写自定义 Skills（3-4 天）

**dev-orchestrator/SKILL.md：**
```markdown
---
name: dev-orchestrator
description: AI研发流程编排器，协调产品、架构、开发、QA
---

# Dev Orchestrator

## 工作流程

1. 接收架构师的需求描述
2. 构建上下文（memory_search + knowledge）
3. 启动 Claude Code 团队 Session
4. 分解任务给不同角色
5. 质量检查（qa-gate）
6. 迭代优化

## 调用 Claude Code

```bash
# 启动团队
claude-code-skill session-start feature-001 -d ~/project \
  --agents '{
    "pm": {"prompt": "产品经理"},
    "arch": {"prompt": "架构师"},
    "dev": {"prompt": "开发者"},
    "qa": {"prompt": "QA"}
  }' \
  --permission-mode plan

# 发送任务
claude-code-skill session-send feature-001 "实现用户登录" --stream
```
```

**qa-gate/SKILL.md：**
```markdown
---
name: qa-gate
description: 质量检查门，验证输出质量
---

# QA Gate

## 检查维度

- 功能完整性
- 代码质量
- 测试覆盖率
- 文档完整性

## 评分标准

- 80分通过
- 低于80分 → 迭代优化
```

### Phase 3：设计知识库（1 天）

```
knowledge/
├── tech-stack.md          # 技术栈
├── api-conventions.md     # API规范
├── best-practices.md      # 最佳实践
└── domain/
    └── business-rules.md  # 业务规则
```

### Phase 4：测试和优化（1-2 天）

端到端测试一个完整功能。

---

## 7. 风险评估

### 选项 B 的风险

| 风险 | 影响 | 缓解 |
|------|------|------|
| backend-api 依赖 | 🟡 中 | 容器化部署 |
| claude-code-skill 停止维护 | 🟡 中 | Fork 项目 |
| 学习曲线 | 🟢 低 | 文档完善 |

---

## 8. 最终决策

### 决策建议

**🎯 采用选项 B：OpenClaw + claude-code-skill**

**理由：**
1. ✅ 最佳的多角色协作（共享 Session）
2. ✅ 最强的编码能力（Claude Code）
3. ✅ 最少的工作量（4-7 天）
4. ✅ 完善的质量保障（Plan 模式 + QA Gate）
5. ✅ 成熟的集成方案（claude-code-skill）

**不选其他方案的原因：**
- ❌ 选项 A：编码能力不足，上下文管理弱
- ❌ 选项 C：80% 功能用不上，工作量太大

---

## 9. 后续行动

### 立即行动（本周）

1. **安装 claude-code-skill**（今天）
2. **编写 dev-orchestrator**（明天）
3. **编写 qa-gate**（后天）

### 短期行动（下周）

4. **设计知识库**
5. **端到端测试**

### 长期优化（持续）

6. **迭代优化 Skills**
7. **积累知识库**
8. **考虑贡献回社区**

---

## 10. 总结

| 维度 | 评分 |
|------|------|
| **决策质量** | ⭐⭐⭐⭐⭐ |
| **风险可控性** | ⭐⭐⭐⭐ |
| **工作量** | ⭐⭐⭐⭐⭐ |
| **长期价值** | ⭐⭐⭐⭐⭐ |

**决策：采用 OpenClaw + claude-code-skill 方案**

---

**决策者：** Gary
**决策日期：** 2026-03-04
**决策支持：** Claw
