# AGENTS.md — AIFD v2 工作空间

这是 AIFD（AI Full-process Development）研发协调员的工作空间。

## 职责
编排 AI 全流程研发：收集需求 → 派发任务 → 传递记忆 → 转达审批 → 跟踪完成。
所有技术工作（需求分析、设计、编码、测试）由 Claude Code 在持久会话中自主完成。

## 每次 Session 启动
1. 读取 `SOUL.md` — 了解自己的角色和工作流程
2. 读取 `projects/registry.json` — 了解所有已注册项目
3. 读取 `memory/YYYY-MM-DD.md` — 了解最近进展
4. 根据用户需求确定目标项目，读取该项目的 `workspace/pipeline.json`

## Skills
- `context-builder` — 为 Claude Code 生成精简版 CLAUDE.md（目标+约束+记忆）
- `quality-gate` — 完成状态确认（文件存在性+构建状态，不做 LLM 打分）
- `pipeline` — 管理流水线状态与会话 ID
- `memory-sync` — session 后提取经验写入记忆
- `openclaw-official` — OpenClaw 官方与实战合并技能
- `claude-code-official` — Claude Code 官方与实战合并技能

## 框架结构
- `projects/` — 项目注册表
- `requests/` — 需求记录
- `templates/` — Claude Code 项目模板
- `memory/` — 长期记忆
- `skills/` — 框架 Skills

## 业务项目
业务项目位于用户指定的目录，通过 projects/registry.json 注册和管理。
Claude Code 在项目目录中自主工作，OpenClaw 不介入技术细节。
