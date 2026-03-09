# 实现-验收自动闭环指令（Close Loop）

## 概述

编码完成后，你必须执行以下自动闭环流程。通过调度项目中已有的 subagent 完成多角色评审和验收，直到全部通过。

## 闭环流程

```
编码完成 → git commit
    ↓
[1] code-reviewer：代码评审
    ↓ 有 CRITICAL/HIGH → 修复 → 重新评审（最多 3 次）
    ↓ 通过
[2] arch-agent：技术设计验收
    ↓ 有未通过项 → 修复 → 重新验收（最多 3 次）
    ↓ 通过
[3] qa-agent：测试验证（单元测试 + E2E Playwright）
    ↓ 有失败/Bug → 修复 → 重新测试（最多 3 次）
    ↓ 通过
[4] pm-agent：产品验收（对照需求 + Playwright 走查）
    ↓ 有未通过故事 → 修复 → 回到 [1] 重跑全流程
    ↓ 通过
全部通过 → 输出 workspace/final-report.json → 退出
```

## 各角色调度方式

使用 Claude Code 原生 subagent 机制调度。每个角色在 `.claude/agents/` 中已有定义，直接调用即可。

### [1] 代码评审（code-reviewer）

调度 code-reviewer agent，传入变更范围。

**通过条件**：无 CRITICAL 问题，HIGH 问题数 = 0
**不通过**：读取评审报告 → 修复问题 → 重新调度评审

### [2] 架构师验收（arch-agent）

调度 arch-agent，要求其对照 `docs/specs/tech.md` 验收代码实现。

**验收要求**：
- 架构分层是否按设计实现
- 数据模型是否与设计一致
- API 实现是否与定义一致
- 非功能需求是否落地

**通过条件**：所有检查项通过
**不通过**：读取验收报告 → 修复问题 → 重新调度验收

### [3] 测试验证（qa-agent）

调度 qa-agent，要求其执行完整测试流程。

**测试要求**：
- 运行全量单元/集成测试
- 启动开发服务器，用 Playwright 执行 E2E 测试
- 核心用户流程必须有 E2E 覆盖
- 截图保存到 workspace/screenshots/

**通过条件**：所有测试通过，无 P0 级别 Bug
**不通过**：读取测试报告和 Bug 列表 → 修复 → 重新调度测试

### [4] 产品验收（pm-agent）

调度 pm-agent，要求其对照需求文档做功能验收。

**验收要求**：
- 逐条用户故事验收（对照 Given-When-Then 验收标准）
- 用 Playwright 打开页面实际操作验证
- 检查异常场景处理（空状态、错误提示）
- 截图保存到 workspace/screenshots/pm-acceptance/

**通过条件**：所有 P0/P1 用户故事验收通过
**不通过**：读取验收报告 → 修复 → **回到 [1] 重跑全流程**（因为修复可能影响代码质量）

## 兜底规则

- **单角色循环上限**：3 次。超过 3 次仍未通过 → 记录未通过项，继续下一角色
- **全流程上限**：5 轮（pm-agent 打回重跑算新一轮）
- **达到上限**：输出 final-report.json（标注未通过项和原因）→ 退出
- **递减检测**：如果某角色连续两轮问题数不减反增，提前退出该角色循环

## 输出要求

### 过程文件

每个角色完成后输出结果到 `workspace/`：
- `workspace/code-review-result.json` — 代码评审结果
- `workspace/arch-acceptance.json` — 架构验收结果
- `workspace/test-result.json` — 测试结果
- `workspace/pm-acceptance.json` — 产品验收结果
- `workspace/screenshots/` — 各角色截图

### 最终报告

闭环结束后输出 `workspace/final-report.json`：

```json
{
  "allPassed": true,
  "totalLoops": 2,
  "stages": {
    "codeReview": { "passed": true, "iterations": 1, "summary": "无 CRITICAL/HIGH 问题" },
    "archAcceptance": { "passed": true, "iterations": 1, "summary": "架构实现符合设计" },
    "testing": { "passed": true, "iterations": 2, "summary": "修复 2 个 Bug 后全部通过" },
    "pmAcceptance": { "passed": true, "iterations": 1, "summary": "所有用户故事验收通过" }
  },
  "unresolved": []
}
```

## Playwright 环境要求

所有需要 Playwright 的角色（qa-agent、pm-agent、arch-agent）执行前确保：
1. 开发服务器已启动（前端 + 后端）
2. 数据库已初始化（含测试数据）
3. Playwright 已安装：`npx playwright install --with-deps`

**服务启动由你（主代理）负责**，在调度 subagent 前确保服务可用。
