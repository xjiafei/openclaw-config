# memory-sync — 记忆同步（v2）

## 用途
每次研发 session 结束后，提取关键经验和用户偏好写入记忆系统。

## 参数
- `project_path`：业务项目的绝对路径

## 触发时机
每次 Claude Code session 完成后（无论成功失败）。

## 记录内容

### 1. 当日日志（workspace-aifd/memory/YYYY-MM-DD.md）
追加：
```markdown
### {HH:MM} AIFD - {project_name} - {stage} - {status}
- 任务：{task_description}
- 产物：{artifact_list}
- 耗时：{duration}
- 结果：{pass/fail/partial}
- 教训：{失败原因和解决方案}
```

### 2. 项目记忆（{project_path}/workspace/memory.md）
维护项目级记忆：
- 技术决策（日期 + 内容 + 原因）
- 审批反馈（日期 + 阶段 + 反馈内容 + 影响）
- 经验教训（问题 → 解决方案）

### 3. 用户偏好提取（workspace-aifd/memory/preferences.md）
回顾本次交互，检查是否有新的用户偏好需要记录：
- 用户明确表达的技术偏好（如"API 命名用 RESTful"）
- 用户明确表达的流程偏好（如"每次审批附上关键决策对比"）
- 用户明确表达的风格偏好（如"文档要简洁不要冗长"）

**提取规则**：
- 只记录用户**明确表达**的偏好，不推测
- 区分：项目相关 → 写入项目 `workspace/memory.md`；个性化偏好 → 写入 `preferences.md`
- 去重：已有相同偏好不重复记录
- 记录格式：`- {偏好内容}（{日期}，来源：{上下文}）`

### 4. 框架长期记忆（workspace-aifd/MEMORY.md）
跨项目经验，在重大发现时更新：
- 框架使用经验
- 通用的 Claude Code 调用技巧
- 跨项目的质量模式

## 原则
- 只记有价值的信息
- 失败和重试必须记录
- 技术决策必须记录原因
- 审批反馈必须持久化
