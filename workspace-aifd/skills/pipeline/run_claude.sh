#!/usr/bin/env bash
set -euo pipefail

# run_claude.sh — 在 tmux 中运行 Claude Code 长任务
# 进程不受 exec timeout 限制，通过轮询产出文件监控状态
#
# 用法：
#   run_claude.sh <project_path> <session_id> <prompt_file> [new|resume]
#
# 产出：
#   /tmp/claude-run-<tmux_session>.pid   — Claude Code PID
#   /tmp/claude-run-<tmux_session>.log   — 输出日志
#   /tmp/claude-run-<tmux_session>.done  — 完成标记（退出码写入）
#
# 监控：
#   run_claude.sh status <tmux_session>  — 检查运行状态
#   run_claude.sh log <tmux_session>     — 查看最新输出
#   run_claude.sh kill <tmux_session>    — 终止运行

ACTION=${1:-}

# --- 状态查询模式 ---
if [ "$ACTION" = "status" ]; then
  TMUX_SESSION=${2:?tmux_session required}
  DONE_FILE="/tmp/claude-run-${TMUX_SESSION}.done"
  PID_FILE="/tmp/claude-run-${TMUX_SESSION}.pid"
  if [ -f "$DONE_FILE" ]; then
    EXIT_CODE=$(cat "$DONE_FILE")
    echo "DONE exit_code=$EXIT_CODE"
  elif [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    ELAPSED=$(ps -p "$(cat "$PID_FILE")" -o etime= 2>/dev/null | tr -d ' ')
    echo "RUNNING pid=$(cat "$PID_FILE") elapsed=$ELAPSED"
  else
    echo "UNKNOWN (no pid file or process dead)"
  fi
  exit 0
fi

if [ "$ACTION" = "log" ]; then
  TMUX_SESSION=${2:?tmux_session required}
  LOG_FILE="/tmp/claude-run-${TMUX_SESSION}.log"
  if [ -f "$LOG_FILE" ]; then
    tail -50 "$LOG_FILE"
  else
    echo "No log file found"
  fi
  exit 0
fi

if [ "$ACTION" = "kill" ]; then
  TMUX_SESSION=${2:?tmux_session required}
  PID_FILE="/tmp/claude-run-${TMUX_SESSION}.pid"
  if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null && echo "Killed" || echo "Process already dead"
  fi
  tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true
  exit 0
fi

# --- 启动模式 ---
PROJECT_PATH=${1:?project_path required}
SESSION_ID=${2:?session_id required}
PROMPT_FILE=${3:?prompt_file required}
MODE=${4:-resume}  # new or resume

TMUX_SESSION="cc-$(echo "$SESSION_ID" | cut -c1-8)"
LOG_FILE="/tmp/claude-run-${TMUX_SESSION}.log"
PID_FILE="/tmp/claude-run-${TMUX_SESSION}.pid"
DONE_FILE="/tmp/claude-run-${TMUX_SESSION}.done"

# 清理旧状态
rm -f "$LOG_FILE" "$PID_FILE" "$DONE_FILE"

# 构建 claude 命令
if [ "$MODE" = "new" ]; then
  CLAUDE_FLAG="--session-id $SESSION_ID"
else
  CLAUDE_FLAG="--resume $SESSION_ID"
fi

# 创建 runner 脚本（tmux 会执行这个）
RUNNER="/tmp/claude-runner-${TMUX_SESSION}.sh"
cat > "$RUNNER" << SCRIPT
#!/usr/bin/env bash
source /home/claw/.bashrc 2>/dev/null || true
export PATH=/root/.nvm/versions/node/v22.22.0/bin:\$PATH
cd "$PROJECT_PATH"

# 记录 PID
echo \$\$ > "$PID_FILE"

# 运行 Claude Code
claude --print --dangerously-skip-permissions \\
  $CLAUDE_FLAG \\
  -p "\$(cat $PROMPT_FILE)" \\
  > "$LOG_FILE" 2>&1

# 记录退出码
echo \$? > "$DONE_FILE"
SCRIPT
chmod +x "$RUNNER"

# 杀掉同名旧 tmux 会话
tmux kill-session -t "$TMUX_SESSION" 2>/dev/null || true

# 在 tmux 中以 claw 用户启动
tmux new-session -d -s "$TMUX_SESSION" "su - claw -c '$RUNNER'"

echo "STARTED tmux_session=$TMUX_SESSION log=$LOG_FILE"
echo "Monitor: run_claude.sh status $TMUX_SESSION"
echo "Logs:    run_claude.sh log $TMUX_SESSION"
echo "Kill:    run_claude.sh kill $TMUX_SESSION"
