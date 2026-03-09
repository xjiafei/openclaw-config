# AIFD Demo 前就绪评估与改进计划

更新时间：2026-03-06
来源：Claude Opus 评估

## 1. 结论

**有条件的 Yes**：当前框架可以做 Demo，但需先完成 5 项关键补齐（约 2-3 天）。

前提条件：
- implementation 阶段至少成功跑通 1 次
- testing 阶段至少成功跑通 1 次
- 至少 1 次失败→重试→恢复闭环验证
- 审批链端到端可演示

---

## 2. 风险清单（P0/P1/P2）

| # | 级别 | 问题 | 影响 | 建议 | 工作量 |
|---|------|------|------|------|--------|
| 1 | P0 | implementation/testing 从未实际执行 | Demo 断链 | 立即在 todo-system 跑通 impl+test | M |
| 2 | P0 | pipeline 无失败恢复机制 | 状态不一致 | 增加 fail 状态与恢复入口 | S |
| 3 | P0 | 审批流无状态记录 | 审批不可验证 | 增加 pending_approval 状态写入 | S |
| 4 | P0 | context-builder 纯文档指南 | 手工易出错 | 增加自动生成脚本 build-context.sh | M |
| 5 | P0 | quality-gate 无真实执行脚本 | 评估不可靠 | impl/test 阶段执行真实构建与测试 | S |
| 6 | P1 | agent-memory 未形成真实消费闭环 | 经验机制无效 | 产生并注入真实经验条目 | S |
| 7 | P1 | sessions 下缺少 review.json 产物 | 质量门禁难追踪 | 确保每阶段产出 review.json | S |
| 8 | P1 | CLAUDE.md.template 占位符手动替换 | 易遗漏 | 自动替换占位符 | S |
| 9 | P1 | 模板残留临时文件风险 | 专业性问题 | 清理 .swp/.tmp 文件 | S |
| 10 | P1 | 进度汇报未模板化 | 汇报不稳定 | 定义阶段消息模板 + 固定渠道 | S |
| 11 | P2 | 新项目初始化未端到端验证 | 初始化不确定性 | 增加 init-project.sh | S |
| 12 | P2 | featureXXX-specs 合并流程未实测 | 文档治理风险 | 用一个 feature 做合并演练 | M |

---

## 3. 30 天改进计划

### Week 1（先跑通）
目标：todo-system 全 5 阶段跑通。

任务：
1. 跑通 implementation（后端）
2. 跑通 implementation（前端）
3. 跑通 testing（至少 5 个测试）
4. pipeline 增加 fail/pending_approval 状态
5. 清理模板杂项文件

验收标准：
- `mvn compile`、`npm run build`、`mvn test`/`npm test` 可通过
- pipeline 状态可准确反映当前阶段与审批状态

### Week 2（再稳定）
目标：关键环节半自动化，提升可复现性。

任务：
1. 实现 build-context.sh
2. quality-gate 增加真实命令执行
3. 审批链闭环（飞书确认→状态推进）
4. agent-memory 读写闭环验证

验收标准：
- 一键生成 CLAUDE.md
- review.json 包含真实测试结果

### Week 3（可演示）
目标：用一个增量特性走完整流程。

任务：
1. 使用 feature001-specs 走完整 5 阶段
2. 演练 1 次失败→重试→成功
3. 进度汇报模板化

验收标准：
- feature 目录产物完整
- 重试机制可观测

### Week 4（可交付）
目标：整理沉淀，准备正式演示。

任务：
1. 提供 init-project.sh（可选）
2. 输出 demo 操作脚本与截图
3. 经验归档到 memory 与 docs/knowledges

验收标准：
- 可按脚本稳定复现 Demo

---

## 4. Demo 最小闭环清单（必须先完成）

1. todo-system implementation 跑通（后端+前端）
2. todo-system testing 跑通
3. pipeline 支持 fail/pending_approval
4. quality-gate 产出 review.json
5. 至少 1 次审批链演示
6. context-builder 至少半自动化
7. 至少 1 次失败→重试→成功演示

---

## 5. Demo 验证流程（建议脚本）

1. 需求输入：生成 requests/REQ-xxx.md
2. requirements：产出 requirements 文档，审批通过
3. product：产出 product 文档，审批通过
4. tech：产出 tech 文档，审批通过
5. implementation：代码产出 + 构建通过（可插入一次失败重试）
6. testing：测试代码与报告产出 + 全量测试通过
7. 收尾：agent-memory 回写、memory 日志更新、spec/docs 沉淀检查

关键观测点：
- pipeline 与实际状态一致
- 审批可追溯
- review.json 可追溯
- docs 沉淀有证据

---

## 6. 当前阶段不建议做的事（避免过度设计）

- Feature Pipeline 并行化
- 需求分级（S/M/L/XL）
- 结构化记忆索引（index.json）
- 多技术栈模板全面铺开
- 复杂影响分析引擎
- 阶段快照 tag 体系（可后置）

原则：先证明“流程跑通 + 质量可控 + 人机协作有效”，再扩展框架能力。
