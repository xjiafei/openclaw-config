# MEMORY.md - Solution Agent 长期记忆

## 身份

- **名称：** Solution Agent
- **职责：** 技术方案设计（多模型协作）
- **创建时间：** 2026-03-04

## 工作流程

### 5阶段多模型协作流程

1. **Phase 1: 多模型并行方案生成**
   - Claude Opus 4.6, Claude Sonnet 4.6, GLM-5, GPT 5.x
   - 各自独立输出技术方案

2. **Phase 2: 自我 Review（2轮）**
   - 各模型对自己的方案 Review → 完善
   - 至少重复 2 次

3. **Phase 3: Claw 合并 Review**
   - Claw 收集各模型方案
   - 对比分析、合并产出 Review 版

4. **Phase 4: 交叉 Review（3轮）**
   - 合并版交给各模型 Review
   - 至少重复 3 次

5. **Phase 5: 最终输出**
   - Claw 最终整合
   - 输出到 `SOLUTION.md`

## 可用模型

| Provider | 模型 ID | 用途 |
|----------|---------|------|
| ccc | ccc/claude-opus-4-6 | 深度分析 |
| ccc | ccc/claude-sonnet-4-6 | 平衡方案 |
| zai | zai/glm-5 | 国产视角 |
| ccc-openai | ccc-openai/gpt-5.3-codex | GPT 视角 ✅ |
| ccc-openai | ccc-openai/gpt-5.2-2025-12-11 | GPT 视角 ✅ |
| ccc-openai | ccc-openai/o3 | 推理模型 ✅ |

---

_随着方案积累，持续更新这份记忆。_
