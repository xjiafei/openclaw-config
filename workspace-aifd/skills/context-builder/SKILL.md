# context-builder — 精简上下文构建（v2.1 + Review Loop）

## 用途
为 Claude Code 生成精简版 CLAUDE.md。只提供目标、约束和记忆，不做技术指导。
v2.1 新增：注入 Review Loop 自检循环指令，提升文档输出质量。

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

### Step 3: 收集用户偏好
从 `workspace-aifd/memory/preferences.md` 提取与当前阶段相关的偏好规则。
这些偏好来自用户历史审批反馈，作为额外检查标准注入。

### Step 4: 准备检查清单
1. 读取 `workspace-aifd/templates/checklists/{current_stage}.json`
2. 复制到 `{project_path}/workspace/checklist.json`（重置所有 passes 为 false）
3. 如果 `preferences.md` 中有该阶段的额外检查项，追加到 checkItems 末尾

### Step 5: 生成 CLAUDE.md

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
- 检查清单：workspace/checklist.json
- 自检日志：workspace/review-log.md

## 约束
- 完成后自行运行构建和测试验证
- 遵循 docs/knowledges/standards/ 下的编码规范

## 审批检查点
完成需求分析（requirements.md）、产品设计（product.md）、技术设计（tech.md）后，
**必须执行 Review Loop 自检循环**（见下方），自检通过后输出文档摘要并停止，等待架构师审批。
审批通过后会通过 --resume 继续会话。
技术设计审批通过后，进入实现阶段并执行自动闭环。

## Review Loop 自检循环（文档阶段）

{review-loop-instructions.md 的完整内容}

## 实现-验收自动闭环（实现阶段）

{close-loop-instructions.md 的完整内容}

## 用户偏好（额外检查标准）
{preferences_summary}

## 项目记忆
{memory_summary}
```

**不包含的内容**：
- 不指定用哪个 agent
- 不写详细的输出格式要求
- 不做代码级规划
- 不注入 agent-memory

### Step 6: Git 存档
```bash
cd {project_path} && git add -A && git commit -m "pre-session: update CLAUDE.md + checklist" --allow-empty
```
