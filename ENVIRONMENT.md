# System Environment Report

> Generated: 2026-05-09
> Maintainer: agent-skills admin
> Scope: Windows 开发环境盘点与问题记录

---

## 1. 操作系统

| 属性 | 值 |
|------|-----|
| OS | Windows 10/11 |
| Shell (Shell Tool) | Windows PowerShell 5.1 |
| Git Bash | `C:\Program Files\Git\usr\bin\bash.exe` (可用) |

**重要**：Shell Tool 在 Windows 下执行的是 **PowerShell**，不是 CMD。所有命令需使用 PowerShell 语法。

---

## 2. Python 环境

| 安装项 | 路径 | 版本 | 状态 |
|--------|------|------|------|
| **系统 Python** | `C:\Users\aiken\AppData\Local\Programs\Python\Python310\python.exe` | 3.10.11 | ✅ 正常 |
| pip | `...\Python310\Scripts\pip.exe` | 23.0.1 | ✅ 正常 |
| **Windows Store Python** | `...\Microsoft\WindowsApps\python.exe` | — | ❌ 损坏/未启用 |
| **Python 3.13** | `...\Python\Python313\` | — | ❌ 已清理（残留） |

### PATH 说明
- 系统 Python 已加入用户 PATH，排在最前面
- 如果 `python --version` 在新终端中无输出，说明 Windows Store 占位符仍在干扰，需从 PATH 中移除 `WindowsApps` 中的 python

### 已安装的关键包
```
PyPDF2        3.0.1
pdfminer.six  20260107
PyMuPDF       1.27.2.2
```

### 虚拟环境
- `D:\coding\py_env\py_venv` — ❌ 已清理（指向已删除的 Python 3.13）
- `C:\comfy\.venv` — ⚠️ 存在但为第三方项目私有，不应作为系统依赖使用

---

## 3. Node.js 环境

| 工具 | 路径 | 版本 | 状态 |
|------|------|------|------|
| node | `C:\Program Files\nodejs\node.exe` | v25.9.0 | ✅ 正常 |
| npm | `...\nodejs\npm.ps1` | 11.12.1 | ✅ 正常 |
| npx | `...\nodejs\npx.ps1` | — | ✅ 正常 |

### 全局 npm 包
```
bun@1.3.13
mdpdf@3.1.0
rollup@4.36.0
```

---

## 4. Go 环境

| 工具 | 路径 | 版本 | 状态 |
|------|------|------|------|
| go | `C:\Program Files\Go\bin\go.exe` | go1.26.2 | ✅ 正常 |

---

## 5. Git / GitHub CLI

| 工具 | 路径 | 版本 | 状态 |
|------|------|------|------|
| git | `C:\Program Files\Git\mingw64\bin\git.exe` | 2.54.0.windows.1 | ✅ 正常 |
| gh | 通过 winget 安装 | 2.88.1 | ✅ 正常（代理: 127.0.0.1:17890） |

---

## 6. 文档处理工具

| 工具 | 路径 | 版本 | 状态 |
|------|------|------|------|
| pandoc | `C:\Users\aiken\AppData\Local\Pandoc\pandoc.exe` | 3.6.3 | ✅ 正常 |
| Edge | `C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe` | — | ✅ 正常 |
| Chrome | `C:\Program Files\Google\Chrome\Application\chrome.exe` | — | ✅ 正常 |

---

## 7. 其他 CLI 工具

| 工具 | 安装方式 | 版本 | 状态 |
|------|----------|------|------|
| **ripgrep** | winget | 15.1.0 | ✅ 已安装（2026-05-09） |
| **7-Zip** | winget | 26.01 | ✅ 已安装（2026-05-09） |
| **FFmpeg** | winget (Essentials) | 8.1.1 | ✅ 已安装（2026-05-09） |
| uv | 独立安装 | 0.10.9 | ✅ 正常 |
| kimi-cli | uv tool | v1.38.0 | ✅ 正常 |

### 未安装的工具（按需安装）

| 工具 | 场景 | 安装命令 |
|------|------|----------|
| Docker Desktop | 容器化部署 | `winget install Docker.DockerDesktop` |
| Java JDK | Java / Android 开发 | `winget install Oracle.JDK.21` |
| .NET SDK | .NET 项目 | `winget install Microsoft.DotNet.SDK.9` |
| Rust | 编译 Rust 工具 | 通过 rustup 安装 |
| fzf | 交互式过滤 | `winget install junegunn.fzf` |

---

## 8. 已知问题与解决方案

### 8.1 Shell 工具重定向语法

| 环境 | stderr 重定向到 null | 是否可用 |
|------|---------------------|----------|
| **PowerShell** (Shell Tool 默认) | `2>$null` | ✅ |
| PowerShell | `2>nul` | ❌ 报错：FileStream was asked to open a device... |
| Git Bash | `2>/dev/null` | ✅ |
| CMD | `2>nul` | ✅ |

### 8.2 Edge Headless PDF 生成缓存问题

**现象**：HTML 修改后重新生成 PDF，文件大小不变，内容未更新。

**根因**：Edge 浏览器已运行时，headless 实例可能复用已有进程的缓存。

**推荐命令**（基于 Chromium 官方文档）：
```powershell
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
$tempProfile = "C:\Temp\edge-pdf-$(Get-Random)"

& $edge `
    --headless `
    --disable-gpu `
    --no-pdf-header-footer `
    --user-data-dir="$tempProfile" `
    --incognito `
    --no-first-run `
    --disk-cache-size=1 `
    --print-to-pdf="output.pdf" `
    "file:///C:/path/to/input.html"

Remove-Item -Recurse -Force $tempProfile
```

**关键参数说明**：
| 参数 | 来源 | 作用 |
|------|------|------|
| `--user-data-dir=<temp>` | Microsoft Q&A 官方回答 | 强制全新实例，隔离已有 Edge 进程 |
| `--incognito` | Chromium 官方文档 | 隐身模式，不缓存页面 |
| `--no-first-run` | Chromium switches | 跳过首次运行体验 |
| `--disk-cache-size=1` | Chromium switches | 限制磁盘缓存为 1 byte |

### 8.3 PDF 中文内容验证

- `findstr` / `Select-String` **无法**直接搜索 PDF 二进制文件中的文本
- 正确方案：使用 `pdfminer.six` 或 `PyMuPDF` 提取文本后验证
- 前提：HTML 中必须正确指定中文字体（如 `font-family: "Microsoft YaHei", "SimSun"`）

```python
from pdfminer.high_level import extract_text
text = extract_text("output.pdf")
assert "目标中文" in text
```

---

## 9. 环境修复记录

| 日期 | 操作 | 状态 |
|------|------|------|
| 2026-05-09 | 修复 Python PATH，将 Python 3.10 置顶 | ✅ |
| 2026-05-09 | 清理 Python 3.13 残留目录和注册表 | ✅ |
| 2026-05-09 | 清理失效虚拟环境 `D:\coding\py_env\py_venv` | ✅ |
| 2026-05-09 | 安装 ripgrep + 7-Zip + FFmpeg (Essentials) | ✅ |

---

## 10. Agent 使用速查

```powershell
# Python（系统安装）
python --version          # Python 3.10.11
python -m pip install ...

# PDF 文本提取验证
python -c "from pdfminer.high_level import extract_text; print(extract_text('file.pdf'))"

# 极速搜索（替代 findstr）
rg "pattern" path/        # ripgrep，支持 Unicode

# 解压
7z x archive.zip -o./dest

# 视频处理
ffmpeg -i input.mp4 -ss 00:00:05 -vframes 1 output.png
```
