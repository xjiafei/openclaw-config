# testing/ — 测试目录

所有测试产物统一存放在此目录下。

| 子目录 | 用途 |
|--------|------|
| `e2e/` | Playwright E2E 测试脚本 + playwright.config.js |
| `integration/` | API 集成测试脚本（curl、httpie、RestAssured 等） |
| `data/` | 测试种子数据、fixtures、mock 数据 |
| `reports/` | 测试报告、用例执行结果 |
| `performence/` | 性能/压力测试脚本 |

**例外**：后端单元测试遵循 Maven/Gradle 约定，放在 `{backend}/src/test/`。
