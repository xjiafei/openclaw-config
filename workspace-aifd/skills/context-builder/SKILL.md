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

### Step 2: 读取相关文档
根据当前阶段，读取对应的输入文档：
- requirements 阶段：读取用户原始需求（从 workspace-aifd/requests/ 获取）
- product 阶段：读取 `{project_path}/docs/specs/requirements.md`
- tech 阶段：读取 `{project_path}/docs/specs/product.md`
- implementation 阶段：读取 `{project_path}/docs/specs/tech.md`
- testing 阶段：读取代码目录 + `{project_path}/docs/specs/requirements.md`

### Step 3: 读取记忆
- 读取 `workspace-aifd/memory/YYYY-MM-DD.md`（最近 2 天），提取相关经验
- 读取 `{project_path}/workspace/memory.md`（项目级记忆）

### Step 4: 读取知识库
根据当前阶段，读取 `{project_path}/docs/knowledges/` 下相关文档：
- implementation 阶段（后端）：standards/ + templates/
- implementation 阶段（前端）：standards/
- 所有阶段：domain/

### Step 5: 生成 CLAUDE.md
参考 `templates/claude-code-project/CLAUDE.md.template`，填入实际数据，写入 `{project_path}/CLAUDE.md`。

### Step 6: Git 存档
```bash
cd {project_path} && git add -A && git commit -m "pre-session: {stage}-{timestamp}" --allow-empty
```
