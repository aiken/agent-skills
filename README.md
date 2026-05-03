# agent-skills

跨平台、跨框架的 Agent Skills 仓库。

## 设计原则

- **平台自适应**：每个 Skill 内部处理 Windows / macOS / Linux 差异，不在仓库顶层按平台分目录
- **框架无关**：Skill 描述使用通用格式，未来可适配 Kimi CLI、Claude Code、Cursor Agent 等不同框架
- **单一职责**：每个 Skill 只解决一个领域问题

## 目录结构

```
.
├── <skill-name>/          # 每个 Skill 一个目录
│   ├── SKILL.md           # 核心文档（必须）
│   └── ...                # 辅助脚本或资源
├── .gitignore
└── README.md
```

## 使用方式

### Kimi CLI

这些 Skill 位于 Kimi CLI 默认扫描路径：
- Windows: `%USERPROFILE%\.config\agents\skills`
- macOS/Linux: `~/.config/agents/skills`

### 其他 Agent 框架

各框架读取 `SKILL.md` 文件即可，文档格式为通用 Markdown，无特殊耦合。

## Skill 清单

| Skill | 说明 |
|-------|------|
| doc-converter | 文档格式转换（Markdown/DOCX/PDF/HTML） |
| docx-processor | 无 Office 依赖的 DOCX 读写 |
| lark-cli | 飞书/Lark CLI 操作（任务、文档、表格、IM） |
| pdf-processor | PDF 文本提取、合并、拆分 |
| scanned-pdf-processor | 扫描版 PDF 处理 |
| volcengine-cloud | 火山引擎云资源管理 |

## 新增 Skill 规范

1. 新建目录 `<skill-name>/`
2. 必须包含 `SKILL.md`，包含：说明、使用场景、示例
3. 如涉平台差异，在文档内分块标注 `<!-- Windows -->` / `<!-- macOS -->`，或提供自适应命令
4. 不提交二进制归档（`.zip`、`.tar.gz`），使用 `.gitignore` 排除
