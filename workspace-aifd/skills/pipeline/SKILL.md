# pipeline — 流水线管理（v2）

## 用途
管理研发流水线状态。初始化、推进阶段、管理会话 ID。

## 参数
- `project_path`：业务项目的绝对路径

## 状态文件
`{project_path}/workspace/pipeline.json`

### v2 结构
```json
{
  "project": "project-id",
  "created_at": "ISO时间戳",
  "request_id": "REQ-YYYYMMDD-NNN",
  "feature_id": "",
  "session_id": "UUID — Claude Code 持久会话 ID",
  "current_stage": "requirements",
  "stages": {
    "requirements": { "status": "pending", "reviewed": false },
    "product": { "status": "pending", "reviewed": false },
    "tech": { "status": "pending", "reviewed": false },
    "implementation": { "status": "pending" },
    "testing": { "status": "pending" }
  }
}
```

## 阶段定义

| 阶段 ID | 需要审批 | 说明 |
|---------|---------|------|
| requirements | ✅ | Claude Code 自主完成需求分析 |
| product | ✅ | Claude Code 自主完成产品设计 |
| tech | ✅ | Claude Code 自主完成技术设计 |
| implementation | ❌ | Claude Code 自主完成编码实现 |
| testing | ❌ | Claude Code 自主完成测试验证 |

## 状态流转

需要审批的阶段：
```
pending → in_progress → waiting_review → done
```

不需要审批的阶段：
```
pending → in_progress → done
```

## 会话管理

- 每个需求对应一个 `session_id`（UUID）
- 首次启动时生成并记录到 pipeline.json
- 审批后通过 `--resume {session_id}` 恢复
- 如果会话丢失，记录新 session_id

## 初始化新项目

使用统一初始化脚本：

```bash
/root/.openclaw/workspace-aifd/skills/pipeline/init_project.sh \
  <project_id> <project_name> <project_path> <tech_stack> [domain] [nfr] [boundary]
```
