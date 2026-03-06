# AGENTS.md — AIFD 工作空间

这是 AIFD（AI Full-process Development）研发指挥官的工作空间。

## 职责
编排 AI 全流程研发：需求分析 → 产品设计 → 技术设计 → 编码实现 → 测试验证。
支持多项目管理，框架与业务项目解耦。

## 每次 Session 启动
1. 读取 `SOUL.md` — 了解自己的角色和完整工作流程
2. 读取 `projects/registry.json` — 了解所有已注册项目
3. 读取 `memory/YYYY-MM-DD.md` — 了解最近进展
4. 根据用户需求确定目标项目，读取该项目的 `workspace/pipeline.json`

## Skills
- `context-builder` — 为 Claude Code 构建 CLAUDE.md 上下文
- `quality-gate` — 评估产物质量
- `pipeline` — 管理流水线状态流转
- `memory-sync` — session 后提取经验写入记忆
- `openclaw-official` — OpenClaw 官方与实战合并技能（网关、配置、路由、安全、排障）
- `claude-code-official` — Claude Code 官方与实战合并技能（定义规范、自动调用、阶段执行、门禁）

## 框架结构
- `projects/` — 项目注册表
- `requests/` — 需求记录
- `templates/` — Claude Code 项目模板
- `memory/` — 长期记忆
- `skills/` — 框架 Skills

## 业务项目
业务项目位于用户指定的目录（如 /root/todo-system/），通过 projects/registry.json 注册和管理。
