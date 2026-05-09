---
name: pdf-processor
description: Process and manipulate PDF files including text extraction, merging, splitting, and image conversion. Use when Kimi needs to work with PDFs for extracting text content, combining multiple PDFs, splitting pages, converting images to PDF, or analyzing PDF metadata.
---

# PDF Processor

> **Environment**: This skill provides both **PowerShell** (`.ps1`) and **Python** (`.py`) scripts.  
> When running in **Git Bash**, use the `.py` scripts with standard Bash syntax.  
> The Python scripts are cross-platform and work identically in Git Bash, PowerShell, and Linux/macOS.

This skill enables Kimi to work with PDF files using Python scripts.

## Prerequisites

This skill requires Python with the following packages:

```bash
pip install PyPDF2 Pillow pdfplumber
```

Optional: Install [xpdf](https://www.xpdfreader.com/) for better text extraction performance.

## Quick Start

### Git Bash / Cross-Platform (Python)

```bash
# Extract text from PDF
python "$HOME/.config/agents/skills/pdf-processor/scripts/extract_text.py" document.pdf

# Merge multiple PDFs
python "$HOME/.config/agents/skills/pdf-processor/scripts/merge_pdfs.py" \
    file1.pdf file2.pdf file3.pdf -o merged.pdf

# Split PDF into pages
python "$HOME/.config/agents/skills/pdf-processor/scripts/split_pdf.py" document.pdf \
    -p 1-5 -o "page_{}.pdf"

# Convert images to PDF
python "$HOME/.config/agents/skills/pdf-processor/scripts/images_to_pdf.py" \
    img1.jpg img2.png -o output.pdf

# Get PDF information
python "$HOME/.config/agents/skills/pdf-processor/scripts/pdf_info.py" document.pdf
```

### PowerShell (Legacy .ps1)

```powershell
& "$env:USERPROFILE\.config\agents\skills\pdf-processor\scripts\extract_text.ps1" `
    -InputFile "document.pdf"

& "$env:USERPROFILE\.config\agents\skills\pdf-processor\scripts\merge_pdfs.ps1" `
    -InputFiles @("file1.pdf", "file2.pdf", "file3.pdf") `
    -OutputFile "merged.pdf"

& "$env:USERPROFILE\.config\agents\skills\pdf-processor\scripts\split_pdf.ps1" `
    -InputFile "document.pdf" `
    -PageRange "1-5" `
    -OutputPattern "page_{0}.pdf"

& "$env:USERPROFILE\.config\agents\skills\pdf-processor\scripts\images_to_pdf.ps1" `
    -InputFiles @("img1.jpg", "img2.png") `
    -OutputFile "output.pdf"

& "$env:USERPROFILE\.config\agents\skills\pdf-processor\scripts\pdf_info.ps1" `
    -InputFile "document.pdf"
```

## Scripts Reference

### extract_text.ps1

Extracts text content from PDF files.

**Parameters:**
- `-InputFile` (required): Path to the PDF file
- `-OutputFile` (optional): Save to file instead of stdout
- `-Pages` (optional): Specific pages to extract (e.g., "1-5,7,10")

**Features:**
- Tries multiple extraction methods (pdftotext, PyPDF2, pdfplumber)
- Preserves layout when possible
- Supports page range selection

**Example:**
```powershell
# Extract all text
& scripts/extract_text.ps1 -InputFile "report.pdf"

# Extract specific pages
& scripts/extract_text.ps1 -InputFile "report.pdf" -Pages "1-10,15,20"

# Save to file
& scripts/extract_text.ps1 -InputFile "report.pdf" -OutputFile "content.txt"
```

### merge_pdfs.ps1

Combines multiple PDF files into a single document.

**Parameters:**
- `-InputFiles` (required): Array of PDF file paths
- `-OutputFile` (required): Output merged PDF path

**Example:**
```powershell
# Merge specific files
& scripts/merge_pdfs.ps1 `
    -InputFiles @("chapter1.pdf", "chapter2.pdf", "chapter3.pdf") `
    -OutputFile "book.pdf"

# Merge all PDFs in directory
Get-ChildItem *.pdf | & scripts/merge_pdfs.ps1 -OutputFile "combined.pdf"
```

### split_pdf.ps1

Splits a PDF into individual pages or page ranges.

**Parameters:**
- `-InputFile` (required): Path to the PDF file
- `-OutputPattern` (optional): Filename pattern (default: "page_{0}.pdf")
- `-PageRange` (optional): Pages to extract (e.g., "1-5,7,10-12")
- `-OutputDir` (optional): Output directory

**Example:**
```powershell
# Split all pages
& scripts/split_pdf.ps1 -InputFile "document.pdf"

# Extract specific pages
& scripts/split_pdf.ps1 `
    -InputFile "document.pdf" `
    -PageRange "1-10" `
    -OutputPattern "chapter1_{0}.pdf"
```

### images_to_pdf.ps1

Converts multiple images into a single PDF file.

**Parameters:**
- `-InputFiles` (required): Array of image paths
- `-OutputFile` (required): Output PDF path
- `-Quality` (optional): JPEG quality 1-100 (default: 85)

**Example:**
```powershell
# Convert specific images
& scripts/images_to_pdf.ps1 `
    -InputFiles @("photo1.jpg", "photo2.png") `
    -OutputFile "album.pdf"

# Convert all JPGs in folder
Get-ChildItem *.jpg | & scripts/images_to_pdf.ps1 -OutputFile "photos.pdf"
```

### pdf_info.ps1

Displays metadata and information about a PDF file.

**Parameters:**
- `-InputFile` (required): Path to the PDF file

**Example:**
```powershell
& scripts/pdf_info.ps1 -InputFile "document.pdf"
```

Output includes:
- Page count
- Title, author, subject (if available)
- Creation/modification dates
- Encryption status
- First page preview

## Workflow Patterns

### Pattern 1: Extract and Analyze

Extract text from PDF for analysis:

```powershell
# Step 1: Extract text
& scripts/extract_text.ps1 -InputFile "report.pdf" -OutputFile "content.txt"

# Step 2: Read extracted content
$content = Get-Content "content.txt" -Raw

# Step 3: Process content as needed
```

### Pattern 2: Organize PDFs

Merge multiple scanned documents:

```powershell
# Get all PDFs sorted by name
$pdfs = Get-ChildItem "scans/*.pdf" | Sort-Object Name | Select-Object -ExpandProperty FullName

# Merge into one document
& scripts/merge_pdfs.ps1 -InputFiles $pdfs -OutputFile "complete_document.pdf"
```

### Pattern 3: Archive Images

Convert photos to PDF archive:

```powershell
# Get all images and convert to PDF
$images = Get-ChildItem "photos/*" -Include *.jpg,*.png | Sort-Object Name
& scripts/images_to_pdf.ps1 -InputFiles $images -OutputFile "archive.pdf"
```

### Pattern 4: Extract Specific Pages

Extract pages from a large document:

```powershell
# Get PDF info first
& scripts/pdf_info.ps1 -InputFile "large.pdf"

# Extract specific section
& scripts/split_pdf.ps1 `
    -InputFile "large.pdf" `
    -PageRange "25-50" `
    -OutputFile "section.pdf"
```

## Troubleshooting

### "Failed to extract text" Error

**Solution:** Install Python dependencies:
```bash
pip install PyPDF2 pdfplumber Pillow
```

### Poor Text Extraction Quality

**Solution:** Try installing xpdf tools for better extraction:
1. Download from https://www.xpdfreader.com/
2. Add to PATH or place in common location

### Encrypted PDFs

**Note:** These scripts cannot process password-protected PDFs. Remove encryption first or provide password handling in custom scripts.

### Large PDFs

For very large PDFs (100+ MB), consider:
- Extracting specific pages instead of full text
- Using streaming approaches with Python
- Splitting into smaller chunks first

## Python Script Reference

When using Git Bash or any cross-platform shell, use the `.py` scripts with standard CLI arguments:

| Script | Usage Example |
|--------|--------------|
| `extract_text.py` | `python extract_text.py document.pdf [-o output.txt] [-p 1-5,7]` |
| `merge_pdfs.py` | `python merge_pdfs.py file1.pdf file2.pdf -o merged.pdf` |
| `split_pdf.py` | `python split_pdf.py document.pdf [-p 1-5] [-o page_{}.pdf] [-d outdir]` |
| `images_to_pdf.py` | `python images_to_pdf.py img1.jpg img2.png -o output.pdf [-q 85]` |
| `pdf_info.py` | `python pdf_info.py document.pdf` |

## PDF to Images

Convert PDF pages to image files (PNG/JPEG) for preview, OCR, or presentation workflows.

### Using Node.js pdf2pic (Windows/PowerShell)

```powershell
# Requires: npm install pdf2pic
$npx pdf2pic -i document.pdf -o ./pages/ -f png
```

### Using Python pdf2image (Cross-platform)

```bash
# Requires: pip install pdf2image
python -c "
from pdf2image import convert_from_path
images = convert_from_path('document.pdf', dpi=200)
for i, img in enumerate(images):
    img.save(f'page_{i+1:02d}.png', 'PNG')
"
```

**Dependencies:** On Windows, also install [Poppler](https://github.com/oschwartz10612/poppler-windows/releases) and add `bin/` to PATH.

### Use Cases

- Generate slide thumbnails from a PDF deck
- Extract pages for image-based OCR (when text extraction fails)
- Create page-by-page previews for review workflows

## Limitations

- **Text extraction accuracy** depends on PDF encoding; scanned documents (images) require OCR
- **Encryption** is not handled; password-protected PDFs need to be decrypted first
- **Complex layouts** (multi-column, tables) may not extract perfectly
- **Interactive elements** (forms, JavaScript) are not preserved in merge/split operations
