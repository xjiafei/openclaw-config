# quality-gate — 完成状态确认（v2）

## 用途
确认 Claude Code 产出的完成状态。**不做 LLM 打分评估**，只做客观检查。

## 参数
- `project_path`：业务项目的绝对路径
- `stage`：当前阶段

## 检查逻辑

### 文档阶段（requirements / product / tech）

1. 检查 Claude Code 退出码是否为 0
2. 检查产出文件是否存在：
   - requirements → `docs/specs/requirements.md`（增量时：`docs/specs/features/{feature_id}/requirements.md`）
   - product → `docs/specs/product.md`（增量时：`docs/specs/features/{feature_id}/product.md`）
   - tech → `docs/specs/tech.md`（增量时：`docs/specs/features/{feature_id}/tech.md`）
3. 检查文件非空（`wc -l` > 10）

判定：退出码 0 + 文件存在且非空 → pass

### 实现阶段（implementation）

1. 检查 Claude Code 退出码
2. 检查关键目录/文件是否存在（backend/src、frontend/src 等）
3. 尝试构建验证（仅当不确定 Claude Code 是否自行验证时）：
   - `cd backend && mvn compile`（如果是 Java 项目）
   - `cd frontend && npm run build`（如果是前端项目）

判定：退出码 0 + 构建通过 → pass

### 测试阶段（testing）

1. 检查 Claude Code 退出码
2. Claude Code 报告测试通过即可

## 输出

直接向 OpenClaw 返回结果，不写 review.json 文件：
- `pass`：继续流程
- `fail`：附带失败原因，通知用户

## 不做的事
- 不调 LLM 评估文档质量
- 不打分
- 不检查"完整性""一致性""可执行性"
- 不做 docs 沉淀检查（由 Claude Code 自行处理）
