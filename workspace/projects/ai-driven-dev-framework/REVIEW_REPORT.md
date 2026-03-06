# AIFD 技术方案 Review 报告

> 评审日期：2026-03-05  
> 评审范围：AIFD_TECHNICAL_PROPOSAL.md v0.1 draft  
> 参考：CROSS_SESSION_ANALYSIS.md

---

## 总体评价

方案架构思路清晰，OpenClaw（战略层）+ Claude Code（战术层）的分层设计合理，但跨 session 状态管理严重缺失，多处设计停留在"原则"层面缺少具体机制。**评分：6/10**

---

## Must-Fix（必须修改）

### MF-1: 缺少跨 Session 状态管理（对应跨会话分析 G1, G3）

**问题**：方案完全没有 session state snapshot 和 pipeline state machine。`workspace/` 下的 JSON 文件是追加式日志，没有统一的状态视图。多阶段流转（P1→P6）的当前位置、完成状态、回退路径全是隐式的。

**影响**：Phase 2 起就无法可靠运行。上下文构建器不知道"从哪里继续"。

**修改**：新增 §4.5 跨 Session 状态管理，包含：
- `workspace/pipeline.json`：feature 级流水线状态机（各阶段状态、子任务列表、回退历史）
- `workspace/sessions/`：每个 session 的结构化快照（输入、输出、状态、pending_work）
- 阶段流转规则和跨阶段回退逻辑

CROSS_SESSION_ANALYSIS.md §3.1 和 §3.2 的设计可直接采用。

### MF-2: Agent Teams session resume 限制未提及（对应跨会话分析 G2）

**问题**：Agent Teams 的 teammates 是 in-process 子进程，session 结束后状态全部丢失。方案完全没提到这个限制，也没有应对设计。对 P4 编码和 P5 测试这类需要多 session 迭代的阶段影响很大。

**影响**：如果不处理，编码阶段每次 session 都要从零理解上下文，效率低且结果不稳定。

**修改**：
1. §13 风险表新增此风险项
2. §4 协同机制明确说明"每次 spawn 都是全新 Team"
3. CLAUDE.md 模板（§7）增加"Session 连续性"段落，包含上一 session 的已完成产物和未完成工作
4. §14 新增决策 D6："每次 session 都是新进程，因为 Agent Teams teammates 无法 resume"

### MF-3: 大任务拆分机制空白（对应跨会话分析 G4）

**问题**：P4 编码对中等复杂度功能，30 分钟单 session 大概率不够。方案只在 §13 风险应对中提了"大任务拆分为子任务"一句话，没有任何具体设计。

**影响**：Phase 3 起编码阶段无法可靠执行。

**修改**：新增 §6.5 或独立章节描述任务拆分机制：
- OpenClaw 用轻量模型分析 tech spec，拆分为子任务（每个 ≤25min 工作量）
- 子任务含明确产物边界（文件列表）和依赖关系
- 按拓扑排序编排执行
- 写入 pipeline.json 的 sub_tasks 字段

### MF-4: Hooks 机制描述与 Claude Code 实际不符

**问题**：§8 的 Hook 脚本接收 `$1`（TEAMMATE_NAME）、`$2`（IDLE_REASON）等参数，但 Claude Code Hooks 的实际调用方式是通过**环境变量和 stdin**传递上下文，不是命令行参数。TeammateIdle 和 TaskCompleted 是实验性 hook 类型，其触发方式和参数传递需要核实官方文档。

**影响**：Phase 1 就会踩坑，Hook 脚本无法正常工作。

**修改**：查阅 Claude Code Hooks 官方文档，修正 Hook 脚本的参数接收方式。建议 Phase 1 优先验证 Hook 的实际行为，用最简单的脚本测试参数传递。

---

## Should-Fix（建议修改）

### SF-1: 幂等/恢复策略缺少具体机制（对应跨会话分析 G5）

**问题**：§13 说"每个 session 做幂等设计，失败可重试"，但没有具体方案。30 分钟超时 kill 后半成品代码怎么办？重试怎么避免重复工作？

**修改**：采用 git checkpoint 方案：
- Pre-session: `git commit` 存档
- 成功: `git commit` 保存产物
- 失败/超时: `git reset --hard` 回到 checkpoint，或检查部分产物是否可用
- 连续失败 3 次升级到人工

### SF-2: workspace/ 文件无清理机制（对应跨会话分析 G6）

**问题**：`task-results.json`、`team-status.json`、`blockers.json` 都是追加写入，随 session 增多会膨胀，影响上下文构建性能。

**修改**：每个 feature 完成后归档到 `workspace/archive/{feature_id}/`，只保留最近 N 个 session 的详细记录。

### SF-3: 质量把关 5 阶段流程过重

**问题**：§9.2 的多模型 Review 流程有 5 个阶段（并行生成 → 自审 → 合并 → 交叉验证 → 最终输出），至少需要 5 次 LLM 调用。对于每个阶段的每次质量门都走这个流程，成本和延迟都很高。

**修改**：
- Phase 1-3 用 2 阶段简化版（并行 Review → 合并），够用就行
- 只在关键节点（P3 技术设计、P4 编码完成）走完整 5 阶段
- 需求分析、产品设计等文档类产物用单模型 Review 即可
- §12 实施路径已经提到"Phase 1-2 用单模型验证"，但 §9 的描述让人以为一上来就是 5 阶段

### SF-4: Agent 定义文件过于简单

**问题**：附录 A 的 agent 定义只有基本的 Role/Skills/Instructions/Constraints。Claude Code Agent Teams 的 agent 定义还需要配置 teammates 之间的通信规则、任务依赖、共享资源等。

**修改**：补充 agent 定义的完整字段，特别是：
- `teammates`: 可通信的其他 agent 列表
- `shared_resources`: 共享文件/目录
- `escalation`: 遇到阻塞时的上报规则

### SF-5: 多 feature 并行未设计（对应跨会话分析 G8）

**问题**：方案隐含假设一次只做一个 feature。实际场景中可能 feature001 在 P4 阶段，feature002 已经提了新需求进入 P1。

**修改**：
- `pipeline.json` 改为 `workspace/pipelines/{feature_id}.json`，每个 feature 独立状态机
- OpenClaw 编排层增加跨 feature 的资源调度逻辑
- 暂不需要复杂设计，Phase 4 再处理即可，但架构上预留

---

## Nice-to-Have（可选优化）

### NH-1: 增加成本估算模型

方案提到成本风险但没有量化。建议补充：每个阶段的预估 token 消耗、每次 Review 的成本、一个中等功能全流程的总成本估算。有助于决策投入产出比。

### NH-2: 增加可观测性设计

当前只有 workspace/ 下的 JSON 文件记录状态。建议增加：
- 执行时间线可视化（Gantt 图或简单日志 dashboard）
- token 消耗追踪
- 成功率/重试率统计

用 OpenClaw heartbeat 定期汇总即可，不需要额外基础设施。

### NH-3: 知识库冷启动策略

§3 定义了 `docs/knowledges/` 的目录结构，但这些知识从哪来？建议：
- Phase 1 用最小知识库启动（1 个编码规范 + 1 个 API 设计模板）
- 每次 session 的经验自动归纳写入知识库（§10 已有此设计，但没强调冷启动）
- 不要试图在项目开始前就填满知识库

### NH-4: 架构图用 Mermaid 替代 ASCII Art

ASCII 图在不同终端和编辑器中对齐容易出问题。Mermaid 在飞书、GitHub 等平台都能渲染。

---

## 具体修改建议

### 1. 新增 §4.5 跨 Session 状态管理

直接采纳 CROSS_SESSION_ANALYSIS.md §3.1（Session State Snapshot）和 §3.2（Pipeline State Machine）的设计，作为方案新章节。核心内容：

```markdown
### 4.5 跨 Session 状态管理

#### 设计原则
- Session 无状态：每次 Claude Code session 视为无状态执行单元
- 状态外置：通过 workspace/pipeline.json + workspace/sessions/ 持久化
- 幂等可重试：git checkpoint 保证任意 session 可安全重试

#### 关键文件
- `workspace/pipeline.json` — feature 级流水线状态
- `workspace/sessions/{session-id}.json` — 单次 session 快照
- `workspace/sessions/latest.json` — 最新 session 状态

#### Session 生命周期
1. Pre-session: git checkpoint → 读取 pipeline state → 构建 CLAUDE.md
2. In-session: Claude Code 执行
3. Post-session: 验证产物 → 更新 session/pipeline state → 同步记忆
4. Recovery: 根���退出状态决定重试/拆分/升级
```

### 2. 修改 §7 CLAUDE.md 模板

在"上下文"段之前增加：

```markdown
## Session 连续性
### 上一 Session 状态
- Session ID: {session_id}
- 状态: {completed|partial|retry}
- 已完成: {已产出的文件列表}
- 未完成: {pending_work 详细描述}

### 当前 Session 范围
- 子任务: {sub_task_id}
- 预期产物: {文件列表}
- 时间预算: {estimated_minutes} 分钟
```

### 3. 修改 §8 Hooks 脚本

当前脚本用 `$1` `$2` 接收参数，需要改为从 stdin/环境变量获取。Phase 1 第一个验证项应该是测试 Hook 的实际行为。暂时可以改为：

```bash
#!/bin/bash
# .claude/hooks/TaskCompleted.sh
# 注意：需要根据 Claude Code Hooks 实际 API 调整参数获取方式
# Phase 1 验证项：确认 Hook 的触发方式和参数传递

# 读取 stdin 获取事件数据（待验证）
EVENT_DATA=$(cat)

# 写入状态文件
echo "$EVENT_DATA" >> workspace/hook-events.json
```

### 4. 修改 §13 风险表

新增一行：

| 风险 | 影响 | 概率 | 应对 |
|------|------|------|------|
| **Agent Teams teammates 无法跨 session resume** | 每次 session 都是全新 Team，需要从文件重建上下文 | 确定 | CLAUDE.md 包含 session 连续性信息；大任务拆分为原子子任务；产物实时写入文件系统 |

### 5. 修改 §14 决策记录

新增：

| # | 决策 | 理由 | 替代方案 |
|---|------|------|---------|
| D6 | 每次 session 都是新 Claude Code 进程 | Agent Teams teammates 无法 resume；新 session + 文件传递更可靠 | --resume 模式（仅 Team Lead 可 resume，不含 teammates） |
| D7 | git checkpoint 实现幂等 | 简单可靠；支持任意回滚；不依赖 Claude Code 内部机制 | 文件级 snapshot/备份 |
| D8 | 大任务拆分由 OpenClaw 完成 | 拆分是战略决策，属于指挥官职责；避免浪费执行层 context | 在 Claude Code Team 内部拆分 |

### 6. 修改 §12 实施路径

Phase 1 增加验证项：
- [ ] **验证 Hook 实际参数传递方式**（优先级最高，阻塞 Hook 设计）
- [ ] 实现 git checkpoint 机制（pre-session commit + post-session commit/reset）
- [ ] 引入 session state 文件（workspace/sessions/）

Phase 2 增加：
- [ ] 实现 pipeline.json 状态机（单 feature，P1 阶段）
- [ ] 实现 session 恢复逻辑（正常/超时/崩溃三种路径）

Phase 3 增加：
- [ ] 实现大任务拆分（P4 编码阶段子任务化）
- [ ] pipeline 状态机扩展到 P1→P3

---

## 附：跨会话分析覆盖度检查

| 跨会话分析问题 | 编号 | 主方案是否已覆盖 | Review 建议 |
|---------------|------|-----------------|------------|
| 缺少 session state snapshot | G1 | ❌ 未覆盖 | MF-1 |
| Agent Teams resume 限制 | G2 | ❌ 未覆盖 | MF-2 |
| 缺少 pipeline state machine | G3 | ❌ 未覆盖 | MF-1 |
| 大任务拆分机制空白 | G4 | ❌ 未覆盖 | MF-3 |
| 幂等/恢复策略无具体机制 | G5 | ⚠️ 只有原则 | SF-1 |
| workspace 文件无清理机制 | G6 | ❌ 未覆盖 | SF-2 |
| 跨阶段回退路径未定义 | G7 | ❌ 未覆盖 | MF-1（含回退） |
| 多 feature 并行未设计 | G8 | ❌ 未覆盖 | SF-5 |

**结论**：跨会话分析提出的 8 个问题，主方案全部未覆盖或仅有原则性描述。这是当前方案最大的短板。

---

*Review 完成。建议优先处理 MF-1 ~ MF-4，这四个问题直接影响 Phase 1 的可行性。*
