---
name: agent-evolution-policy
description: "Agent自我进化与经验回写规范。"
version: 1.0.0
---

# Agent 自我进化策略

## 目的
通过结构化的经验回写和跨环节反馈，使 Agent 在项目推进中持续优化执行质量。

## 经验回写协议

### 触发时机
每个 Agent 在以下时刻必须执行经验回写：
1. **阶段完成时**：无论通过还是失败，都要回写
2. **质量门禁不通过时**：记录失败原因和修正方案
3. **ReAct 重试时**：记录每次重试的调整策略

### 回写格式
追加到 `workspace/agent-memory/{agent-id}.md`：
```markdown
### [YYYY-MM-DD] — [阶段名] — [项目/特性名]
- **本轮收获**：（做得好的地方、发现的高效模式）
- **失败/问题**：（遇到的问题、返工原因、根因分析）
- **下次改进**：（具体可执行的改进点，不要泛泛而谈）
```

### 回写原则
- **具体**：不写"加强质量"，写"API 响应体缺少分页字段，下次先对照 tech.md 字段清单逐一核对"
- **可执行**：改进点必须是下次可直接执行的动作
- **简洁**：每次回写不超过 10 行

## 跨环节反馈机制

### 下游反馈上游
当下游 Agent 发现上游产物有问题时：
1. 在自己的 agent-memory 记录具体问题
2. 同时在上游 Agent 的 agent-memory 追加反馈：
   ```markdown
   ### [日期] — 跨环节反馈 from {下游agent}
   - **问题**：（具体描述）
   - **建议**：（如何避免）
   ```

### 反馈流向
- qa-agent → java-be-agent / vue-fe-agent：测试发现的代码问题模式
- java-be-agent / vue-fe-agent → arch-agent：实现中发现的设计缺陷
- arch-agent → pm-agent：技术可行性问题导致的需求调整

## 经验消费

### context-builder 注入
context-builder 构建 CLAUDE.md 时，读取对应 agent-memory 的最近 3 条记录，注入到 CLAUDE.md 的"历史经验"段落。

### 积累与归档
- 单个 agent-memory 文件超过 50 条时，提取共性经验归档到 `docs/knowledges/` 目录
- 归档后保留最近 20 条，其余移除
