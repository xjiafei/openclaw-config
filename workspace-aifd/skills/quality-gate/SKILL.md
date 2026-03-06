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

## Docs 沉淀检查

质量评估完成后，还必须执行 docs 沉淀检查：

1. **specs 更新**：本阶段产物是否已正确写入 docs/specs/（或 featureXXX-specs/）？
2. **knowledges 沉淀**：是否有通用知识/规范/模式需要沉淀到 docs/knowledges/？
3. **README 同步**：项目运行方式是否有变化需要更新 README？
4. **agent-memory 回写**：执行 Agent 的经验是否已回写到 workspace/agent-memory/？
5. **增量合并**：如果是增量特性且 testing 通过，检查 featureXXX-specs 是否需要合并到全量 specs

检查结果写入 review.json 的 `doc_check` 字段：
```json
{
  "doc_check": {
    "specs_updated": true,
    "knowledges_updated": false,
    "readme_updated": true,
    "agent_memory_written": true,
    "feature_merge_needed": false
  }
}
```

## 判定规则
- implementation / testing 阶段：全量测试必须通过 **且** score >= 7 且 must_fix 为空 → pass
- 其他阶段：score >= 7 且 must_fix 为空 → pass
- 否则 → fail
- **doc_check 不影响 pass/fail 判定，但会作为提醒输出给指挥官**
