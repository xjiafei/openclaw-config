# quality-gate — 质量把关

## 用途
评估 Claude Code 产出的文档或代码的质量。

## 参数
- `project_path`：业务项目的绝对路径

## 评估维度

**文档类产物**（requirements.md, product.md, tech.md）：
1. 完整性：是否覆盖了所有需求点？
2. 一致性：与上游文档是否矛盾？
3. 可执行性：描述是否具体到可直接实现？
4. 质量评分：1-10

**后端代码类产物**（backend/）：
1. 功能完整性：是否实现了 tech.md 中定义的所有端点？
2. 编译检查：`cd {project_path}/backend && mvn compile`
3. 单元测试：`cd {project_path}/backend && mvn test`
4. 规范一致性：是否符合编码规范？
5. 质量评分：1-10

**前端代码类产物**（frontend/）：
1. 功能完整性：是否实现了 product.md 中定义的所有页面？
2. 构建检查：`cd {project_path}/frontend && npm run build`
3. 测试运行：`cd {project_path}/frontend && npm test`
4. 规范一致性：是否符合编码规范？
5. 质量评分：1-10

## 输出格式
写入 `{project_path}/workspace/sessions/{timestamp}-review.json`：
```json
{
  "stage": "当前阶段",
  "timestamp": "ISO时间戳",
  "verdict": "pass|fail",
  "score": 7,
  "must_fix": [],
  "suggestions": [],
  "summary": "一句话总结"
}
```

## 回归门禁（implementation / testing 阶段）

在 implementation 和 testing 阶段，除常规质量评分外，还必须执行全量测试：
- 后端：`cd {project_path}/backend && mvn test`（或对应构建工具）
- 前端：`cd {project_path}/frontend && npm test`（或对应构建工具）
- **全量测试必须全部通过，否则直接判定 fail**，不论评分多高

## 判定规则
- implementation / testing 阶段：全量测试必须通过 **且** score >= 7 且 must_fix 为空 → pass
- 其他阶段：score >= 7 且 must_fix 为空 → pass
- 否则 → fail
