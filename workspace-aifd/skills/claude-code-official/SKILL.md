---
name: claude-code-official
description: Claude Code 官方与实战合并技能。用于 Claude Code 的规范化使用：CLI 异步执行（claw 账号）、CLAUDE.md 指令设计、agents/skills/hooks/commands 定义规范、阶段化交付、质量门禁、缺陷闭环与进度汇报。
version: 2.0.0
---

# Claude Code Official (Merged)

## 适用场景
- 设计或优化 Claude Code 执行流程
- 定义/审计 `.claude/agents` 与 `skills/*/SKILL.md`
- 用 Claude Code 执行阶段任务（requirements/product/tech/implementation/testing）

## 统一原则
1. AIFD 负责编排与门禁；Claude Code 负责按需自动调用 `.claude/*` 能力。
2. 定义类文件遵循：**YAML 前置 + 说明正文**。
3. 全量与增量需求统一走 5 阶段；增量使用 `docs/specs/featureXXX-specs/`。
4. 任务执行使用 `claw` 账号、异步运行，并进行周期进度汇报。

## 标准执行命令
```bash
su - claw -c 'source ~/.bashrc && cd {project_path} && claude --print --dangerously-skip-permissions -p "{prompt}"'
```

## 质量门禁
- 文档阶段：完整性/一致性/可执行性 >= 7
- implementation/testing：必须跑全量测试
  - 后端：`mvn test`
  - 前端：`npm test`
- 开发与测试闭环：读取 `testing/reports/bugs/` -> 修复 -> 回写状态

## 定义规范边界
- 强制：`.claude/agents/*.md`、`skills/*/SKILL.md`
- 非强制：普通文档（README/SOUL/MEMORY/requests 等）

## 参考
- `references/official-overview-notes.md`
- 官方文档索引：`https://code.claude.com/docs/llms.txt`
