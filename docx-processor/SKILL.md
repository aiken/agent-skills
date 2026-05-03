---
name: docx-processor
description: Read, extract, and edit Microsoft Word (.docx) documents without requiring Microsoft Office or Python libraries. Use when Kimi needs to work with Word documents for extracting text content, analyzing document structure, or making text replacements. Supports reading document content, structured extraction with paragraph numbers, and text replacement editing.
---

# DOCX Processor

This skill enables Kimi to work with Microsoft Word (.docx) files using PowerShell scripts that manipulate the underlying Open XML format directly.

## Quick Start

### Reading a Document

Extract plain text from a .docx file:

```powershell
& "$env:USERPROFILE\.config\agents\skills\docx-processor\scripts\read_docx.ps1" `
    -InputFile "document.docx"
```

### Extracting with Structure

Get numbered paragraphs for analysis:

```powershell
& "$env:USERPROFILE\.config\agents\skills\docx-processor\scripts\extract_docx.ps1" `
    -InputFile "document.docx" -Format List
```

### Editing a Document

Replace text in a document:

```powershell
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

## Limitations

- **Text-only**: Works with text content. Complex formatting, tables, images are preserved but not directly editable via text replacement.
- **String matching**: Replacements are literal string matches. Regex is not supported.
- **XML encoding**: Replacement text should not contain XML special characters (`<`, `>`, `&`) as they are automatically escaped.

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
