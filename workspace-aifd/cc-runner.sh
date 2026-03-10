#!/usr/bin/env bash
source /home/claw/.bashrc 2>/dev/null || true
export PATH=/root/.nvm/versions/node/v22.22.0/bin:$PATH
cd /root/my-knowledge

PROMPT=$(cat /root/.openclaw/workspace-aifd/cc-prompt-test-only.txt)

claude --print --dangerously-skip-permissions \
  --session-id 115f231a-21ea-408f-8f25-2e5663697b76 \
  -p "$PROMPT" \
  > /tmp/claude-run-cc-test.log 2>&1

echo $? > /tmp/claude-run-cc-test.done
