# docs/specs — 需求与设计文档

## 全量文档
全量需求、产品、技术设计文档直接放在本目录下：
- `requirements.md` — 需求规格
- `product.md` — 产品设计
- `tech.md` — 技术设计
- `test-plan.md` — 测试方案
- `test-cases.md` — 测试用例集

## 增量特性文档
每个增量特性的文档放在 `features/` 子目录下，以 feature_id 命名：

```
docs/specs/
├── requirements.md          # 全量需求
├── product.md               # 全量产品设计
├── tech.md                  # 全量技术设计
├── test-plan.md             # 全量测试方案
├── test-cases.md            # 全量测试用例
├── features/
│   ├── F001/                # 特性 F001
│   │   ├── requirements.md
│   │   ├── product.md
│   │   ├── tech.md
│   │   ├── test-plan.md
│   │   ├── test-cases.md
│   │   └── merged.md       # 合并记录（交付后生成）
│   └── F002/                # 特性 F002
│       ├── requirements.md
│       ├── product.md
│       └── tech.md
```

## 合并规则
- 特性交付后，将 feature spec 内容合并回全量文档（标注特性 ID）
- **保留 feature 目录用于追溯**，不删除
- 合并记录写入 `features/{feature_id}/merged.md`
