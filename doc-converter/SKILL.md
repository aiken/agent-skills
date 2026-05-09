---
name: doc-converter
description: Convert documents between various formats (Markdown, DOCX, PDF, HTML) with intelligent dependency detection and Chinese language support. Gracefully handles missing LaTeX by providing fallback options. Also covers browser headless PDF generation (Edge/Chrome) for client-facing documents. Use when Kimi needs to: (1) convert between document formats, (2) generate PDF from Markdown/HTML using pandoc, LaTeX, or browser headless mode, (3) produce client-facing PDFs where local file paths must not leak.
---

# Document Converter

> **Environment**: This skill provides both **PowerShell** (`.ps1`) and **Python** (`.py`) scripts.  
> When running in **Git Bash**, use the `.py` scripts with standard Bash syntax.  
> The Python scripts are cross-platform and work identically in Git Bash, PowerShell, and Linux/macOS.

A robust document conversion tool that converts between Markdown, DOCX, PDF, and HTML formats. Features intelligent LaTeX detection, Chinese language support, and graceful degradation when dependencies are missing.

## Features

- ✅ **Multi-format support**: Markdown ↔ DOCX ↔ PDF ↔ HTML
- ✅ **LaTeX detection**: Automatically detects available PDF engines
- ✅ **Chinese support**: Optimized for CJK documents with XeLaTeX
- ✅ **Graceful degradation**: Falls back to HTML when LaTeX unavailable
- ✅ **Batch conversion**: Convert multiple files at once

## Prerequisites

### Required
- **Pandoc** (>= 2.0): [Download](https://pandoc.org/installing.html)

### For PDF Generation (any of the following)
| Tool | Quality | Chinese Support | Platform |
|------|---------|-----------------|----------|
| **Microsoft Word** | ⭐⭐⭐ Best | ✅ Excellent | Windows only |
| **XeLaTeX** | ⭐⭐⭐ Best | ✅ Excellent | All platforms |
| **LibreOffice** | ⭐⭐ Good | ✅ Good | All platforms |
| **pdflatex** | ⭐⭐ Good | ⚠️ Limited | All platforms |

**Recommendation for Windows users:** Microsoft Word COM automation provides the best DOCX→PDF conversion quality and requires no additional installation if Office is already installed.

## Quick Start

### Git Bash / Cross-Platform (Python)

```bash
# Convert Markdown to PDF
python "$HOME/.config/agents/skills/doc-converter/scripts/convert.py" document.md document.pdf

# Convert DOCX to PDF
python "$HOME/.config/agents/skills/doc-converter/scripts/convert.py" document.docx document.pdf

# Force XeLaTeX for Chinese documents
python "$HOME/.config/agents/skills/doc-converter/scripts/convert.py" report.md report.pdf --pdf-engine xelatex

# Check available converters
python "$HOME/.config/agents/skills/doc-converter/scripts/check_deps.py"
```

### PowerShell (Legacy .ps1)

```powershell
& "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\convert.ps1" `
    -InputFile "document.md" `
    -OutputFile "document.pdf"

& "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\convert.ps1" `
    -InputFile "document.docx" `
    -OutputFile "document.pdf"

& "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\check_deps.ps1"
```

## Scripts Reference

### convert.ps1

Main conversion script with automatic format detection and LaTeX handling.

**Parameters:**
- `-InputFile` (required): Source file path
- `-OutputFile` (required): Target file path
- `-PdfEngine` (optional): Specify PDF engine (`xelatex`, `pdflatex`, `auto`)

**Examples:**
```powershell
# Auto-detect best PDF engine
& scripts/convert.ps1 -InputFile "report.md" -OutputFile "report.pdf"

# Force XeLaTeX for Chinese documents
& scripts/convert.ps1 -InputFile "report.md" -OutputFile "report.pdf" -PdfEngine xelatex

# Convert DOCX to Markdown
& scripts/convert.ps1 -InputFile "document.docx" -OutputFile "document.md"

# Fallback to HTML if no LaTeX
& scripts/convert.ps1 -InputFile "document.md" -OutputFile "document.html"
```

### check_deps.ps1

Check available converters and dependencies.

**Example:**
```powershell
& scripts/check_deps.ps1
# Output:
# ✓ Pandoc: 3.6.3
# ✓ XeLaTeX: available (recommended for Chinese)
# ✗ pdflatex: not found
```

### batch_convert.ps1

Convert multiple files at once.

**Parameters:**
- `-InputFiles` (required): Array of input file paths
- `-OutputFormat` (required): Target format (`pdf`, `html`, `docx`, `md`)
- `-OutputDir` (optional): Output directory

**Example:**
```powershell
$files = Get-ChildItem "*.md" | Select-Object -ExpandProperty FullName
& scripts/batch_convert.ps1 -InputFiles $files -OutputFormat pdf -OutputDir "output/"
```

## Workflow Patterns

### Pattern 1: Chinese Document to PDF

```powershell
# Check if XeLaTeX is available
$deps = & "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\check_deps.ps1"

if ($deps -match "xelatex.*available") {
    # Use XeLaTeX for proper Chinese rendering
    & "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\convert.ps1" `
        -InputFile "chinese_report.md" `
        -OutputFile "chinese_report.pdf" `
        -PdfEngine xelatex
} else {
    Write-Host "Warning: XeLaTeX not found. Installing TinyTeX..."
    # Or fallback to DOCX then use Word to convert
    & "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\convert.ps1" `
        -InputFile "chinese_report.md" `
        -OutputFile "chinese_report.docx"
}
```

### Pattern 2: Graceful PDF Generation

```powershell
# Try PDF first, fallback to HTML
$inputFile = "document.md"
$outputPdf = "document.pdf"
$outputHtml = "document.html"

try {
    & "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\convert.ps1" `
        -InputFile $inputFile `
        -OutputFile $outputPdf
    Write-Host "PDF generated successfully"
} catch {
    Write-Host "PDF generation failed, falling back to HTML..."
    & "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\convert.ps1" `
        -InputFile $inputFile `
        -OutputFile $outputHtml
}
```

### Pattern 3: DOCX to PDF with Company Template

```powershell
# Convert DOCX quote to PDF (automatically uses best available method)
& "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\convert.ps1" `
    -InputFile "甲苯报价单_香港椋鸟.docx" `
    -OutputFile "甲苯报价单_香港椋鸟.pdf"

# On Windows with Microsoft Office installed, this will use Word COM
# for highest quality conversion. No additional setup needed!
```

### Pattern 4: Check Available Converters

```powershell
# Check what conversion tools are available on your system
& "$env:USERPROFILE\.config\agents\skills\doc-converter\scripts\check_deps.ps1"

# Example output on Windows with Office:
# ✓ Pandoc: 3.6.3
# ✓ Microsoft Word COM: available (best for DOCX->PDF)
# ✗ XeLaTeX: Not found
# ✗ LibreOffice: Not found
```

## LaTeX Installation Guide

### Windows (TinyTeX - Recommended)
```powershell
# Install TinyTeX (lightweight, ~100MB)
Invoke-WebRequest -Uri "https://yihui.org/tinytex/install-bin-windows.bat" -OutFile "install-tinytex.bat"
.\install-tinytex.bat
```

### macOS
```bash
brew install --cask mactex-no-gui
# Or minimal install:
brew install --cask basictex
```

### Linux
```bash
sudo apt-get update
sudo apt-get install texlive-xetex texlive-lang-chinese
```

## Troubleshooting

### "No LaTeX installation found"
**Solution**: Install TinyTeX or MiKTeX (see Installation Guide above)

### Chinese characters not displaying
**Solution**: Use XeLaTeX instead of pdflatex:
```powershell
& scripts/convert.ps1 -InputFile "doc.md" -OutputFile "doc.pdf" -PdfEngine xelatex
```

### DOCX to PDF fails
**Solution**: The skill automatically tries multiple methods in order:
1. ✅ **Microsoft Word COM** (Windows, best quality)
2. ✅ **LibreOffice** headless mode
3. ⚠️ **Pandoc fallback**: DOCX → Markdown → PDF

If all methods fail, you can manually open the DOCX in Word and "Save As" PDF.

### PDF generation is slow
**Solution**: First conversion downloads LaTeX packages. Subsequent conversions will be faster.

## Python Script Reference

When using Git Bash or any cross-platform shell, use the `.py` scripts with standard CLI arguments:

| Script | Usage Example |
|--------|--------------|
| `convert.py` | `python convert.py input.md output.pdf [--pdf-engine xelatex]` |
| `check_deps.py` | `python check_deps.py` |
| `batch_convert.py` | `python batch_convert.py *.md -f pdf [-o output_dir] [--pdf-engine auto]` |

## Browser Headless PDF Generation (Windows)

When generating client-facing PDFs from Markdown via **pandoc → HTML → Edge headless**, follow these security and quality rules strictly.

### Security Checklist

| # | Rule | Rationale |
|---|------|-----------|
| 1 | `--embed-resources` in pandoc | Inlines CSS/images so the temporary HTML has no external file references |
| 2 | `--no-pdf-header-footer` in Edge | Prevents Edge from printing the source URL (`file:///D:/...`) in the PDF header |
| 3 | Delete temp HTML after generation | Eliminates the source file that contains local paths |
| 4 | Scan PDF for path leakage | Run `findstr`/`strings` on the PDF to confirm no `file://`, `ops_sts`, `pdf-style`, or local usernames remain |
| 5 | Never expose `D:/coding/...` in replies | Local absolute paths must never appear in user-facing output |

### Recommended Pipeline

```powershell
# 1. Markdown → self-contained HTML
pandoc input.md -o _tmp.html --standalone --embed-resources --css=pdf-style.css --metadata title="Doc Title"

# 2. HTML → PDF via Edge headless
$edge = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
Start-Process $edge -ArgumentList "--headless","--disable-gpu","--no-pdf-header-footer","--print-to-pdf=output.pdf",(Resolve-Path _tmp.html) -Wait

# 3. Verify no path leakage
$leaked = Select-String -Path output.pdf -Pattern "file://|ops_sts|pdf-style|D:\\coding" -Quiet
if ($leaked) { Write-Error "PDF contains local paths!"; exit 1 }

# 4. Cleanup
Remove-Item _tmp.html -Force
```

### Print CSS Tips for Complex Tables

When PDF tables have long model names or code blocks that cause overflow:

```css
table { font-size: 7.5pt; margin: 8px 0; page-break-inside: auto; }
th, td { border: 1px solid #bbb; padding: 4px 6px; text-align: left; vertical-align: top; }
td code { white-space: nowrap; }  /* prevent model names from wrapping */
tr { page-break-inside: avoid; }
```

## Limitations

- **DOCX → PDF**: Requires LibreOffice or manual conversion (Pandoc limitation)
- **Complex DOCX**: May lose formatting when converting to Markdown
- **Images**: Relative paths must be correct for image inclusion
- **Fonts**: PDF output uses system fonts; may differ from original document

## License

MIT License - Feel free to use and modify for your needs.
