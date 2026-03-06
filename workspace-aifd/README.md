# AIFD - AI Full-process Development Framework

> **版本:** V1.0  
> **更新:** 2026-03-06

## 概述

AIFD（AI Full-process Development）是一个基于 OpenClaw 的 AI 全流程研发框架。它通过编排 Claude Code 等 AI 编码工具，实现从需求到可运行系统的自动化研发流程。

## 核心特性

- 🚀 **全流程驱动**：需求 → 产品设计 → 技术设计 → 开发 → 测试
- 🧠 **记忆管理**：跨 session 持久化项目经验、决策记录
- 📋 **质量把关**：AI 自动评估产物质量，不通过则修正重做
- 👥 **多项目支持**：框架与业务项目解耦，支持同时管理多个项目
- ⏰ **进度汇报**：定期汇报任务执行进度

## 目录结构

```
workspace-aifd/
├── SOUL.md                 # AIFD agent 人格定义和工作流程
├── USER.md                 # 用户信息
├── MEMORY.md               # 长期记忆
├── AGENTS.md               # 工作空间说明
├── TOOLS.md                # 工具配置
├── skills/                 # Skills 定义
│   ├── context-builder/    # 上下文构建
│   ├── quality-gate/       # 质量把关
│   ├── pipeline/           # 流程编排
│   └── memory-sync/        # 记忆同步
├── memory/                 # 日志记忆
├── projects/               # 项目注册表
│   └── registry.json       # 已注册项目列表
├── requests/               # 用户需求记录
└── templates/              # Claude Code 项目模板
    └── claude-code-project/
```

## 工作流程

```
用户需求
    ↓
1. 记录需求 (requests/)
    ↓
2. 判断项目类型
    ├── 新项目 → 创建项目目录 → 初始化 Claude Code 项目
    └── 已有项目 → 读取项目状态
    ↓
3. 驱动研发流程
    ├── Requirements (需求分析) → 用户审批
    ├── Product (产品设计) → 用户审批
    ├── Tech (技术设计) → 用户审批
    ├── Implementation (编码实现)
    └── Testing (测试验证)
    ↓
4. 质量把关 + 修正循环
    ↓
5. 总结经验教训 → 写入记忆
```

## 使用方法

### 1. 提出需求

通过飞书等渠道向 AIFD agent 描述你的需求：

```
帮我开发一个 Todo 系统，支持任务的 CRUD 操作
```

### 2. 确认项目路径

AIFD 会询问项目存放路径，或自动在 `/root/` 下创建。

### 3. 审批关键节点

在需求、产品设计、技术设计阶段完成后，AIFD 会请求你的审批。

### 4. 查看进度

AIFD 会定期汇报任务执行进度。

## 业务项目结构

每个业务项目是标准的 Claude Code 项目：

```
{project}/
├── .claude/
│   ├── agents/
│   │   ├── pm-agent.md
│   │   ├── architect-agent.md
│   │   ├── developer-agent.md
│   │   └── qa-agent.md
│   ├── commands/
│   └── skills/
├── CLAUDE.md               # 动态生成的任务指令
├── docs/
│   ├── specs/              # 规格文档
│   └── knowledges/         # 知识库
├── workspace/
│   └── pipeline.json       # 流水线状态
├── backend/                # 后端代码
└── frontend/               # 前端代码
```

## 已注册项目

| 项目名 | 路径 | 状态 |
|--------|------|------|
| Todo System | /root/todo-system | active |

## 技术栈

- **编排层**: OpenClaw (本框架)
- **执行层**: Claude Code CLI
- **模型**: Claude Opus / GPT-5 / GLM-5

## 相关文档

- [技术方案](./AIFD_V1_PROPOSAL.md)
- [SOUL 定义](./SOUL.md)
- [项目模板](./templates/claude-code-project/)

## 维护者

- Gary (架构设计)
- AIFD Agent (自动维护)
