# docs/knowledges — 项目知识库

项目知识资产的统一沉淀目录。Claude Code 各 agent 在执行过程中会读取和沉淀知识。

## 目录结构

| 目录 | 用途 | 主要读者 |
|------|------|---------|
| `standards/` | 编码规范（命名、异常处理、API 设计、数据库、安全等） | 开发 agent、code-reviewer |
| `domain/` | 业务领域知识（术语表、业务规则） | pm-agent、qa-agent、开发 agent |
| `architecture/` | 架构决策记录（ADR）、技术债务清单 | arch-agent、code-reviewer |
| `patterns/` | 可复用的代码模式和实现模板 | 开发 agent |
| `ui-guidelines/` | UI/交互规范 | 前端 agent |
| `lessons-learned/` | 经验教训、踩坑记录 | 所有 agent |

## 知识条目格式

每个知识条目建议包含：

```markdown
# {标题}

> 来源：{哪个阶段/agent 沉淀的} | 日期：{YYYY-MM-DD}

## 适用场景
什么时候用这个知识/规范/模式。

## 内容
具体的规范/规则/模式描述。

## 反模式（可选）
不该怎么做 + 为什么。
```

## 沉淀触发条件

以下场景应触发知识沉淀（参见 DOC_GOVERNANCE.md）：
- 发现可复用的编码模式 → `patterns/`
- 发现领域业务规则 → `domain/`
- 做出关键技术决策 → `architecture/`
- 踩坑并解决 → `lessons-learned/`
- 总结出编码规范 → `standards/`
