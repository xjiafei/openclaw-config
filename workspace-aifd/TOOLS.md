# TOOLS.md — AIFD v2 工具配置

## Claude Code CLI（v2 持久会话模式）

### 首次启动（全量需求）
```bash
SESSION_ID=$(uuidgen)
cd {project_path} && su - claw -c "source ~/.bashrc && cd {project_path} && \
  claude --print --dangerously-skip-permissions \
  --session-id $SESSION_ID \
  -p '任务目标 + 用户需求 + 项目记忆 + 审批检查点说明'"
```

### 首次启动（增量特性）
```bash
# 1. 创建 feature branch
cd {project_path} && git checkout -b feature/{feature_id}-{name} main

# 2. 创建增量文档目录（必须用 project_write.sh 确保权限）
skills/pipeline/project_write.sh {project_path} mkdir docs/specs/features/{feature_id}

# 3. 启动 Claude Code
SESSION_ID=$(uuidgen)
cd {project_path} && su - claw -c "source ~/.bashrc && cd {project_path} && \
  claude --print --dangerously-skip-permissions \
  --session-id $SESSION_ID \
  -p '任务目标 + 增量特性信息(feature_id/name/branch) + 用户需求 + 项目记忆 + 审批检查点说明'"
```

### 审批后恢复
```bash
cd {project_path} && su - claw -c "source ~/.bashrc && cd {project_path} && \
  claude --print --dangerously-skip-permissions \
  --resume $SESSION_ID \
  -p '审批反馈 + 继续下一阶段'"
```

### 回退方案
如果 `--resume` 失败：
1. 尝试 `--continue`（恢复最近会话）
2. 启动新会话，注入已完成文档路径

### 长任务执行（推荐方式）
使用 `skills/pipeline/run_claude.sh` 在后台运行：
```bash
# 启动
skills/pipeline/run_claude.sh {project_path} {session_id} {prompt_file} new|resume

# 监控
skills/pipeline/run_claude.sh status {run_id}
skills/pipeline/run_claude.sh log {run_id}
skills/pipeline/run_claude.sh kill {run_id}
```

### 增量特性合并（Close Loop 通过后）
```bash
cd {project_path}
git checkout main
git merge feature/{feature_id}-{name}
git branch -d feature/{feature_id}-{name}
```

## 项目初始化
- 统一初始化脚本：`skills/pipeline/init_project.sh`
- 调用示例：
  `skills/pipeline/init_project.sh <project_id> <project_name> <project_path> <tech_stack> [domain] [nfr] [boundary]`

## 业务项目文件写入
- 统一写入脚本：`skills/pipeline/project_write.sh`
- OpenClaw（root）写业务项目文件必须通过此脚本，确保权限归 claw 用户
- 调用示例：
  `skills/pipeline/project_write.sh {project_path} mkdir {dir_path}`
  `skills/pipeline/project_write.sh {project_path} write {file_path} {content}`

## Git
- 每次 Claude Code 调用前：`cd {project_path} && git add -A && git commit -m "..." --allow-empty`
- 失败时可 `git reset --hard` 回退
