# AIFD 框架可扩展性评估

> 评估版本：AIFD_TECHNICAL_PROPOSAL.md v0.2
> 评估日期：2026-03-05

## 总体评价

方案架构分层合理，但当前是一个**面向单一场景的端到端设计**，不是一个可复用框架。可扩展性评分：**5/10**。

核心问题：方案把「软件研发全流程」这个具体业务场景的逻辑（P1-P6 阶段、PM/Arch/BE/FE/QA/DevOps 角色、具体的 pipeline 状态机）硬编码在框架设计中，新业务项目接入成本高。

---

## 逐项评估

### 要求 1: OpenClaw 不变性

**评估：部分满足**

**符合的部分：**
- OpenClaw 作为「战略层指挥官」的定位是通用的——上下文构建、质量把关、记忆管理、IM 通知这些能力本身不绑定业务
- 记忆体系（MEMORY.md、memory/）是通用机制
- ReAct-Loop 的「执行→评估→修正」模式是通用的

**违反的部分：**
- §4.5 的 Pipeline State Machine 把 P1-P6 六个阶段和具体的流转规则写死了。换一个非软件研发项目（比如内容创作、数据分析），这套状态机完全不适用
- §9.1 Review 触发阶段表把 requirements.md、product.md、tech.md 等具体产物和 Review 类型绑定
- §11 整个端到端工作流是纯软件研发流程
- `workspace-aifd/skills/` 下的 context-builder、quality-gate、memory-sync 看起来是框架级能力，却放在 AIFD 专用目录下——边界模糊

**修改建议：**
1. 将 Pipeline State Machine 抽象为**通用状态机引擎**，阶段定义通过项目配置文件（如 `project/pipeline-config.yaml`）声明
2. Review 触发规则从代码移到配置：每个阶段配置 review_level、review_criteria
3. context-builder、quality-gate、memory-sync 如果是通用能力，应该作为 OpenClaw skill 发布，不放在 AIFD 目录下

---

### 要求 2: Claude Code 能力不变 / 内容可变

**评估：满足**

**符合的部分：**
- Claude Code 层确实只用了通用能力：Agent Teams、CLAUDE.md、Hooks、文件系统读写
- 所有业务内容通过 `docs/specs/`、`docs/knowledges/`、CLAUDE.md 动态注入
- Team 角色不是预定义配置，而是 CLAUDE.md 中的自然语言描述，Team Lead 自行创建
- 新项目只需换 docs 内容和 CLAUDE.md 模板

**违反的部分：**
- 附录 A 的 Team 配置示例虽然只是示例，但 §11.2 各阶段描述中把 PM/Arch/BE/FE/QA/DevOps 角色写成了固定流程的一部分。这不是 Claude Code 层的问题，是上层编排的问题

**修改建议：**
- 当前设计在这一维度基本合格，无重大改动需求
- 建议将附录 A 的示例标注为「软件研发场景示例」，明确这不是框架固有的角色定义

---

### 要求 3: 双生态可扩展

**评估：部分满足**

**符合的部分：**
- OpenClaw 侧：提到了 `skills/` 目录用于扩展
- Claude Code 侧：`.claude/commands/`、`.claude/hooks/`、CLAUDE.md 都是标准扩展点
- 方案中提到的 context-builder、quality-gate 等可以作为 skill 实现

**违反的部分：**
- **OpenClaw skill 和 Claude Code skill/agent 的边界不清晰**。方案中没有明确定义：
  - 哪些逻辑应该作为 OpenClaw skill？（上下文构建？质量评估？任务拆分？）
  - 哪些应该作为 Claude Code 的 commands/hooks？
  - 两者如何协作？
- §3 项目结构中 `.openclaw/workspace-aifd/skills/` 和 `.claude/commands/` 并存，但没有设计原则说明什么放哪里
- 没有 skill 接口规范——context-builder skill 的输入输出是什么？quality-gate skill 怎么配置评估标准？

**修改建议：**
1. 明确边界原则：
   - **OpenClaw skill**：跨 session 的编排逻辑（上下文构建、质量评估、记忆同步、任务拆分）
   - **Claude Code 扩展**：session 内的执行辅助（hooks 做产物记录、commands 做常用操作快捷方式）
2. 为 OpenClaw skill 定义接口规范（输入/输出/配置项），使其可独立开发和复用
3. 增加一个「扩展点清单」章节，列出所有可扩展的位置和扩展方式

---

### 要求 4: 少代码 / 配置驱动

**评估：不满足**

**符合的部分：**
- CLAUDE.md 动态生成思路正确——通过模板 + 数据生成，不需要写代码
- 上下文裁剪策略用优先级配置
- Hook 脚本是简单 shell，不算重量级代码

**违反的部分：**
- §4.5 的阶段流转规则用 **Python 伪代码** 描述了 `next_action()` 和 `rollback()` 函数——这意味着需要写代码实现状态机
- §6.5 大任务拆分流程需要编程实现
- §8.2 Hook 脚本需要编写
- §9.3 多模型 Review 的并行+合并流程需要编排代码
- §10.2 记忆回写流程需要编程
- 整个 ReAct-Loop 控制器（§6）需要编程实现

**核心矛盾**：方案描述的 OpenClaw 侧能力（上下文构建器、质量把关引擎、ReAct 控制器、Pipeline 状态机、记忆同步回写器）目前都不是 OpenClaw 内置功能，需要**从零开发**。

**修改建议：**
1. **评估 OpenClaw 现有能力**：哪些已经内置？哪些可以通过现有 skill/配置实现？明确列出需要新开发的部分
2. **Pipeline 状态机配置化**：
   ```yaml
   # pipeline-config.yaml
   stages:
     - id: requirements
       review: {level: simple, model: glm}
       human_approval: true
     - id: design
       review: {level: full, models: [claude, glm]}
       human_approval: true
     - id: coding
       review: {level: full, models: [claude, glm]}
       split_strategy: auto
   ```
3. **CLAUDE.md 模板化**：用 Jinja2/Mustache 模板而非代码生成
4. **ReAct-Loop 声明式配置**：max_rounds、timeout、评估标准都配置化，循环逻辑由框架引擎处理
5. 如果 OpenClaw 当前不支持这些配置驱动的能力，需要明确：是向 OpenClaw 提需求，还是自己写 skill？写 skill 的代码量预估是多少？

---

## 新项目接入清单

按当前方案，接入一个新业务项目需要：

1. 创建项目目录结构（`project/`、`docs/`、`workspace/`）
2. 编写项目 specs（`docs/specs/` 下的全量规格）
3. 准备知识库（`docs/knowledges/` 下的模板、规范、领域知识）
4. 配置 Pipeline 阶段和流转规则（当前需要**改代码**）
5. 编写 CLAUDE.md 模板（当前需要**改代码**中的生成逻辑）
6. 配置 Review 规则和评估标准（当前需要**改代码**）
7. 配置 Hook 脚本
8. 配置 Agent Teams 角色描述模板

**问题**：步骤 4/5/6 需要改代码，不是纯配置。理想状态应该只需要步骤 1/2/3/8，其余全部配置驱动。

---

## 架构改进建议

### 1. 引入项目配置层

在 `project/` 下增加 `aifd.yaml`（或类似配置文件），声明：
- Pipeline 阶段定义和流转规则
- 每个阶段的 Review 配置
- CLAUDE.md 模板路径
- 人工审批节点
- 任务拆分策略

这样 OpenClaw 侧的引擎代码读配置执行，不因项目不同而改变。

### 2. 分离框架引擎和项目内容

```
AIFD/
├── engine/                    # 框架引擎（不随项目变）
│   ├── pipeline-engine/       # 通用状态机（OpenClaw skill）
│   ├── context-builder/       # 通用上下文构建（OpenClaw skill）
│   ├── quality-gate/          # 通用质量把关（OpenClaw skill）
│   └── memory-sync/           # 通用记忆同步（OpenClaw skill）
├── templates/                 # 场景模板
│   ├── software-dev/          # 软件研发场景
│   │   ├── aifd.yaml
│   │   ├── claude-md-templates/
│   │   └── knowledge-seed/
│   └── content-creation/      # 内容创作场景（示例）
└── projects/                  # 具体项目实例
    └── my-app/
        ├── aifd.yaml          # 从模板复制 + 定制
        ├── docs/
        └── ...
```

### 3. 明确需要写的代码清单

当前方案中**必须写代码**的部分：
1. Pipeline 状态机引擎（OpenClaw skill，~200-400 行）
2. 上下文构建器（OpenClaw skill，~150-300 行）
3. CLAUDE.md 模板渲染（~50-100 行）
4. ReAct-Loop 控制器（OpenClaw skill，~200-300 行）
5. 质量评估编排（OpenClaw skill，~100-200 行）
6. Session 恢复逻辑（~100-200 行）
7. Hook 脚本（~30-50 行 bash）

总计约 **800-1500 行**代码。建议在方案中明确标注这些，而不是用伪代码暗示。

### 4. 考虑用 OpenClaw 现有机制替代自建

- ReAct-Loop 是否可以用 OpenClaw 的 heartbeat + 状态检查实现？
- Pipeline 状态是否可以用 OpenClaw 的 task 系统（OpenGoat）管理？
- 质量评估是否可以用 OpenClaw 的 subagent spawn 实现（spawn 一个评估 subagent）？

如果这些都能用现有机制，代码量可以大幅减少。

---

*评估完毕。核心结论：方案的战略分层正确，但当前是一个「软件研发自动化系统」的设计，不是一个「通用 AI 驱动研发框架」的设计。要达到框架级的可扩展性，需要抽象出配置���，分离引擎和内容。*
