# pipeline — 流水线管理

## 用途
管理研发流水线状态。初始化、推进阶段、记录 session。

## 参数
- `project_path`：业务项目的绝对路径

## 状态文件
`{project_path}/workspace/pipeline.json`

## 阶段定义

| 阶段 ID | 名称 | 负责 Agent | 人工审批 |
|---------|------|-----------|---------|
| requirements | 需求分析 | pm-agent | ✅ |
| product | 产品设计 | pm-agent | ✅ |
| tech | 技术设计 | architect-agent | ✅ |
| implementation | 编码实现 | developer-agent | ❌ |
| testing | 测试验证 | qa-agent | ❌ |

## 状态流转
- pending → in_progress → done（无需审批的阶段）
- pending → in_progress → pending_approval → done（需要审批的阶段）

## 重试规则
- quality-gate fail 时 retry_count++
- retry_count <= 3：修正重做
- retry_count > 3：通知人工介入

## 初始化新项目
从 `templates/claude-code-project/workspace/pipeline.json` 复制到新项目，填入项目名和创建时间。
