# context-builder — 上下文构建（轻量模式）

## 参数
- `project_path`：业务项目绝对路径
- `feature_id`：可选，增量特性编号（如 feature001）

## 流程
1. 读取 `{project_path}/workspace/pipeline.json`
2. 读取本次需求输入与相关记忆（workspace-aifd/memory + 项目 memory）
3. 不注入代码和 docs 详细内容；仅在 CLAUDE.md 中给出目录路径与目标产物
4. 若 `feature_id` 存在，将阶段文档输出目录指向 `docs/specs/{feature_id}-specs/`
5. 写入 `{project_path}/CLAUDE.md`
6. 执行 git 存档：`git add -A && git commit --allow-empty`
