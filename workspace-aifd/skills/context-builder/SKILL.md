# context-builder — 精简上下文构建（v2）

## 用途
为 Claude Code 生成精简版 CLAUDE.md。只提供目标、约束和记忆，不做技术指导。

## 参数
- `project_path`：业务项目的绝对路径

## 使用方式

### Step 1: 读取当前状态
读取 `{project_path}/workspace/pipeline.json`，确定：
- 当前阶段（current_stage）
- 会话 ID（session_id）

### Step 2: 收集记忆摘要
从以下来源提取**简短摘要**（每项不超过 3 条）：
- `{project_path}/workspace/memory.md`（项目级记忆）
- `workspace-aifd/memory/` 最近 2 天的日志

记忆只提取"做法"和"避坑"类信息，不注入详细内容。

### Step 3: 生成 CLAUDE.md

写入 `{project_path}/CLAUDE.md`，内容：

```markdown
# CLAUDE.md

## 项目概述
- 项目：{project_name}
- 技术栈：{tech_stack}
- 业务域：{domain}

## 当前任务
{用户原始需求描述}

## 文件路径指引
- 需求/设计文档：docs/specs/
- 编码规范：docs/knowledges/standards/
- Agent 定义：.claude/agents/
- 项目记忆：workspace/memory.md

## 约束
- 完成后自行运行构建和测试验证
- 遵循 docs/knowledges/standards/ 下的编码规范

## 审批检查点
完成需求分析（requirements.md）、产品设计（product.md）、技术设计（tech.md）后，
分别输出文档摘要并停止，等待架构师审批。审批通过后会通过 --resume 继续会话。
技术设计审批通过后，请一路完成实现和测试。

## 项目记忆
{memory_summary}
```

**不包含的内容**：
- 不指定用哪个 agent
- 不写详细的输出格式要求
- 不做代码级规划
- 不注入 agent-memory

### Step 4: Git 存档
```bash
cd {project_path} && git add -A && git commit -m "pre-session: update CLAUDE.md" --allow-empty
```
