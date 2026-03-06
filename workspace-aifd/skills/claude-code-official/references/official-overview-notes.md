# Claude Code 官方概览要点（学习笔记）

来源：
- https://code.claude.com/docs/en/overview
- 文档索引： https://code.claude.com/docs/llms.txt

## 关键能力
- 可读代码库、改文件、运行命令、跨工具协作
- 可在 Terminal / VSCode / JetBrains / Desktop / Web 使用
- 支持通过 CLAUDE.md 持续记忆与项目约束
- 支持 custom commands、hooks、sub-agents、MCP 集成
- 适合 CLI 自动化与管道化调用（`claude -p`）

## 对 AIFD 的直接启发
1. AIFD 应聚焦“编排与门禁”，减少对子能力调用顺序的硬编码
2. 强化 `.claude/agents + skills + hooks + commands` 定义质量
3. 用 `CLAUDE.md` 明确阶段目标、输入输出、质量标准与约束
4. 通过测试和文档沉淀形成可审计交付闭环

## 使用注意
- 长任务建议异步运行并定时汇报进度
- 失败重试需要有次数上限和人工介入阈值
- docs 与 bug 记录要形成闭环（产出 -> 验证 -> 回写）
