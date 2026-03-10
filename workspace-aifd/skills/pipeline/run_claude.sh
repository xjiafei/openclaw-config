#!/usr/bin/env bash
set -euo pipefail

# run_claude.sh — 在后台运行 Claude Code 长任务
#
# 解决问题：
#   1. exec timeout 会 SIGTERM 杀进程 → 用 nohup 脱离
#   2. prompt 含特殊字符被 shell 解释 → 用 stdin pipe 传入
#   3. prompt 文件在 root 目录，claw 无法读取 → 复制到 /tmp
#   4. su - claw 环境不完整 → 生成独立 runner 脚本
#
# 用法：
#   run_claude.sh <project_path> <session_id> <prompt_file> [new|resume]
#   run_claude.sh status <run_id>
#   run_claude.sh log <run_id>
#   run_claude.sh kill <run_id>
#
# 产出：
#   /tmp/claude-run-<run_id>.pid   — Claude Code PID
#   /tmp/claude-run-<run_id>.log   — 输出日志
#   /tmp/claude-run-<run_id>.done  — 完成标记（退出码）

ACTION=${1:-}

# --- 状态查询模式 ---
if [ "$ACTION" = "status" ]; then
  RUN_ID=${2:?run_id required}
  DONE_FILE="/tmp/claude-run-${RUN_ID}.done"
  PID_FILE="/tmp/claude-run-${RUN_ID}.pid"
  if [ -f "$DONE_FILE" ]; then
    EXIT_CODE=$(cat "$DONE_FILE")
    echo "DONE exit_code=$EXIT_CODE"
  elif [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    ELAPSED=$(ps -p "$(cat "$PID_FILE")" -o etime= 2>/dev/null | tr -d ' ')
    echo "RUNNING pid=$(cat "$PID_FILE") elapsed=$ELAPSED"
  else
    echo "DEAD (process gone, no done file)"
    # 检查是否有日志可供诊断
    [ -f "/tmp/claude-run-${RUN_ID}.log" ] && echo "Log exists: $(wc -c < /tmp/claude-run-${RUN_ID}.log) bytes"
  fi
  exit 0
fi

if [ "$ACTION" = "log" ]; then
  RUN_ID=${2:?run_id required}
  LOG_FILE="/tmp/claude-run-${RUN_ID}.log"
  LINES=${3:-50}
  if [ -f "$LOG_FILE" ]; then
    tail -"$LINES" "$LOG_FILE"
  else
    echo "No log file found"
  fi
  exit 0
fi

if [ "$ACTION" = "kill" ]; then
  RUN_ID=${2:?run_id required}
  PID_FILE="/tmp/claude-run-${RUN_ID}.pid"
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    kill "$(cat "$PID_FILE")" 2>/dev/null && echo "Killed pid=$(cat "$PID_FILE")"
  else
    echo "Process not running"
  fi
  exit 0
fi

# --- 启动模式 ---
PROJECT_PATH=${1:?project_path required}
SESSION_ID=${2:?session_id required}
PROMPT_FILE=${3:?prompt_file required}
MODE=${4:-resume}  # new or resume

RUN_ID=$(echo "$SESSION_ID" | cut -c1-8)
LOG_FILE="/tmp/claude-run-${RUN_ID}.log"
PID_FILE="/tmp/claude-run-${RUN_ID}.pid"
DONE_FILE="/tmp/claude-run-${RUN_ID}.done"
PROMPT_TMP="/tmp/claude-prompt-${RUN_ID}.txt"

# 清理旧状态
rm -f "$LOG_FILE" "$PID_FILE" "$DONE_FILE"

# 复制 prompt 到 claw 可读的位置（解决 /root 目录 700 权限问题）
cp "$PROMPT_FILE" "$PROMPT_TMP"
chmod 644 "$PROMPT_TMP"

# 构建 claude 参数
if [ "$MODE" = "new" ]; then
  CLAUDE_FLAG="--session-id $SESSION_ID"
else
  CLAUDE_FLAG="--resume $SESSION_ID"
fi

# 生成 runner 脚本（避免 shell 嵌套引号问题）
RUNNER="/tmp/claude-runner-${RUN_ID}.sh"
cat > "$RUNNER" << ENDSCRIPT
#!/usr/bin/env bash
# 加载 claw 用户环境
source /home/claw/.bashrc 2>/dev/null || true
export PATH=/root/.nvm/versions/node/v22.22.0/bin:\$PATH
cd "$PROJECT_PATH"

# 通过 stdin pipe 传入 prompt（避免特殊字符被 shell 解释）
cat "$PROMPT_TMP" | claude --print --dangerously-skip-permissions $CLAUDE_FLAG

# 记录退出码
echo \$? > "$DONE_FILE"
ENDSCRIPT
chmod +x "$RUNNER"
chown claw:claw "$RUNNER"

# 以 claw 用户在后台运行，nohup 脱离终端
nohup su - claw -c "$RUNNER" > "$LOG_FILE" 2>&1 &
RUNNER_PID=$!

# 等待 claude 进程实际启动（su 是包装层）
sleep 3
CLAUDE_PID=$(pgrep -P "$(pgrep -P $RUNNER_PID 2>/dev/null || echo 0)" -f "claude" 2>/dev/null || echo "$RUNNER_PID")
echo "$RUNNER_PID" > "$PID_FILE"

echo "STARTED run_id=$RUN_ID pid=$RUNNER_PID log=$LOG_FILE"
echo "Monitor: $(basename "$0") status $RUN_ID"
echo "Logs:    $(basename "$0") log $RUN_ID"
echo "Kill:    $(basename "$0") kill $RUN_ID"
