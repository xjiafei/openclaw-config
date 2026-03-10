# Review Loop 自检循环 + 评审团指令

## 阶段产出责任

| 阶段 | 产出物 | 负责角色 | 输出路径 |
|------|--------|---------|---------|
| 需求分析 | requirements.md | pm-agent（模式 A） | docs/specs/requirements.md |
| 产品设计 | product.md | pm-agent（模式 B） | docs/specs/product.md |
| 技术设计 | tech.md | arch-agent（模式 A） | docs/specs/tech.md |
| 技术设计 | test-plan.md | qa-agent（模式 A） | docs/specs/test-plan.md |
| 技术设计 | test-cases.md | qa-agent（模式 A） | docs/specs/test-cases.md |

## 流程：产出 → 自检 → 评审团 → 人工审批

每个文档阶段必须经过三道关：

### 第一关：Agent 产出 + 自检循环

1. 调度对应 agent 产出文档
2. 验证 agent 的输出契约是否满足
3. 加载 `workspace/checklist.json` 中当前阶段的检查清单
4. 对照清单逐项检查文档
5. 不通过的项 → 修正文档 → 重新检查（最多 3 轮）
6. 记录自检结果到 workspace/review-log.md

### 第二关：评审团交叉评审

自检通过后，调度评审团成员用**模式 C**评审：

**需求文档评审团**：
```
调度 qa-agent（模式 C）：
  "请评审 docs/specs/requirements.md，关注：需求是否可测试？验收标准是否清晰？
   输出评审意见到 workspace/review-requirements-qa.json"

调度 arch-agent（模式 C）：
  "请评审 docs/specs/requirements.md，关注：技术可行性初判，有无不可实现的需求？
   输出评审意见到 workspace/review-requirements-arch.json"
```

**产品设计评审团**：
```
调度 arch-agent（模式 C）：
  "请评审 docs/specs/product.md，关注：与技术约束是否兼容？
   输出评审意见到 workspace/review-product-arch.json"

调度 qa-agent（模式 C）：
  "请评审 docs/specs/product.md，关注：交互流程是否可 E2E 测试？
   输出评审意见到 workspace/review-product-qa.json"
```

**技术设计评审团**（tech.md + test-plan.md + test-cases.md 一起评审）：
```
调度开发 agent（模式评审）：
  "请评审 docs/specs/tech.md，关注：方案是否可落地？数据模型和 API 设计是否合理？
   输出评审意见到 workspace/review-tech-dev.json"

调度 qa-agent：
  "请评审 docs/specs/test-plan.md 和 test-cases.md，关注：测试策略是否全面？用例覆盖是否充分？
   输出评审意见到 workspace/review-tech-qa.json"
```

### 第三关：汇总评审意见 + 修正

1. 读取所有 workspace/review-{stage}-*.json
2. 汇总意见：
   - CRITICAL 意见 → **必须修正**，修正后重新调度对应评审方复审
   - HIGH 意见 → 修正
   - MEDIUM/LOW 意见 → 酌情修正或标注为已知
3. 修正后更新文档
4. 将评审过程记录到 workspace/review-log.md：

```markdown
### 评审团 — {stage}
| 评审方 | 结论 | CRITICAL | HIGH | MEDIUM |
|--------|------|----------|------|--------|
| qa-agent | APPROVE | 0 | 1 | 2 |
| arch-agent | REQUEST_CHANGES | 1 | 0 | 1 |

**CRITICAL 意见处理**：
- [arch] xxx → 已修正：xxx

**HIGH 意见处理**：
- [qa] xxx → 已修正：xxx
```

5. 所有 CRITICAL 处理完毕 → 更新 stage-status.json（status=waiting_approval）→ 输出文档摘要，等待人工审批

## 技术设计阶段特殊流程

技术设计是最复杂的阶段，需要多角色协作：

1. 调度 arch-agent（模式 A）→ 产出 tech.md
2. 调度 qa-agent（模式 A）→ 基于 requirements.md + product.md + tech.md 产出 test-plan.md + test-cases.md
3. 三份文档一起进入自检循环
4. 三份文档一起进入评审团评审
5. 三份文档一起提交人工审批

## 自检清单格式

`workspace/checklist.json` 由 context-builder 生成，格式：

```json
{
  "stage": "requirements",
  "minIterations": 2,
  "maxIterations": 4,
  "checkItems": [
    { "id": "R1", "title": "用户角色完整", "criteria": "列出所有角色+权限矩阵", "passes": null }
  ]
}
```

## 多轮自检策略
- **第 1 轮**：以文档作者视角检查，对照 checklist 逐项验证
- **第 2 轮**：切换为**架构师的挑剔视角**，尝试找出遗漏：验收标准是否可测试？非功能需求数字是否合理？术语是否一致？
- 连续 2 轮全部通过才能进入评审团

## 重要约束
- 每轮迭代必须重新审查所有项（避免修 A 破 B）
- 修正时优先补充内容，不删减已有合理内容
- review-log.md 是追加写入，不覆盖之前记录
- 评审团意见必须逐条处理，不能选择性忽略
