# Review Loop 自检循环指令

## 阶段产出责任

每个阶段有明确的产出物和负责角色：

| 阶段 | 产出物 | 负责角色 | 输出路径 |
|------|--------|---------|---------|
| 需求分析 | requirements.md | 主代理 | docs/specs/requirements.md |
| 产品设计 | product.md | 主代理 | docs/specs/product.md |
| 技术设计 | tech.md | 主代理 | docs/specs/tech.md |
| 技术设计 | test-plan.md（测试方案） | 主代理调度 **qa-agent** | docs/specs/test-plan.md |
| 技术设计 | test-cases.md（测试用例集） | 主代理调度 **qa-agent** | docs/specs/test-cases.md |

### 技术设计阶段特殊流程

技术设计阶段完成 tech.md 后，**必须先调度 qa-agent** 产出测试方案和测试用例集，再进入自检循环：

1. 主代理完成 tech.md 初稿
2. 调度 qa-agent，prompt：
   ```
   请基于以下文档设计测试方案和测试用例集：
   - 需求文档：docs/specs/requirements.md
   - 产品设计：docs/specs/product.md
   - 技术设计：docs/specs/tech.md

   产出要求：
   1. docs/specs/test-plan.md — 测试方案：测试策略（单元/集成/E2E 的范围与覆盖目标）、测试环境要求、质量标准（覆盖率目标、通过率）、测试工具选型
   2. docs/specs/test-cases.md — 测试用例集：结构化用例表，每条包含用例 ID、所属模块、前置条件、操作步骤、预期结果、优先级（P0-P3），覆盖正向/异常/边界场景

   测试目录规范（必须在测试方案中明确）：
   - 后端单元测试：遵循 Maven/Gradle 约定，放 {backend}/src/test/
   - E2E 测试脚本 + playwright.config：testing/e2e/
   - 集成测试脚本：testing/integration/
   - 测试数据/fixtures：testing/data/
   - 测试报告：testing/reports/
   ```
3. qa-agent 产出完成后，三份文档（tech.md + test-plan.md + test-cases.md）一起进入自检循环
4. 自检时 checklist 包含 T8（测试方案）和 T9（测试用例集）检查项

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
- 如果迭代次数 < `minIterations`（默认 2）→ **即使全部通过也必须继续**，回到 Step 2
- 如果迭代次数 >= `minIterations` 且所有项 `passes: true` → 更新 `workspace/checklist.json` → 退出循环，输出文档摘要
- 如果仍有未通过项且迭代次数 < `maxIterations` → 回到 Step 2
- 如果达到 `maxIterations` 仍有未通过项 → 更新 `workspace/checklist.json`（保留未通过状态）→ 退出循环，输出文档摘要并列出未通过项

### 多轮自检策略
- **第 1 轮**：以文档作者视角检查，对照 checklist 逐项验证
- **第 2 轮**：切换为**架构师的挑剔视角**，重新审查所有项。尝试找出第 1 轮遗漏的问题：
  - 验收标准是否真的可测试？还是写得模糊？
  - 非功能需求的数字是否合理？有没有拍脑袋？
  - 边界和排除项是否足够明确？会不会有歧义？
  - 术语是否真的一致？有没有同义词混用？
- **第 3 轮（如需）**：修复第 2 轮发现的问题后再次全量检查
- 连续 2 轮全部通过才能退出循环

### 重要约束
- 每轮迭代必须重新审查所有项（避免修 A 破 B）
- 第 2 轮不能敷衍通过，必须用批判性思维真正寻找问题
- 修正时优先补充内容，不要删减已有合理内容
- review-log.md 是追加写入，不要覆盖之前的记录
- 检查要严格：模糊的描述不算通过，必须具体可验证
