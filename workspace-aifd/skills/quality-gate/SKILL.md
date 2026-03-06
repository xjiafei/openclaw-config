# quality-gate — 质量把关

## 用途
评估 Claude Code 产出的文档或代码的质量。

## 评估维度

**文档类产物**（requirements.md, product.md, tech.md）：
1. 完整性：是否覆盖了所有需求点？
2. 一致性：与上游文档是否矛盾？
3. 可执行性：描述是否具体到可直接实现？
4. 质量评分：1-10

**Java 代码类产物**（backend/）：
1. 功能完整性：是否实现了 tech.md 中定义的所有端点？
2. 编译检查：`cd backend && mvn compile`
3. 单元测试：`cd backend && mvn test`
4. 规范一致性：是否符合 java-coding.md？
5. 质量评分：1-10

**React 代码类产物**（frontend/）：
1. 功能完整性：是否实现了 product.md 中定义的所有页面？
2. 构建检查：`cd frontend && npm run build`
3. 测试运行：`cd frontend && npm test`
4. 规范一致性：是否符合 react-coding.md？
5. 质量评分：1-10

## 输出格式
写入 `workspace/sessions/{timestamp}-review.json`：
```json
{
  "stage": "implementation",
  "timestamp": "...",
  "verdict": "pass|fail",
  "score": 7,
  "must_fix": [],
  "suggestions": [],
  "summary": "一句话总结"
}
```

## 判定规则
- score >= 7 且 must_fix 为空 → pass
- 否则 → fail
