# context-builder — 上下文构建

## 用途
为 Claude Code 生成 CLAUDE.md 文件。在每次调用 Claude Code 前使用。

## 参数
- `project_path`：业务项目的绝对路径（从 projects/registry.json 获取）

## 使用方式

### Step 1: 读取当前状态
读取 `{project_path}/workspace/pipeline.json`，确定：
- 当前阶段（current_stage）
- 当前阶段状态
- 上一 session 结果（`{project_path}/workspace/sessions/` 下最新文件）

### Step 2: 注入用户需求、记忆与 Agent 经验（轻上下文策略）

**只注入摘要和路径，不做全量内容注入。**

注入内容：
- 用户原始需求文本（从 workspace-aifd/requests/ 获取）
- 项目级记忆摘要（`{project_path}/workspace/memory.md` 最近条目）
- 框架记忆摘要（`workspace-aifd/memory/YYYY-MM-DD.md` 最近 2 天关键条目）
- 当前执行 Agent 的经验摘要（`{project_path}/workspace/agent-memory/{agent-id}.md` 最近 3 条）

> 当前阶段与 agent 映射建议：
> - requirements/product -> `pm-agent`
> - tech -> `arch-agent`
> - implementation -> `java-be-agent` / `vue-fe-agent`
> - testing -> `qa-agent`

注入到 CLAUDE.md 的“历史经验”段，格式建议：
- 做法：...
- 避坑：...
- 本轮优先检查：...

### Step 3: 给出目录路径与输出要求

**代码和文档不做全量注入，只给路径和产出要求。**

根据当前阶段，在 CLAUDE.md 中写明：
- 上游文档路径（如 `docs/specs/requirements.md` 或 `docs/specs/featureXXX-specs/requirements.md`）
- 代码目录路径（如 `backend/`、`frontend/`）
- 知识库目录路径（如 `docs/knowledges/standards/`）
- 本阶段的输出文件路径与格式要求

Claude Code 执行时自行按需读取这些路径的内容。

### Step 4: 生成 CLAUDE.md
参考 `templates/claude-code-project/CLAUDE.md.template`，填入实际数据，写入 `{project_path}/CLAUDE.md`。

### Step 5: Git 存档
```bash
cd {project_path} && git add -A && git commit -m "pre-session: {stage}-{timestamp}" --allow-empty
```
