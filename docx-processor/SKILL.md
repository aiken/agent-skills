---
name: docx-processor
description: Read, extract, and edit Microsoft Word (.docx) documents without requiring Microsoft Office or Python libraries. Use when Kimi needs to work with Word documents for extracting text content, analyzing document structure, or making text replacements. Supports reading document content, structured extraction with paragraph numbers, and text replacement editing.
---

# DOCX Processor

> **Environment**: This skill provides both **PowerShell** (`.ps1`) and **Python** (`.py`) scripts.  
> When running in **Git Bash**, use the `.py` scripts with standard Bash syntax.  
> The Python scripts are cross-platform and work identically in Git Bash, PowerShell, and Linux/macOS.

This skill enables Kimi to work with Microsoft Word (.docx) files using scripts that manipulate the underlying Open XML format directly.

## Quick Start

### Git Bash / Cross-Platform (Python)

```bash
# Reading a document
python "$HOME/.config/agents/skills/docx-processor/scripts/read_docx.py" document.docx

# Extracting with structure
python "$HOME/.config/agents/skills/docx-processor/scripts/extract_docx.py" document.docx -f list

# Editing a document
python "$HOME/.config/agents/skills/docx-processor/scripts/edit_docx.py" document.docx \
    -r "OLD TEXT=NEW TEXT" -r "[Placeholder]=Actual Value" -b
```

### PowerShell (Legacy .ps1)

```powershell
& "$env:USERPROFILE\.config\agents\skills\docx-processor\scripts\read_docx.ps1" `
    -InputFile "document.docx"

& "$env:USERPROFILE\.config\agents\skills\docx-processor\scripts\extract_docx.ps1" `
    -InputFile "document.docx" -Format List

& "$env:USERPROFILE\.config\agents\skills\docx-processor\scripts\edit_docx.ps1" `
    -InputFile "document.docx" `
    -Replacements @{"OLD TEXT"="NEW TEXT"; "[Placeholder]"="Actual Value"} `
    -Backup
```

## Scripts Reference

### read_docx.ps1

Extracts all text content from a .docx file, preserving paragraph breaks.

**Parameters:**
- `-InputFile` (required): Path to the .docx file
- `-OutputFile` (optional): Save to file instead of stdout

**Example:**
```powershell
# Output to console
& scripts/read_docx.ps1 -InputFile "report.docx"

# Save to file
& scripts/read_docx.ps1 -InputFile "report.docx" -OutputFile "content.txt"
```

### extract_docx.ps1

Extracts structured content with paragraph indexing. Useful for identifying specific text to modify.

**Parameters:**
- `-InputFile` (required): Path to the .docx file  
- `-OutputFile` (optional): Save to file
- `-Format` (optional): `Text`, `List` (default), or `Json`

**Example:**
```powershell
# Get numbered list of paragraphs
& scripts/extract_docx.ps1 -InputFile "report.docx" -Format List

# Get JSON for programmatic processing
& scripts/extract_docx.ps1 -InputFile "report.docx" -Format Json -OutputFile "content.json"
```

### edit_docx.ps1

Modifies a .docx file by replacing specified text strings.

**Parameters:**
- `-InputFile` (required): Path to the .docx file
- `-OutputFile` (optional): Save to new file (defaults to overwrite input)
- `-Replacements` (required): Hashtable of text replacements
- `-Backup` (optional switch): Create .backup file before editing

**Example:**
```powershell
# Simple replacement with backup
& scripts/edit_docx.ps1 -InputFile "template.docx" -Backup `
    -Replacements @{"[DATE]"="2024-01-15"; "[CLIENT]"="Acme Corp"}

# Save to new file
& scripts/edit_docx.ps1 -InputFile "template.docx" -OutputFile "filled.docx" `
    -Replacements @{"[NAME]"="John Smith"}
```

## Workflow Patterns

### Pattern 1: Read and Analyze

1. Extract content with paragraph numbers
2. Identify target text to modify
3. Plan replacements

```powershell
# Step 1: Extract with structure
& scripts/extract_docx.ps1 -InputFile "doc.docx" -Format List

# Step 2: Identify text to change (e.g., paragraph 5 contains "OLD TEXT")

# Step 3: Make replacements
& scripts/edit_docx.ps1 -InputFile "doc.docx" -Backup `
    -Replacements @{"OLD TEXT"="NEW TEXT"}
```

### Pattern 2: Template Filling

Replace multiple placeholders in a template document:

```powershell
$replacements = @{
    "[COMPANY]" = "Starling Droid"
    "[EMAIL]" = "sales@starlingdroid.com"
    "[DATE]" = (Get-Date -Format "yyyy-MM-dd")
}

& scripts/edit_docx.ps1 -InputFile "template.docx" -OutputFile "output.docx" `
    -Replacements $replacements
```

### Pattern 3: Content Cleanup

Remove or replace unwanted text sections:

```powershell
# Remove a section by replacing with empty string
& scripts/edit_docx.ps1 -InputFile "doc.docx" -Backup `
    -Replacements @{"Unwanted paragraph text."=""}
```

## Python Script Reference

When using Git Bash or any cross-platform shell, use the `.py` scripts with standard CLI arguments:

| Script | Usage Example |
|--------|--------------|
| `read_docx.py` | `python read_docx.py document.docx [-o output.txt]` |
| `extract_docx.py` | `python extract_docx.py document.docx [-o output.txt] [-f text/list/json]` |
| `edit_docx.py` | `python edit_docx.py document.docx -r "OLD=NEW" [-o output.docx] [-b]` |
| `edit_docx_advanced.py` | `python edit_docx_advanced.py document.docx -r "OLD=NEW" [-o output.docx] [-b]` |

## Advanced Usage with python-docx

For complex formatting (fonts, paragraph styles, tables, page margins), use `python-docx` instead of direct XML editing.

### Prerequisites

```bash
pip install python-docx
```

### Generate a Formatted Document (Chinese Contract Example)

```python
from docx import Document
from docx.shared import Pt, Inches, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml.ns import qn

def set_font(run, font_name='宋体', size=10.5, bold=False):
    run.font.name = font_name
    run._element.rPr.rFonts.set(qn('w:eastAsia'), font_name)
    run.font.size = Pt(size)
    run.font.bold = bold

doc = Document()
sections = doc.sections[0]
sections.top_margin = Inches(1)
sections.bottom_margin = Inches(1)
sections.left_margin = Inches(1.2)
sections.right_margin = Inches(1.2)

# Title
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
run = p.add_run('Document Title')
run.font.name = '黑体'
run._element.rPr.rFonts.set(qn('w:eastAsia'), '黑体')
run.font.size = Pt(22)
run.font.bold = True

# Body with first-line indent and 1.5 line spacing
p = doc.add_paragraph()
run = p.add_run('Body text content...')
set_font(run, '宋体', 10.5)
p.paragraph_format.first_line_indent = Inches(0.45)
p.paragraph_format.line_spacing_rule = WD_LINE_SPACING.ONE_POINT_FIVE

doc.save('output.docx')
```

### Batch Text Replacement (Format-Preserving)

Safer than XML editing for formatted documents:

```python
from docx import Document

doc = Document('contract.docx')
for para in doc.paragraphs:
    for run in para.runs:
        if 'OLD TEXT' in run.text:
            run.text = run.text.replace('OLD TEXT', 'NEW TEXT')
doc.save('contract_updated.docx')
```

**Why `run`-level replacement:** In Word, formatting (bold, color, font) is applied at the `run` level, not the paragraph level. Replacing at the paragraph level (`para.text = ...`) destroys all formatting. Always iterate `para.runs` when format must be preserved.

### Add a Styled Table

```python
table = doc.add_table(rows=2, cols=2)
table.style = 'Table Grid'
table.autofit = False
table.columns[0].width = Inches(3.2)
table.columns[1].width = Inches(3.2)

table.cell(0, 0).text = 'Party A'
table.cell(0, 1).text = 'Party B'
```

## Limitations

- **Text-only (XML scripts)**: Works with text content. Complex formatting, tables, images are preserved but not directly editable via text replacement.
- **String matching (XML scripts)**: Replacements are literal string matches. Regex is not supported.
- **XML encoding**: Replacement text should not contain XML special characters (`<`, `>`, `&`) as they are automatically escaped.
- **python-docx**: Cannot edit existing tables or headers/footers directly. For those, use the XML scripts or recreate the document.

## Troubleshooting

**Issue**: Document appears corrupted after editing
- The -Backup switch creates a .backup file before editing
- Always use -Backup when editing in-place

**Issue**: Chinese or special characters display incorrectly
- The scripts handle UTF-8 encoding correctly
- If issues persist, verify the source document is properly UTF-8 encoded

**Issue**: Replacement didn't work
- Verify the exact text using extract_docx.ps1 with -Format List
- Check for hidden characters or different whitespace
