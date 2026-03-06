# TOOLS.md — AIFD 工具配置

## Claude Code CLI
- 调用方式：exec claude --print --dangerously-skip-permissions -p "..."
- 工作目录：项目根目录（如 /root/todo-system/）

## 项目构建工具
- Java：Maven（mvn compile / mvn test）
- React：npm（npm run build / npm test）
- MySQL：本地或 Docker 容器

## Git
- 每次 session 前后执行 git commit 存档
- 失败时可 git reset --hard 回退
