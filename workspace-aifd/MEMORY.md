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
