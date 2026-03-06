# memory-sync — 记忆同步

## 用途
每次研发 session 结束后，提取关键经验写入记忆系统。

## 触发时机
每次 Claude Code session 完成后（无论成功失败）。

## 记录内容

### 当日日志（memory/YYYY-MM-DD.md）
追加：
```markdown
### {HH:MM} AIFD - {stage} - {status}
- 任务：{task_description}
- 产物：{artifact_list}
- 耗时：{duration}
- 结果：{pass/fail/partial}
- 教训：{失败原因和解决方案}
```

### 项目记忆（workspace/memory.md）
维护项目级记忆：
- 技术决策（日期 + 内容 + 原因）
- 经验教训（问题 → 解决方案）
- 质量模式（反复出现的问题、有效的提示词）

## 原则
- 只记有价值的信息
- 失败和重试必须记录
- 技术决策必须记录原因
