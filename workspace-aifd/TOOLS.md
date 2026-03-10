# TOOLS.md — AIFD v2 工具配置

## Claude Code CLI（v2 持久会话模式）

### 首次启动
```bash
SESSION_ID=$(uuidgen)
cd {project_path} && su - claw -c "source ~/.bashrc && cd {project_path} && \
  claude --print --dangerously-skip-permissions \
  --session-id $SESSION_ID \
  -p '任务目标 + 用户需求 + 项目记忆 + 审批检查点说明'"
```

### 审批后恢复
```bash
cd {project_path} && su - claw -c "source ~/.bashrc && cd {project_path} && \
  claude --print --dangerously-skip-permissions \
  --resume $SESSION_ID \
  -p '审批反馈 + 继续下一阶段'"
```

### 长任务执行（推荐）
Claude Code 长任务（尤其是 Close Loop）必须用 tmux 托管，不受 exec timeout 限制：
```bash
# 启动（新会话 / 恢复会话）
skills/pipeline/run_claude.sh <project_path> <session_id> <prompt_file> [new|resume]

# 监控状态（返回 RUNNING/DONE/UNKNOWN）
skills/pipeline/run_claude.sh status <tmux_session>

# 查看最新输出
skills/pipeline/run_claude.sh log <tmux_session>

# 终止
skills/pipeline/run_claude.sh kill <tmux_session>
```
进程完成后写入 `/tmp/claude-run-<tmux_session>.done`（内含退出码），
输出日志在 `/tmp/claude-run-<tmux_session>.log`。

**规则：预计超过 10 分钟的 Claude Code 任务必须用 run_claude.sh，禁止直接 exec 调用。**

### 回退方案
如果 `--resume` 失败：
1. 尝试 `--continue`（恢复最近会话）
2. 启动新会话，注入已完成文档路径

## 项目初始化
- 统一初始化脚本：`skills/pipeline/init_project.sh`
- 调用示例：
  `skills/pipeline/init_project.sh <project_id> <project_name> <project_path> <tech_stack> [domain] [nfr] [boundary]`

## 项目文件操作（权限安全）
OpenClaw 以 root 运行，Claude Code 以 claw 运行。直接以 root 在业务项目中创建文件/目录会导致 claw 无权写入。

**统一入口**：`skills/pipeline/project_write.sh`
```bash
# 创建目录
skills/pipeline/project_write.sh {project_path} mkdir docs/specs/features/xxx

# 写文件（内容通过参数）
skills/pipeline/project_write.sh {project_path} write workspace/pipeline.json '{"key":"value"}'

# 写文件（内容通过 stdin）
echo '{}' | skills/pipeline/project_write.sh {project_path} write workspace/pipeline.json

# 修复整个项目权限（应急）
skills/pipeline/project_write.sh {project_path} fix_perms
```

**规则**：凡是 OpenClaw 需要在业务项目中创建/修改文件，必须通过此脚本或操作后 `chown -R claw:claw`。

## Git
- 每次 Claude Code 调用前：`cd {project_path} && git add -A && git commit -m "..." --allow-empty`
- 失败时可 `git reset --hard` 回退
