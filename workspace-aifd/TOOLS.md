# TOOLS.md — AIFD 工具配置

## Claude Code CLI
- 调用方式：`cd {project_path} && claude --print --dangerously-skip-permissions -p "..."`
- 工作目录：必须是业务项目根目录

## 项目初始化
- 模板目录：`templates/claude-code-project/`
- 初始化：`cp -r templates/claude-code-project/* {project_path}/`

## Git
- 每次 Claude Code 调用前：`cd {project_path} && git add -A && git commit -m "..." --allow-empty`
- 失败时可 `git reset --hard` 回退

## 常用构建命令（按项目技术栈调整）
- Java：`mvn compile` / `mvn test`
- React：`npm run build` / `npm test`
- Python：`pip install -r requirements.txt` / `pytest`
