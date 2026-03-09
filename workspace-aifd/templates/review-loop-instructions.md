# Review Loop 自检循环指令

## 自检流程

每个需要审批的阶段（需求分析、产品设计、技术设计）完成文档初稿后，你必须执行以下自检循环：

### Step 1: 加载检查清单
从 `workspace/checklist.json` 读取当前阶段的检查清单。

### Step 2: 逐项检查
对照检查清单的每一项 `checkItems`，审查你的文档：
- 如果该项满足 `criteria`，标记 `"passes": true`
- 如果不满足，标记 `"passes": false`，记录具体缺陷

### Step 3: 修正未通过项
对所有 `passes: false` 的项，修改文档使其达标。

### Step 4: 记录自检日志
将本轮检查结果追加写入 `workspace/review-log.md`，格式：

```markdown
### Iteration {N} — {stage}
- {id}: ✅/❌ {说明，如修正了什么}
```

### Step 5: 判断是否继续
- 如果所有项 `passes: true` → 更新 `workspace/checklist.json` → 退出循环，输出文档摘要
- 如果仍有未通过项且迭代次数 < `maxIterations` → 回到 Step 2
- 如果达到 `maxIterations` 仍有未通过项 → 更新 `workspace/checklist.json`（保留未通过状态）→ 退出循环，输出文档摘要并列出未通过项

### 重要约束
- 每轮迭代必须重新审查所有项（避免修 A 破 B）
- 修正时优先补充内容，不要删减已有合理内容
- review-log.md 是追加写入，不要覆盖之前的记录
- 检查要严格：模糊的描述不算通过，必须具体可验证
