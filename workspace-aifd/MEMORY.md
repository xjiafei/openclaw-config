# MEMORY.md — AIFD 长期记忆

## 框架使用经验
- 长任务（Claude Code 调用）必须用异步方式执行（background: true），不能阻塞当前会话（2026-03-09）
- 长任务执行期间每 10 分钟向用户汇报进度（2026-03-09）
- `--print` 模式下 Claude Code 的输出是完成后一次性返回的，中间无法看到进度，需通过检查文件产出来判断进展（2026-03-09）
- **Claude Code CLI 无法以 root 运行**：业务项目必须属于 `claw` 用户，以 `su - claw -c "..."` 方式执行（2026-03-09）

## 跨项目教训
（初始化，尚无记录）

## 质量模式
（初始化，尚无记录）

## 流程改进
- 技术设计阶段必须由 qa-agent 产出 test-plan.md 和 test-cases.md，不能只靠检查清单事后验（2026-03-10）
- 产出责任链：主代理写 tech.md → 调度 qa-agent 写测试方案和用例集 → 三份文档一起进自检循环 → 一起提交审批（2026-03-10）
- 实现阶段 qa-agent 按 test-cases.md 逐条执行，结果落盘到 workspace/test-results.md（2026-03-10）

## 权限问题教训
- OpenClaw 以 root 运行，Claude Code 以 claw 运行。root 直接在业务项目目录中 mkdir/写文件会导致 claw 无权操作，Claude Code 被迫换路径或报错（2026-03-10）
- 根因：增量特性初始化时 OpenClaw 用 Python/mkdir 直接创建 docs/specs/features/ 子目录，未 chown 给 claw
- 修复：新增 skills/pipeline/project_write.sh 作为统一入口，所有操作后自动 chown；SOUL.md 约束中新增"权限一致性"条款
- 教训：凡是 OpenClaw 和 Claude Code 共享操作的目录，必须确保权限一致

## 长任务执行教训
- exec 的 timeout 参数到期后 OpenClaw 会 SIGTERM 杀进程，Close Loop 等长任务（20-60分钟）必然被中断（2026-03-10）
- 解决方案：用 tmux 托管 Claude Code 进程，生命周期独立于 exec timeout。新增 skills/pipeline/run_claude.sh 脚本
- 规则：预计超过 10 分钟的任务必须用 run_claude.sh，通过轮询 status/log 监控进度
- 监控方式：检查 /tmp/claude-run-*.done 文件是否存在 + 轮询项目目录中的产出文件

## Close Loop 中断恢复教训
- Close Loop 被中断后，OpenClaw 不应替代 Claude Code 编排者角色手动拆分任务（如单独调度 Bug 修复）（2026-03-10）
- 正确做法：恢复会话时告诉 Claude Code "从 Close Loop 断点继续"，让它自己走完闭环流程
- E2E 测试在多次中断恢复中丢失了上下文，qa-agent 只跑了单元+API 测试就结束了
- 改进：恢复 prompt 中必须明确列出"尚未完成的 Close Loop 环节"和"test-plan 中要求但未执行的测试类型（如 Playwright E2E）"

## Close Loop 检查点机制（2026-03-10）
- Close Loop 进度之前只存在 Claude Code 会话上下文中，中断即丢失
- 新增 workspace/close-loop-checkpoint.json 持久化检查点，每完成一个阶段立即更新并 commit
- testing 阶段细分为 unitTests / integrationTests / e2eTests / bugFixes，避免恢复后遗漏
- OpenClaw 恢复时读取 checkpoint 生成 prompt，不替代编排者角色
- 职责边界：Bug 修复和测试调度是 Claude Code 编排者的工作，OpenClaw 只负责恢复会话+传递状态
