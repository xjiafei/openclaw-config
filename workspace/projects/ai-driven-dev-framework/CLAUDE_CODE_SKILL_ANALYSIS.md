# openclaw-claude-code-skill 项目分析报告

> **项目地址：** https://github.com/Enderfga/openclaw-claude-code-skill
> **分析日期：** 2026-03-04
> **重要程度：** ⭐⭐⭐⭐⭐ **与 Gary 项目高度相关！**

---

## 1. 项目用途

### 1.1 核心定位

**这是一个 OpenClaw Skill，用于通过 MCP 协议控制 Claude Code。**

简单来说：**这是 OpenClaw 调用 Claude Code 的桥梁！**

```
OpenClaw Agent
    ↓
claude-code-skill (CLI)
    ↓ HTTP
backend-api (API 服务器)
    ↓ MCP 协议
Claude Code (claude mcp serve)
    ↓
文件 & 工具
```

### 1.2 为什么重要？

这正好解决了 Gary 项目的核心需求：

| Gary 的需求 | claude-code-skill 提供的能力 |
|------------|----------------------------|
| OpenClaw 调用 Claude Code | ✅ 完整的 CLI 接口 |
| 持久化 Session | ✅ session-start/session-send |
| Agent 团队 | ✅ --agents 参数 |
| 工具控制 | ✅ --allowed-tools |
| 质量控制 | ✅ --permission-mode |
| 多模型支持 | ✅ --base-url 代理 |

---

## 2. 核心功能

### 2.1 持久化 Session

**问题：** Claude Code 每次调用都是独立的，无法保持上下文。

**解决：** session-start 创建持久化 session。

```bash
# 启动 session
claude-code-skill session-start myproject -d ~/project \
  --permission-mode plan \
  --allowed-tools "Bash,Read,Edit,Write"

# 发送任务（保持上下文）
claude-code-skill session-send myproject "实现用户登录功能" --stream

# 检查状态
claude-code-skill session-status myproject

# 停止
claude-code-skill session-stop myproject
```

**关键特性：**
- ✅ 多轮对话保持上下文
- ✅ 自动保存历史记录
- ✅ 可以暂停/恢复
- ✅ 可以 fork（创建分支）

### 2.2 Agent 团队

**问题：** 复杂任务需要不同角色的 Agent。

**解决：** --agents 定义多个 Agent。

```bash
# 定义团队
claude-code-skill session-start team -d ~/project \
  --agents '{
    "architect": {
      "description": "设计系统架构",
      "prompt": "你是资深架构师，设计可扩展的系统"
    },
    "developer": {
      "description": "实现功能",
      "prompt": "你是全栈开发者，编写干净的代码"
    },
    "reviewer": {
      "description": "审查代码",
      "prompt": "你是代码审查员，检查 bug 和改进点"
    }
  }' \
  --agent architect

# 切换 Agent
claude-code-skill session-send team "设计认证系统"
claude-code-skill session-send team "@developer 实现这个设计"
claude-code-skill session-send team "@reviewer 审查实现"
```

**适用场景：**
- 架构师 → 开发者 → 审查员（标准流程）
- 安全专家 + 性能专家 + 质量专家（多维审查）
- 前端 + 后端 + 数据库（全栈团队）

### 2.3 工具控制

**问题：** 需要限制 Agent 能做什么。

**解决：** --allowed-tools 和 --disallowed-tools。

```bash
# 只允许特定工具
--allowed-tools "Bash(git:*),Read,Glob,Grep"

# 禁止危险操作
--disallowed-tools "Bash(rm:*,sudo:*),Write(/etc/*)"

# 限制工具集
--tools "Read,Glob,Grep"
```

**模式：**
| 模式 | 说明 |
|------|------|
| `acceptEdits` | 自动接受文件编辑（默认） |
| `plan` | 预览变更再应用 |
| `default` | 每次操作都询问 |
| `bypassPermissions` | 跳过所有提示（危险！） |

### 2.4 多模型支持（代理）

**问题：** 想用 Gemini/GPT 等其他模型。

**解决：** --base-url 路由到代理。

```bash
# 使用 Gemini
claude-code-skill session-start gemini-task -d ~/project \
  --base-url http://127.0.0.1:8082 \
  --model gemini-2.0-flash

# 使用 GPT-4o
claude-code-skill session-start gpt-task -d ~/project \
  --model gpt-4o \
  --base-url https://api.openai.com/v1
```

**原理：**
```
Claude Code Client
    ↓
claude-code-proxy（代理服务器）
    ↓ 转换
Gemini / GPT / OpenRouter
```

---

## 3. 实现原理

### 3.1 架构设计

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenClaw Agent                            │
│  （调用 claude-code-skill CLI）                              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              claude-code-skill CLI (TypeScript)              │
│  • 解析命令行参数                                            │
│  • 管理 session                                             │
│  • 调用 backend-api                                         │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              backend-api (API Server :18795)                 │
│  • 管理 Claude Code session                                 │
│  • 提供 REST API                                            │
│  • 持久化 session 状态                                      │
└────────────────────┬────────────────────────────────────────┘
                     │ MCP 协议
                     ▼
┌─────────────────────────────────────────────────────────────┐
│           Claude Code (claude mcp serve)                     │
│  • 执行 agent loop                                          │
│  • 调用工具（Bash, Read, Write, etc.）                      │
│  • 管理对话历史                                             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                    文件系统 & 工具                           │
│  • 读写文件                                                 │
│  • 执行命令                                                 │
│  • Git 操作                                                 │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 技术栈

**项目结构：**
```
openclaw-claude-code-skill/
├── SKILL.md              # OpenClaw Skill 定义（12KB）
├── package.json          # Node.js 依赖
├── src/
│   ├── index.ts          # CLI 主入口（24KB）
│   ├── mcp/              # MCP 协议实现
│   └── store/            # Session 存储
├── examples/             # 示例
└── mcp_config.example.json  # MCP 配置示例
```

**依赖：**
- Node.js 18+
- TypeScript
- MCP SDK（Model Context Protocol）
- backend-api 服务器（需单独运行）

### 3.3 关键机制

#### 3.3.1 Session 管理

```typescript
// 伪代码
session-start:
  1. 创建 session ID
  2. 连接到 backend-api
  3. 启动 Claude Code MCP server
  4. 注册工具和权限
  5. 返回 session ID

session-send:
  1. 根据 session ID 找到 session
  2. 发送消息到 backend-api
  3. backend-api 转发到 Claude Code
  4. Claude Code 执行 agent loop
  5. 流式返回结果
```

#### 3.3.2 MCP 协议

**MCP (Model Context Protocol)** 是 Anthropic 定义的协议，用于连接 AI 模型和工具。

```typescript
// MCP 消息格式
{
  "jsonrpc": "2.0",
  "method": "tools/call",
  "params": {
    "name": "Bash",
    "arguments": {
      "command": "npm test"
    }
  }
}
```

**可用工具：**
| 工具 | 说明 |
|------|------|
| Bash | 执行 shell 命令 |
| Read | 读文件 |
| Write | 写文件 |
| Edit | 编辑文件 |
| Glob | 查找文件 |
| Grep | 搜索内容 |
| Task | 启动子 agent |
| WebFetch | 抓取网页 |
| WebSearch | 搜索网页 |
| Git* | Git 操作 |
| ... | 10+ 更多 |

---

## 4. 与 Gary 项目的关系

### 4.1 完美匹配度 ⭐⭐⭐⭐⭐

| Gary 的需求 | claude-code-skill | 匹配度 |
|------------|------------------|--------|
| OpenClaw 调用 Claude Code | ✅ 专为这个设计 | 100% |
| 持久化 Session | ✅ session-start | 100% |
| 多 Agent 协作 | ✅ --agents | 100% |
| 质量控制 | ✅ --permission-mode plan | 90% |
| 工具限制 | ✅ --allowed-tools | 100% |
| QA Gate | ❌ 需自己实现 | 0% |
| 知识库 | ❌ 需自己实现 | 0% |

### 4.2 如何集成到 Gary 项目

**方案：直接使用这个 Skill**

```bash
# 1. 安装
cd ~/.openclaw/workspace/skills
git clone https://github.com/Enderfga/openclaw-claude-code-skill.git

# 2. 安装依赖
cd openclaw-claude-code-skill
npm install
npm run build

# 3. 启动 backend-api
# (需要运行 backend-api 服务器在 :18795)

# 4. 在 OpenClaw Agent 中使用
```

**在 dev-orchestrator SKILL.md 中调用：**

```markdown
# Dev Orchestrator

## 调用 Claude Code

当需要执行编码任务时，使用 claude-code-skill：

```bash
# 启动 session
claude-code-skill session-start feature-001 -d ~/project \
  --permission-mode plan \
  --allowed-tools "Bash(npm:*,git:*),Read,Edit,Write" \
  --max-budget 2.00

# 发送任务
claude-code-skill session-send feature-001 "实现用户登录 API" --stream

# 检查状态
claude-code-skill session-status feature-001

# 停止
claude-code-skill session-stop feature-001
```
```

### 4.3 缺失部分

claude-code-skill 没有的，需要自己补充：

| 缺失功能 | Gary 需要实现 |
|---------|--------------|
| QA Gate | 编写 qa-gate SKILL.md |
| 知识库管理 | 设计 knowledge/ 目录 |
| 上下文构建 | 编写 context-builder SKILL.md |
| 迭代优化 | 在 orchestrator 中实现循环 |

---

## 5. 使用示例

### 5.1 基础使用

```bash
# 启动 session
claude-code-skill session-start myproject -d ~/myapp

# 发送任务
claude-code-skill session-send myproject "找出所有 TODO 并修复"

# 查看历史
claude-code-skill session-history myproject -n 50

# 停止
claude-code-skill session-stop myproject
```

### 5.2 团队模式

```bash
# 启动团队 session
claude-code-skill session-start dev-team -d ~/myapp \
  --agents '{
    "architect": {"prompt": "资深架构师"},
    "developer": {"prompt": "全栈开发者"},
    "reviewer": {"prompt": "代码审查员"}
  }' \
  --agent architect

# 架构师设计
claude-code-skill session-send dev-team "设计认证系统"

# 开发者实现
claude-code-skill session-send dev-team "@developer 实现这个设计"

# 审查员审查
claude-code-skill session-send dev-team "@reviewer 审查代码"
```

### 5.3 安全模式

```bash
# 只读模式（审查代码）
claude-code-skill session-start review -d ~/myapp \
  --tools "Read,Glob,Grep" \
  --max-budget 1.00

# Plan 模式（预览变更）
claude-code-skill session-start safe -d ~/myapp \
  --permission-mode plan

# 受限模式（限制危险操作）
claude-code-skill session-start limited -d ~/myapp \
  --allowed-tools "Bash(npm:*,git:*),Read,Edit" \
  --disallowed-tools "Bash(rm:*,sudo:*)"
```

---

## 6. 关键发现

### 6.1 这个项目正好是 Gary 需要的！

**核心价值：**
1. ✅ **OpenClaw → Claude Code 的桥梁**（核心需求）
2. ✅ **持久化 Session**（保持上下文）
3. ✅ **Agent 团队**（多角色协作）
4. ✅ **工具控制**（安全限制）
5. ✅ **权限模式**（质量控制）

**不需要自己实现的：**
- ❌ Claude Code 调用逻辑
- ❌ Session 管理
- ❌ MCP 协议
- ❌ 工具调用

**仍需要自己实现的：**
- ✅ QA Gate（质量检查）
- ✅ 知识库管理
- ✅ 上下文构建
- ✅ 迭代优化

### 6.2 与 OpenGoat 的区别

| 维度 | claude-code-skill | OpenGoat |
|------|-------------------|----------|
| **定位** | OpenClaw Skill | 完整平台 |
| **功能** | 调用 Claude Code | 组织 + 任务 + UI |
| **依赖** | backend-api | OpenClaw Gateway |
| **适合 Gary** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

**结论：claude-code-skill 更适合 Gary！**

---

## 7. 建议

### 7.1 立即采用

**理由：**
1. ✅ 完美匹配核心需求
2. ✅ 已经是 OpenClaw Skill 格式
3. ✅ 成熟的实现
4. ✅ 活跃维护

**不需要重复造轮子！**

### 7.2 补充缺失部分

**只需要补充：**

```
Gary 的 Skills/
├── dev-orchestrator/      # 研发流程编排（自己写）
├── qa-gate/               # 质量检查（自己写）
├── context-builder/       # 上下文构建（自己写）
└── claude-code-skill/     # Claude Code 调用（直接用）
```

**工作量：**
- 使用 claude-code-skill：0 天
- 补充 3 个 Skills：3-5 天
- **总计：3-5 天**（vs 自己实现 15-23 天）

### 7.3 下一步

1. **克隆项目**
   ```bash
   cd ~/.openclaw/workspace/skills
   git clone https://github.com/Enderfga/openclaw-claude-code-skill.git
   ```

2. **安装和测试**
   ```bash
   cd openclaw-claude-code-skill
   npm install
   npm run build
   ```

3. **编写其他 Skills**
   - dev-orchestrator（调用 claude-code-skill）
   - qa-gate
   - context-builder

---

## 8. 总结

### 核心价值

**claude-code-skill 是 OpenClaw 调用 Claude Code 的标准解决方案！**

| 维度 | 评分 |
|------|------|
| 与 Gary 需求匹配度 | ⭐⭐⭐⭐⭐ |
| 代码质量 | ⭐⭐⭐⭐ |
| 文档完整性 | ⭐⭐⭐⭐⭐ |
| 易用性 | ⭐⭐⭐⭐ |
| 可扩展性 | ⭐⭐⭐⭐ |

### 最终建议

**🎯 立即采用 claude-code-skill，补充 3 个自定义 Skills**

**工作量：**
- 采用 claude-code-skill：0 天
- 编写 dev-orchestrator：1-2 天
- 编写 qa-gate：1-2 天
- 编写 context-builder：1 天
- 测试和优化：1-2 天
- **总计：4-7 天** ✅

---

**文档状态：** 完成
**分析者：** Claw
**日期：** 2026-03-04
