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
    "implementation": {
      "status": "pending",
      "sub_stage": "",
      "loop_count": 0,
      "max_loops": 5
    }
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

需要审批的阶段（v2.1 含 Review Loop）：
```
pending → in_progress → self_reviewing → peer_reviewing → waiting_review → done
```

- `self_reviewing`：Claude Code 正在执行自检循环（Review Loop 第一关）
- `peer_reviewing`：Claude Code 正在执行评审团交叉评审（Review Loop 第二关+第三关）
- `waiting_review`：自检和评审团完成，等待架构师审批

实现阶段（含自动闭环）：
```
pending → coding → code_review → arch_acceptance → testing → pm_acceptance → done
```

每个子阶段可回退到 coding（修复后重新走流程），由 Claude Code 内部 subagent 机制自动编排。

其他不需要审批的阶段：
```
pending → in_progress → done
```

## Review Loop 集成

Claude Code 退出后，OpenClaw 检查 `{project_path}/workspace/checklist.json`：
1. 所有 `passes: true` → 状态推进到 `waiting_review`，通知用户审批
2. 有 `passes: false` 项 → 状态仍为 `waiting_review`，但通知用户时标注未通过项
3. `workspace/review-log.md` 作为自检过程记录，审批时可供参考

审批后反馈沉淀：
- 审批反馈写入 `{project_path}/workspace/memory.md`
- 通用偏好写入 `workspace-aifd/memory/preferences.md`（作为未来检查清单的额外规则）

## 增量特性管理

当收到增量需求时，OpenClaw 执行：

### 初始化
1. 生成 feature_id（格式：F001、F002...递增）
2. 创建 feature branch：`git checkout -b feature/{feature_id}-{name} main`
3. 创建增量文档目录（**必须使用 project_write.sh 确保权限归 claw**）：
   `skills/pipeline/project_write.sh {project_path} mkdir docs/specs/features/{feature_id}`
4. 设置 pipeline.json（同样通过 project_write.sh 或操作后 chown）：
   - `is_incremental: true`
   - `feature_id`、`feature_name`、`feature_branch`
   - `base_branch: "main"`
5. Git commit + 启动 Claude Code

### 合并
Close Loop 全部通过后：
1. 增量文档追加到全量 specs（标注 feature_id）
2. 合并记录写入 `docs/specs/features/{feature_id}/merged.md`
3. `git checkout main && git merge {feature_branch}`
4. `git branch -d {feature_branch}`
5. 通知用户完成

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
