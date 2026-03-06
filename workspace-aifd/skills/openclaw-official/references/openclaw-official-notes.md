# OpenClaw 官方文档学习笔记

来源：
- https://github.com/openclaw/openclaw/tree/main/docs
- 本地 docs：openclaw/docs/index.md, gateway/runbook, gateway/configuration

## 关键认知
1. OpenClaw 是多渠道 AI 代理网关（自托管）
2. Gateway 是会话、路由、渠道连接的单一真相源
3. 配置文件为 `~/.openclaw/openclaw.json`，遵循严格 schema 校验
4. 默认热重载模式是 `hybrid`（可热更则热更，否则重启）
5. 关键运维命令：
   - `openclaw gateway status`
   - `openclaw status`
   - `openclaw logs --follow`
   - `openclaw doctor`
   - `openclaw channels status --probe`

## 配置与安全
- 支持 `.env` 与 `~/.openclaw/.env`
- 支持 config 中 `${ENV_VAR}` 替换
- 支持 SecretRef（env/file/exec）
- 非 loopback 绑定默认要求网关认证

## 对 AIFD 的实践建议
- 先 status/doctor，再改配置
- 提交时排除运行时噪音文件
- 所有变更附带回滚方案
