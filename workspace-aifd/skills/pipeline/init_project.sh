#!/usr/bin/env bash
set -euo pipefail

# Usage:
# init_project.sh <project_id> <project_name> <project_path> <tech_stack> [domain] [nfr] [boundary]

PROJECT_ID=${1:?project_id required}
PROJECT_NAME=${2:?project_name required}
PROJECT_PATH=${3:?project_path required}
TECH_STACK=${4:?tech_stack required}
DOMAIN=${5:-通用业务系统}
NFR=${6:-性能优先，安全合规，可维护性良好}
BOUNDARY=${7:-全新系统}

WORKSPACE_AIFD="/root/.openclaw/workspace-aifd"
TEMPLATE_DIR="$WORKSPACE_AIFD/templates/claude-code-project"
REGISTRY="$WORKSPACE_AIFD/projects/registry.json"
NOW_DATE=$(date -u +"%Y-%m-%d")
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$PROJECT_PATH"
cp -r "$TEMPLATE_DIR"/. "$PROJECT_PATH"/

# Ensure features directory exists
mkdir -p "$PROJECT_PATH/docs/specs/features"

# 设置目录归属为 claw 用户（Claude Code 必须以非 root 用户运行）
chown -R claw:claw "$PROJECT_PATH"
# 添加 git safe.directory
git config --global --add safe.directory "$PROJECT_PATH" 2>/dev/null || true

# Fill pipeline.json (v2)
python3 - <<PY
import json
p = "$PROJECT_PATH/workspace/pipeline.json"
obj = json.load(open(p))
obj["project"] = "$PROJECT_ID"
obj["created_at"] = "$NOW_ISO"
obj["session_id"] = ""
obj["current_stage"] = "requirements"
for k in obj.get("stages", {}):
    obj["stages"][k]["status"] = "pending"
    if k in ("requirements", "product", "tech"):
        obj["stages"][k]["reviewed"] = False
open(p, "w").write(json.dumps(obj, ensure_ascii=False, indent=2))
PY

# Generate CLAUDE.md from template (v2 — simplified)
if [ -f "$PROJECT_PATH/CLAUDE.md.template" ]; then
  sed \
    -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
    -e "s/{{TECH_STACK}}/$TECH_STACK/g" \
    -e "s/{{DOMAIN}}/$DOMAIN/g" \
    -e "s/{{TASK_DESCRIPTION}}/项目初始化完成，等待需求派发/g" \
    -e "s/{{MEMORY_SUMMARY}}/（新项目，暂无记忆）/g" \
    "$PROJECT_PATH/CLAUDE.md.template" > "$PROJECT_PATH/CLAUDE.md"
fi

# Generate README.md from template
if [ -f "$PROJECT_PATH/README.md.template" ]; then
  sed \
    -e "s/{{PROJECT_NAME}}/$PROJECT_NAME/g" \
    -e "s/{{TECH_STACK}}/$TECH_STACK/g" \
    "$PROJECT_PATH/README.md.template" > "$PROJECT_PATH/README.md"
fi

# Role-based dynamic block injection for agent files
python3 - <<PY
from pathlib import Path
import re

project = Path("$PROJECT_PATH")
domain = "$DOMAIN"
tech = "$TECH_STACK"
nfr = "$NFR"
boundary = "$BOUNDARY"

agent_blocks = {
    "go-be-agent.md": [
        f"- 业务实现：理解{domain}核心业务规则并在后端实现。",
        "- 技术能力：精通 Go 标准库、HTTP 框架（Gin/Echo/Fiber）与数据库交互。",
        f"- 工程约束：遵循{tech}技术约束与{nfr}质量目标。",
        f"- 边界意识：仅在系统边界（{boundary}）内实现需求。"
    ],
    "python-be-agent.md": [
        f"- 业务实现：理解{domain}核心业务规则并在后端实现。",
        "- 技术能力：精通 Python Web 框架（FastAPI/Django/Flask）与 ORM。",
        f"- 工程约束：遵循{tech}技术约束与{nfr}质量目标。",
        f"- 边界意识：仅在系统边界（{boundary}）内实现需求。"
    ],
    "react-fe-agent.md": [
        f"- 业务体验：理解{domain}场景下的多角色操作路径与信息架构。",
        "- 前端能力：具备 React/Next.js 开发经验，关注可用性与组件化。",
        f"- 工程约束：遵循{tech}约束与{nfr}指标，保证构建稳定与可测试。",
        f"- 边界意识：遵循系统边界（{boundary}），不扩展无关功能。"
    ],
    "pm-agent.md": [
        f"- 业务理解：熟悉{domain}的核心流程、角色权限与数据口径。",
        "- 产品经验：具备管理系统（B端）产品设计经验，能够输出可验收的 PRD/用户故事。",
        f"- 约束意识：在设计中落实技术约束（{tech}）与非功能约束（{nfr}）。",
        f"- 边界把控：明确系统边界（{boundary}），避免需求越界。"
    ],
    "arch-agent.md": [
        f"- 领域建模：能将{domain}抽象为清晰的领域模型、模块边界与服务边界。",
        f"- 技术架构：基于{tech}设计可演进架构，兼顾性能、安全、可维护性。",
        f"- 质量目标：架构需满足非功能约束（{nfr}），并可被测试验证。",
        f"- 兼容约束：严格遵循系统边界（{boundary}）与现有规范。"
    ],
    "java-be-agent.md": [
        f"- 业务实现：理解{domain}核心业务规则并在后端实现可审计、可追溯逻辑。",
        "- 技术能力：精通 Spring Boot/MySQL 典型分层、事务、一致性与异常处理。",
        f"- 工程约束：遵循{tech}技术约束与{nfr}质量目标。",
        f"- 边界意识：仅在系统边界（{boundary}）内实现需求。"
    ],
    "vue-fe-agent.md": [
        f"- 业务体验：理解{domain}场景下的多角色操作路径与信息架构。",
        "- 前端能力：具备 Vue 管理后台开发经验，关注可用性、一致性与易用性。",
        f"- 工程约束：遵循{tech}约束与{nfr}指标，保证构建稳定与可测试。",
        f"- 边界意识：遵循系统边界（{boundary}），不扩展无关功能。"
    ],
    "qa-agent.md": [
        f"- 业务测试：理解{domain}关键流程，能设计覆盖角色与流程的测试方案。",
        "- 测试能力：擅长接口/功能/UI 自动化测试（含 Playwright）。",
        f"- 质量目标：测试策略需对齐{nfr}，形成可追溯证据链。",
        f"- 边界意识：围绕系统边界（{boundary}）构建测试范围。"
    ],
    "devops-agent.md": [
        f"- 发布运维：理解{domain}系统的发布节奏与运行特征。",
        "- 平台能力：具备 CI/CD、环境隔离、监控告警、日志追踪能力。",
        f"- 质量目标：发布与运维策略需满足{nfr}。",
        f"- 边界意识：遵循系统边界（{boundary}）与合规要求。"
    ],
    "code-reviewer.md": [
        f"- 业务理解：熟悉{domain}核心流程，能识别业务逻辑错误。",
        f"- 技术审查：基于{tech}技术栈审查代码质量与安全。",
        f"- 质量对齐：审查标准对齐{nfr}。",
    ],
}

for name, lines in agent_blocks.items():
    f = project / ".claude" / "agents" / name
    if not f.exists():
        continue
    txt = f.read_text(encoding="utf-8")
    pattern = re.compile(r"(<!-- DYNAMIC_INJECT_START -->)(.*?)(<!-- DYNAMIC_INJECT_END -->)", re.S)
    block = "\n" + "\n".join(lines) + "\n"
    if pattern.search(txt):
        txt = pattern.sub(r"\1" + block + r"\3", txt)
    else:
        txt += "\n\n<!-- DYNAMIC_INJECT_START -->\n" + "\n".join(lines) + "\n<!-- DYNAMIC_INJECT_END -->\n"
    f.write_text(txt, encoding="utf-8")
PY

# Register project
mkdir -p "$(dirname "$REGISTRY")"
if [ ! -f "$REGISTRY" ]; then
  cat > "$REGISTRY" <<JSON
{
  "projects": []
}
JSON
fi
python3 - <<PY
import json
reg = "$REGISTRY"
obj = json.load(open(reg))
projects = obj.get("projects", [])
found = False
for p in projects:
    if p.get("id") == "$PROJECT_ID":
        p.update({
          "name": "$PROJECT_NAME",
          "path": "$PROJECT_PATH",
          "techStack": "$TECH_STACK",
          "status": "active",
          "lastActivity": "$NOW_DATE"
        })
        found = True
        break
if not found:
    projects.append({
      "id": "$PROJECT_ID",
      "name": "$PROJECT_NAME",
      "path": "$PROJECT_PATH",
      "techStack": "$TECH_STACK",
      "status": "active",
      "createdAt": "$NOW_DATE",
      "lastActivity": "$NOW_DATE"
    })
obj["projects"] = projects
open(reg, "w").write(json.dumps(obj, ensure_ascii=False, indent=2))
PY

echo "INIT_OK project=$PROJECT_ID path=$PROJECT_PATH"
