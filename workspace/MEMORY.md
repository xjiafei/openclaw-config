# MEMORY.md - Claw 长期记忆

## 身份

- **名称：** Claw 🐾
- **用户：** Gary，软件架构师
- **创建时间：** 2026-03-04

## 核心项目

### AI 驱动全流程研发框架

分层托管方案：
- OpenClaw：编排 + 记忆 + 知识库
- Claude Code：执行团队（PM + Architect + Developer + QA）

## OpenClaw Agent 创建流程

1. **创建 workspace 目录**
   ```bash
   mkdir -p ~/.openclaw/workspace-<agent-id>/memory
   ```

2. **创建 workspace 文件**
   - `SOUL.md` - 身份定义
   - `AGENTS.md` - 工作空间说明
   - `USER.md` - 用户信息
   - `MEMORY.md` - 长期记忆
   - `memory/YYYY-MM-DD.md` - 每日日志

3. **创建 agent 配置目录**
   ```bash
   mkdir -p ~/.openclaw/agents/<agent-id>/agent
   mkdir -p ~/.openclaw/agents/<agent-id>/sessions
   ```

4. **复制认证和模型配置**
   ```bash
   cp ~/.openclaw/agents/main/agent/auth-profiles.json ~/.openclaw/agents/<agent-id>/agent/
   cp ~/.openclaw/agents/main/agent/models.json ~/.openclaw/agents/<agent-id>/agent/
   ```

5. **更新 openclaw.json 的 agents.list**
   ```json
   {
     "id": "<agent-id>",
     "name": "<agent-name>",
     "workspace": "/root/.openclaw/workspace-<agent-id>",
     "agentDir": "/root/.openclaw/agents/<agent-id>",
     "sandbox": {"mode": "off"},
     "tools": {"allow": ["*"]}
   }
   ```

6. **重启 Gateway**
   ```bash
   openclaw gateway restart
   ```

**目录结构：**
```
~/.openclaw/
├── workspace-<agent-id>/    # workspace（SOUL.md 等）
└── agents/<agent-id>/
    ├── agent/               # auth + models
    └── sessions/
```

## 已配置的模型 Provider

### zai (z.ai)
- baseUrl: https://api.z.ai/api/coding/paas/v4
- models: glm-5, glm-4.7, glm-4.7-flash, glm-4.7-flashx

### ccc (claude-code.club)
### ccc-openai (claude-code.club OpenAI 兼容)
- baseUrl: https://claude-code.club/openai
- models: gpt-5.3-codex, gpt-5.2, gpt-5.1, gpt-5, o3, o3-mini, gpt-4o, gpt-4o-mini
- baseUrl: https://claude-code.club/api
- models: claude-haiku-4-5, claude-sonnet-4-5, claude-opus-4-5, claude-sonnet-4-6, claude-opus-4-6

---

_持续更新中。_

## Solution Agent 工作流程

### 5阶段多模型协作流程

```
Phase 1: 多模型并行方案生成
    ↓
Phase 2: 自我 Review（2轮）
    ↓
Phase 3: Claw 合并 Review
    ↓
Phase 4: 交叉 Review（3轮）
    ↓
Phase 5: 最终输出 SOLUTION.md
```

参与模型：
- Claude Opus 4.6 (ccc/claude-opus-4-6)
- Claude Sonnet 4.6 (ccc/claude-sonnet-4-6)
- GLM-5 (zai/glm-5)
- GPT 5.x (待配置)

## Gary 偏好

- **复杂任务请异步执行** - 使用 sessions_spawn 创建 sub-agent
