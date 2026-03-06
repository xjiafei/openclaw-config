# quality-gate — 质量把关

## 参数
- `project_path`：业务项目绝对路径

## 规则
1. 文档阶段：完整性/一致性/可执行性评分，>=7 通过
2. implementation/testing 阶段：必须执行全量回归测试
   - 后端：`cd {project_path}/backend && mvn test`
   - 前端：`cd {project_path}/frontend && npm test`
3. 任一全量测试失败，直接判定 `fail`
4. 输出 review 到 `{project_path}/workspace/sessions/{timestamp}-review.json`
