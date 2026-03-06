# AIFD 跨会话问题分析

> 评审日期：2026-03-05  
> 评审范围：OpenClaw ↔ Claude Code 协同的跨 session 连续性

---

## 1. 问题逐项分析

### 1.1 一次 session 完成后，下次 session 如何继续？

**当前方案处理情况**：方案通过文件系统传递上下文（CLAUDE.md + docs/ + workspace/），记忆同步回写到 MEMORY.md 和 memory/ 日志。下一次 session 前由上下文构建器重新生成 CLAUDE.md。

**评估**：基本框架正确，但缺乏**结构化的 session 状态持久化**。当前设计中 `workspace/task-results.json`、`workspace/blockers.json` 是追加式日志，没有一个统一的 **session state snapshot**，导致下次构建上下文时需要从散落的文件中拼凑状态。

**缺陷**：
- 没有定义 session 之间的**状态交接协议**——哪些信息必须传递、以什么格式
- `workspace/` 下的 JSON 文件是追加式的，没有清理/归档机制，随 session 增多会膨胀
- CLAUDE.md 的"已知问题"段落是可选的，没有强制要求包含上一 session 的未完成项

### 1.2 Agent Teams session resume 限制的影响

**当前方案处理情况**：方案未提及此限制。

**评估**：这是一个**被完全忽略的关键问题**。Claude Code Agent Teams 的 teammates 是 in-process 的子进程，session 结束后 teammates 状态全部丢失。这意味着：

- 每次 `sessions_spawn` 都是全新的 Team，无法"继续上次 BE Agent 的工作"
- 如果 P4 编码阶段 BE Agent 写了一半代码，session 中断后，新 session 的 BE Agent 需要从产物文件重新理解上下文
- Team Lead 的任务分配决策、teammates 之间的消息历史全部丢失

**影响**：中等偏高。对于可以原子化完成的阶段（P1 需求分析）影响小；对于需要迭代的阶段（P4 编码、P5 测试）影响大。

### 1.3 OpenClaw 调 Claude Code 是新 session 还是复用？

**当前方案处理情况**：方案使用 `sessions_spawn` + `--print` 非交互模式，每次都是新 session。

**评估**：当前设计是正确的——**每次都是新 session 是唯一可靠的方式**。原因：

1. `--print` 模式本身就是 one-shot
2. Claude Code CLI 的 `--resume` 功能虽然存在，但 Agent Teams 模式下 teammates 无法 resume（只有 Team Lead 的对话历史可以 resume）
3. OpenClaw 的 `sessions_spawn` 是 fork 出新进程，无法复用之前的进程

**结论**：新 session 是正确选择，但需要为此设计更完善的**状态传递机制**。

### 1.4 长流程（P1→P6）跨多 session 的上下文传递

**当前方案处理情况**：
- 每个阶段的产物写入 `docs/featureXXX-specs/`
- 下一阶段的上下文构建器加载上一阶段产物
- CLAUDE.md 动态生成时包含项目状态

**评估**：**��件级传递是可行的，但缺乏流程级状态管理**。

**缺陷**：
- 没有一个 **pipeline state machine**——当前处于哪个阶段、每个阶段的完成状态、阶段间依赖关系都是隐式的
- 如果 P3 技术设计 Review 不通过导致回退到 P2 修改产品设计，当前方案没有描述这种**跨阶段回退**的处理
- 多个 feature 并行时（feature001 在 P4，feature002 在 P1），没有 feature 级别的状态隔离

### 1.5 单阶段需要多次 session（大功能拆分）

**当前方案处理情况**：方案提到"大任务拆分为子任务"（§13 风险应对），但没有具体的拆分和编排机制。

**评估**：这是一个**设计空白**。P4 编码阶段对于中等复杂度功能，一次 30 分钟的 Claude Code session 很可能不够。需要：

1. 任务拆分策略：OpenClaw 如何将一个大的编码任务拆分为多个 session？
2. 中间状态管理：第 1 个 session 写了后端 API，第 2 个 session 写前端，如何确保一致性？
3. 依赖管理：子任务之间有顺序依赖（如先写 API 再写前端调用），如何编排？

### 1.6 Session 中断/失败后的恢复策略

**当前方案处理情况**：§13 提到"每个 session 做幂等设计，失败可重试"，但没有具体设计。

**评估**：**只有原则没有机制**。需要回答：

- 30 分钟超时被 kill 后，部分写入的文件如何处理？（可能有半成品代码）
- 重试时如何避免重复工作？（幂等的具体实现）
- 连续失败 N 次后的升级策略？（当前只有 ReAct 3 轮限制，但没有针对 session 级失败的策略）

---

## 2. 缺陷汇总

| # | 缺陷 | 严重度 | 影响阶段 |
|---|------|--------|---------|
| G1 | 缺少结构化的 session state snapshot | 高 | 全部 |
| G2 | 完全忽略 Agent Teams session resume 限制 | 高 | P4, P5 |
| G3 | 缺少 pipeline state machine | 高 | P1→P6 流转 |
| G4 | 大任务拆分和编排机制空白 | 高 | P4 |
| G5 | 幂等/恢复策略只有原则没有机制 | 中 | 全部 |
| G6 | workspace/ 下状态文件无清理/归档机制 | 低 | 长期运行 |
| G7 | 跨阶段回退路径未定义 | 中 | P2↔P3 |
| G8 | 多 feature 并行的状态隔离未设计 | 中 | 扩展场景 |

---

## 3. 解决方案

### 3.1 Session State Snapshot（解决 G1, G5）

引入 `workspace/sessions/` 目录，每次 session 前后写入结构化状态：

```
workspace/sessions/
├── session-2026-03-05-001.json    # 历史 session
├── session-2026-03-05-002.json
└── latest.json                    # 软链或最新状态的副本
```

**Session State 结构**：

```json
{
  "session_id": "2026-03-05-001",
  "feature": "feature001",
  "pipeline_stage": "P4",
  "sub_task": "backend-api-user-crud",
  "status": "completed|failed|timeout|partial",
  "started_at": "2026-03-05T10:00:00Z",
  "ended_at": "2026-03-05T10:25:00Z",
  "artifacts_produced": [
    "backend/src/api/users.py",
    "backend/src/models/user.py"
  ],
  "artifacts_validated": true,
  "pending_work": [
    "backend/src/api/users.py 中的 DELETE 端点未实现"
  ],
  "error": null,
  "retry_count": 0,
  "context_hash": "sha256:abc123..."
}
```

**OpenClaw 在每次 spawn 前**：
1. 读取 `latest.json`
2. 如果上一 session 是 `partial` 或 `failed`，将 `pending_work` 注入 CLAUDE.md 的"当前任务"段
3. 如果是新任务，归档 `latest.json` 并创建新的

### 3.2 Pipeline State Machine（解决 G3, G7）

引入 `workspace/pipeline.json`：

```json
{
  "feature": "feature001",
  "current_stage": "P4",
  "stages": {
    "P1": {"status": "done", "completed_at": "...", "artifacts": ["docs/feature001-specs/requirements.md"]},
    "P2": {"status": "done", "completed_at": "...", "artifacts": ["docs/feature001-specs/product.md"]},
    "P3": {"status": "done", "completed_at": "...", "artifacts": ["docs/feature001-specs/tech.md"]},
    "P4": {"status": "in_progress", "sub_tasks": [
      {"id": "backend-api", "status": "done"},
      {"id": "frontend-pages", "status": "in_progress", "current_session": "2026-03-05-003"},
      {"id": "frontend-state", "status": "todo"}
    ]},
    "P5": {"status": "pending"},
    "P6": {"status": "pending"}
  },
  "rollback_history": []
}
```

**阶段流转规则**（OpenClaw 上下文构建器实现）：

```python
def next_action(pipeline):
    stage = pipeline["stages"][pipeline["current_stage"]]
    
    if stage["status"] == "in_progress":
        # 找到第一个未完成的 sub_task
        for task in stage.get("sub_tasks", []):
            if task["status"] in ("todo", "in_progress", "failed"):
                return {"action": "spawn_session", "task": task}
        # 所有 sub_task 完成 → 触发质量门
        return {"action": "quality_gate", "stage": pipeline["current_stage"]}
    
    if stage["status"] == "review_failed":
        if stage.get("retry_count", 0) >= 3:
            return {"action": "escalate_to_human"}
        return {"action": "retry_with_feedback", "feedback": stage["review_feedback"]}
    
    if stage["status"] == "done":
        next_stage = get_next_stage(pipeline["current_stage"])
        return {"action": "advance", "to": next_stage}
```

**跨阶段回退**：

```python
def rollback(pipeline, target_stage, reason):
    current = pipeline["current_stage"]
    pipeline["rollback_history"].append({
        "from": current, "to": target_stage,
        "reason": reason, "timestamp": now()
    })
    # 将 target_stage 及之后的阶段标记为需要重做
    for stage in stages_from(target_stage):
        pipeline["stages"][stage]["status"] = "needs_redo"
    pipeline["current_stage"] = target_stage
```

### 3.3 大任务拆分机制（解决 G4）

在 OpenClaw 上下文构建阶段，增加**任务拆分步骤**：

```python
def split_coding_task(tech_spec, pipeline):
    """
    用轻量模型分析 tech_spec，拆分为可独立执行的子任务。
    每个子任务应满足：
    1. 单次 session（≤25min 工作量）可完成
    2. 产物边界清晰（具体文件列表）
    3. 依赖关系明确
    """
    prompt = f"""
    分析以下技术设计，将编码任务拆分为独立子任务：
    {tech_spec}
    
    要求：
    - 每个子任务产出明确的文件列表
    - 标注依赖关系（哪些子任务必须先完成）
    - 估算复杂度（S/M/L）
    
    输出 JSON 格式：
    [{{"id": "...", "title": "...", "files": [...], "depends_on": [...], "size": "S|M|L"}}]
    """
    sub_tasks = call_lightweight_model(prompt)
    
    # 按依赖拓扑排序
    ordered = topological_sort(sub_tasks)
    
    # 写入 pipeline
    pipeline["stages"]["P4"]["sub_tasks"] = ordered
    return ordered
```

**子任务间上下文传递**：每个子任务的 CLAUDE.md 中增加：

```markdown
## 已完成的相关子任务
- [backend-api] 已完成，产物：backend/src/api/users.py
  - 关键接口：GET/POST/PUT /api/users, 认证用 JWT
- [backend-models] 已完成，产物：backend/src/models/user.py
  - User model 字段：id, email, name, hashed_password, created_at

## 当前子任务
- [frontend-pages] 实现用户管理页面
  - 依赖上述 API 接口
  - 输出到 frontend/src/pages/users/
```

### 3.4 Session 恢复策略（解决 G2, G5）

```
Session 结束
    │
    ▼
检查退出状态
    │
    ├── 正常退出（exit 0）
    │   ├── 检查产物完整性
    │   │   ├── 完整 → status=completed
    │   │   └── 不完整 → status=partial, 记录 pending_work
    │   └── 继续流程
    │
    ├── 超时（30min）
    │   ├── 检查已产出文件的完整性
    │   │   ├── 文件可用（语法正确）→ status=partial
    │   │   └── 文件损坏 → status=failed, git checkout 恢复
    │   └── 用更小粒度重新拆分剩余工作
    │
    └── 异常退出（crash/error）
        ├── git diff 检查 working tree
        │   ├── 有改动 → 暂存到 stash，标记 status=failed
        │   └── 无改动 → 直接重试
        └── retry_count++ → 超过 3 次则 escalate
```

**幂等保证**：

1. 每次 session 前 `git add -A && git commit -m "pre-session checkpoint"`
2. 失败恢复时可 `git reset --hard` 到 checkpoint
3. 成功后 `git commit -m "session-XXX: {task_title}"`

```python
def handle_session_end(session_state, exit_code, pipeline):
    if exit_code == 0:
        # 验证产物
        expected = session_state["expected_artifacts"]
        actual = check_artifacts(expected)
        if all_valid(actual):
            session_state["status"] = "completed"
            advance_pipeline(pipeline, session_state["sub_task"])
        else:
            session_state["status"] = "partial"
            session_state["pending_work"] = diff(expected, actual)
            # 下次 session 只做剩余部分
    
    elif exit_code == -1:  # timeout
        session_state["status"] = "timeout"
        salvage = salvage_partial_work()
        if salvage:
            session_state["artifacts_produced"] = salvage
            # 重新拆分剩余工作为更小粒度
            remaining = compute_remaining(session_state)
            re_split(pipeline, remaining, max_size="S")
        else:
            git_reset_to_checkpoint()
            session_state["retry_count"] += 1
    
    else:  # crash
        git_stash_or_reset()
        session_state["status"] = "failed"
        session_state["error"] = capture_error_log()
        session_state["retry_count"] += 1
        
        if session_state["retry_count"] > 3:
            escalate_to_human(session_state)
```

### 3.5 Workspace 清理机制（解决 G6）

```python
def cleanup_workspace(workspace_path):
    """每次 pipeline 完成后（或定期）清理"""
    # 1. 归档已完成 feature 的 session 记录
    archive_dir = f"workspace/archive/{feature_id}/"
    move("workspace/sessions/*.json", archive_dir)
    
    # 2. 清理追加式日志文件
    for f in ["task-results.json", "team-status.json", "blockers.json"]:
        summarize_and_archive(f, archive_dir)
    
    # 3. 保留最近 N 个 session 的详细记录
    retain_recent(archive_dir, n=10)
```

---

## 4. 需要补充到方案的设计内容

### 4.1 新增章节：§4.5 跨 Session 状态管理

```markdown
### 4.5 跨 Session 状态管理

#### 设计原则
1. **Session 无状态**：每次 Claude Code session 视为无状态的执行单元
2. **状态外置**：所有状态通过文件系统持久化（workspace/pipeline.json + workspace/sessions/）
3. **幂等可重试**：任何 session 可安全重试，通过 git checkpoint 保证
4. **增量推进**：大任务拆分为子任务，每个子任务一个 session，失败不影响已完成部分

#### Session 生命周期
1. Pre-session：checkpoint (git commit) → 读取 pipeline state → 构建 CLAUDE.md
2. In-session：Claude Code 执行，产物写入文件系统
3. Post-session：验证产物 → 更新 session state → 更新 pipeline state → 同步记忆
4. Recovery：根据退出状态决定重试/拆分/升级
```

### 4.2 修改 §6 ReAct-Loop：增加 session 级重试

当前 ReAct-Loop 只处理质量 Review 不通过的情况。需要增加 **session 级别的重试逻辑**（区别于 Review 重试）：

```
┌─────────────────────────────────────────────────┐
│                  Session 执行层                  │
│                                                 │
│   Pre-session → Spawn → Post-session            │
│       │                      │                  │
│       │              ┌───────┴────────┐         │
│       │          成功完成           失败/超时     │
│       │              │                │         │
│       │              ▼                ▼         │
│       │        质量 Review      恢复/重试        │
│       │         (ReAct)        (Session Retry)  │
│       │           │                  │          │
│       │     ┌─────┴─────┐    ┌──────┴──────┐   │
│       │    通过       不通过  重试≤3    重试>3   │
│       │     │          │      │         │      │
│       │   下一步    修正重做  重新spawn  人工    │
│       │              (ReAct轮次)                │
└─────────────────────────────────────────────────┘
```

### 4.3 修改 §7 CLAUDE.md：增加连续性段落

CLAUDE.md 模板增加：

```markdown
## Session 连续性
### 上一 Session 状态
- Session ID: {session_id}
- 状态: {completed|partial|retry}
- 已完成: {已产出的文件列表}
- 未完成: {pending_work 详细描述}

### 当前 Session 范围
- 子任务: {sub_task_id}
- 目标: {具体目标，不含已完成部分}
- 预期产物: {文件列表}
- 时间预算: {estimated_minutes} 分钟
```

### 4.4 新增：§14 关键设计决策补充

| # | 决策 | 理由 |
|---|------|------|
| D6 | 每次 session 都是新的 Claude Code 进程 | Agent Teams teammates 无法 resume；新 session + 文件传递更可靠 |
| D7 | 用 git checkpoint 实现幂等 | 简单可靠；支持任意回滚；不依赖 Claude Code 内部机制 |
| D8 | pipeline state 用单文件 JSON 而非数据库 | 与方案整体的文件系统通信风格一致；简单场景足够；未来可迁移到 DB |
| D9 | 大任务拆分由 OpenClaw 用轻量模型完成 | 拆分是战略决策，属于 OpenClaw 职责；避免浪费 Claude Code 的 context |

---

## 5. 总结

当前方案的**文件系统传递上下文**思路是正确的，但对跨 session 连续性的设计严重不足。核心缺失：

1. **Session State Snapshot**——需要结构化记录每个 session 的输入输出状态
2. **Pipeline State Machine**——需要显式管理 P1→P6 的流转、回退、子任务拆分
3. **恢复策略**——需要 git checkpoint + 产物验证 + 分级重试

建议在 Phase 1（基础验证）中就引入 session state 和 git checkpoint 机制，避免后期补救成本过高。Pipeline state machine 可在 Phase 2-3 逐步完善。
