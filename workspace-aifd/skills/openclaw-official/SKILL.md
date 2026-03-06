---
name: openclaw-official
description: OpenClaw 官方与实战合并技能。用于网关运维、配置治理、会话与多代理路由、安全与环境变量、诊断排障与变更回滚。
version: 2.0.0
---

# OpenClaw Official (Merged)

## 适用场景
- OpenClaw 配置/运维/排障
- 多渠道与多代理路由配置
- 变更前后验证与回滚设计

## 标准流程
1. 先检查运行状态：
   - `openclaw gateway status`
   - `openclaw status`
   - `openclaw logs --follow`
2. 再改配置：
   - `openclaw config get ...`
   - `openclaw config set ...`
3. 最后验证：
   - `openclaw doctor`
   - `openclaw channels status --probe`

## 关键规范
- 配置文件：`~/.openclaw/openclaw.json`（严格 schema）
- 优先最小改动；输出影响范围与回滚方法
- 敏感信息优先环境变量/SecretRef
- 提交时排除运行时噪音文件（dedup/runs/state 等）

## 常见故障
- 端口冲突（EADDRINUSE）
- 鉴权不匹配（token/password）
- 配置校验失败导致网关拒绝启动
- 频道 probe 失败

## 参考
- `references/openclaw-official-notes.md`
- 本地 docs：`openclaw/docs/`
