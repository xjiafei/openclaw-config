---
name: claude-code-official
description: Claude Code 使用规范（v2）。持久会话模式、agent 定义规范、自我进化策略。
version: 2.0.0
---

# Claude Code Official (v2)

## 适用场景
- 设计或优化 Claude Code 执行流程
- 定义/审计 `.claude/agents` 与 `.claude/skills`
- 用 Claude Code 执行研发任务

## v2 核心变化
- 使用 `--session-id` + `--resume` 持久会话模式（非一次性 `--print`）
- OpenClaw 不做 LLM 质量打分，只做完成状态确认
- Claude Code 自主完成全流程（需求分析 → 设计 → 实现 → 测试）
- 审批检查点：requirements / product / tech 完成后暂停等待架构师审批

## 执行命令

### 首次启动
```bash
SESSION_ID=$(uuidgen)
su - claw -c "source ~/.bashrc && cd {project_path} && \
  claude --print --dangerously-skip-permissions \
  --session-id $SESSION_ID \
  -p '任务目标 + 用户需求 + 项目记忆 + 审批检查点说明'"
```

### 审批后恢复
```bash
su - claw -c "source ~/.bashrc && cd {project_path} && \
  claude --print --dangerously-skip-permissions \
  --resume $SESSION_ID \
  -p '审批反馈 + 继续下一阶段'"
```

### 回退方案
1. `--resume` 失败 → 尝试 `--continue`
2. 仍失败 → 新会话，注入已完成文档路径

## Agent 定义规范
- YAML frontmatter：name、description、tools、model、version
- 正文结构：角色定位 → 调用边界 → 诊断命令 → 质量检查清单（CRITICAL/HIGH/MEDIUM）→ 代码示例 → 执行清单 → 交付标准
- 动态注入：`<!-- DYNAMIC_INJECT_START/END -->`

## 自我进化
Claude Code 有权在执行中优化：
- `.claude/agents/*.md`：增加执行清单项、补充风险、细化标准
- `.claude/skills/`：沉淀可复用能力
- `.claude/hooks/`：增加自动检查
- `docs/knowledges/`：沉淀通用知识
详见 `agent-evolution-policy.md`

## 参考
- `references/official-overview-notes.md`
