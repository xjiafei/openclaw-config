# context-builder — 上下文构建

## 用途
为 Claude Code 生成 CLAUDE.md 文件。在每次调用 Claude Code 前使用。

## 使用方式

### Step 1: 读取当前状态
读取项目根目录下的 `workspace/pipeline.json`，确定：
- 当前阶段（current_stage）
- 当前阶段状态
- 上一 session 结果（workspace/sessions/ 下最新文件）

### Step 2: 读取相关文档
根据当前阶段，读取对应的输入文档：
- requirements 阶段：读取用户原始需求
- product 阶段：读取 docs/specs/requirements.md
- tech 阶段：读取 docs/specs/product.md
- implementation 阶段：读取 docs/specs/tech.md
- testing 阶段：读取 backend/ + frontend/ 代码 + docs/specs/requirements.md

### Step 3: 读取记忆
读取 OpenClaw 的 memory/YYYY-MM-DD.md（最近 2 天），提取与当前任务相关的经验。

### Step 4: 读取知识库
根据当前阶段，读取 docs/knowledges/ 下相关文档：
- implementation 阶段（后端）：standards/java-coding.md + templates/api-design.md + templates/db-design.md
- implementation 阶段（前端）：standards/react-coding.md
- 所有阶段：domain/todo-domain.md

### Step 5: 生成 CLAUDE.md
使用以下模板填入实际数据，写入项目根目录的 CLAUDE.md。

### Step 6: Git 存档
```bash
cd {project_root} && git add -A && git commit -m "pre-session: {stage}-{timestamp}" --allow-empty
```

## CLAUDE.md 模板

```markdown
# CLAUDE.md — AIFD 任务指令

## 项目概述
- 项目：{project_name}
- 类型：前后端分离 Web 应用
- 技术栈：Spring Boot + React + MySQL

## 当前阶段：{current_stage}

### 任务目标
{task_description}

### 输入文档
请阅读以下文件了解上下文：
{input_files_list}

### 输出要求
请产出以下文件：
{output_files_list}

### 质量标准
{quality_criteria}

### 约束
{constraints}

## Session 连续性
### 上次 Session 状态
- 状态：{last_session_status}
- 已完成：{completed_artifacts}
- 未完成：{pending_work}

### 修正指令
{must_fix_list}

## 编码规范
请参考 docs/knowledges/standards/ 下的编码规范文档。

## Agent 角色说明
你是 {agent_role}，负责 {role_responsibility}。
```
