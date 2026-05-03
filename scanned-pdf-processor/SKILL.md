---
name: scanned-pdf-processor
description: Process scanned PDF documents including OCR text extraction, image conversion, visual analysis, and layout preservation. Designed for handling image-based PDFs, scanned documents, and files where standard text extraction fails.
---

# Scanned PDF Processor

This skill enables Kimi to work with **scanned PDF documents** and image-based PDFs using OCR, image conversion, and visual analysis techniques.

## Overview

Unlike standard PDFs with embedded text, scanned PDFs are essentially images. This skill provides tools to:
- Convert PDF pages to images for visual analysis
- Perform OCR to extract text from scanned pages
- Handle complex layouts (tables, forms, mixed content)
- Process multi-page scanned documents

## Prerequisites

This skill requires Python with the following packages:

```bash
pip install PyMuPDF Pillow pytesseract pdf2image
```

Optional but recommended:
- **Tesseract-OCR**: For OCR text extraction
  - Windows: Download from https://github.com/UBKMannheim/tesseract/wiki
  - Mac: `brew install tesseract`
  - Linux: `sudo apt-get install tesseract-ocr`

- **Poppler**: For pdf2image conversion
  - Windows: Download from https://github.com/oschwartz10612/poppler-windows/releases
  - Mac: `brew install poppler`
  - Linux: `sudo apt-get install poppler-utils`

## Quick Start

### Convert PDF to Images

```powershell
& "$env:USERPROFILE\.config\agents\skills\scanned-pdf-processor\scripts\pdf_to_images.ps1" `
    -InputFile "scanned_document.pdf" `
    -OutputDir "./images" `
    -Dpi 300
```

### Extract Text with OCR

```powershell
& "$env:USERPROFILE\.config\agents\skills\scanned-pdf-processor\scripts\ocr_extract.ps1" `
    -InputFile "scanned_document.pdf" `
    -OutputFile "extracted_text.txt" `
    -Language "chi_sim+eng"
```

### Analyze Scanned Document

```powershell
& "$env:USERPROFILE\.config\agents\skills\scanned-pdf-processor\scripts\analyze_scanned.ps1" `
    -InputFile "scanned_document.pdf" `
    -Mode "visual"
```

## Scripts Reference

### pdf_to_images.ps1

Converts PDF pages to high-quality images for visual analysis.

**Parameters:**
- `-InputFile` (required): Path to the scanned PDF
- `-OutputDir` (optional): Output directory for images (default: ./pdf_images)
- `-Dpi` (optional): Resolution in DPI (default: 300, recommended: 300-600)
- `-Format` (optional): Image format - png, jpg, tiff (default: png)
- `-Pages` (optional): Specific pages to convert (e.g., "1-5,7,10")

**Example:**
```powershell
# Convert all pages to PNG at 300 DPI
& scripts/pdf_to_images.ps1 -InputFile "contract.pdf"

# Convert specific pages at high resolution
& scripts/pdf_to_images.ps1 `
    -InputFile "contract.pdf" `
    -Dpi 600 `
    -Pages "1-10,15" `
    -Format jpg

# Batch convert multiple PDFs
Get-ChildItem *.pdf | & scripts/pdf_to_images.ps1 -Dpi 300
```

### ocr_extract.ps1

Extracts text from scanned PDFs using OCR (Optical Character Recognition).

**Parameters:**
- `-InputFile` (required): Path to the scanned PDF
- `-OutputFile` (optional): Save text to file (default: stdout)
- `-Language` (optional): OCR language(s) (default: chi_sim+eng)
- `-Pages` (optional): Specific pages to process
- `-PreserveLayout` (optional): Maintain original layout (default: true)

**Supported Languages:**
- `eng` - English
- `chi_sim` - Simplified Chinese
- `chi_tra` - Traditional Chinese
- `jpn` - Japanese
- `kor` - Korean
- `chi_sim+eng` - Chinese and English (recommended for mixed content)

**Example:**
```powershell
# Extract Chinese text
& scripts/ocr_extract.ps1 -InputFile "chinese_contract.pdf" -Language "chi_sim"

# Extract mixed Chinese-English content
& scripts/ocr_extract.ps1 `
    -InputFile "invoice.pdf" `
    -Language "chi_sim+eng" `
    -OutputFile "text_content.txt"

# Process specific pages
& scripts/ocr_extract.ps1 `
    -InputFile "document.pdf" `
    -Pages "5-20" `
    -PreserveLayout $true
```

### analyze_scanned.ps1

Comprehensive analysis of scanned documents with multiple modes.

**Parameters:**
- `-InputFile` (required): Path to the scanned PDF
- `-Mode` (optional): Analysis mode
  - `visual` - Convert to images for visual inspection
  - `text` - OCR text extraction
  - `full` - Both visual and text analysis
  - `structure` - Analyze document structure/layout
- `-OutputDir` (optional): Output directory for results

**Example:**
```powershell
# Full analysis
& scripts/analyze_scanned.ps1 `
    -InputFile "complex_form.pdf" `
    -Mode "full" `
    -OutputDir "./analysis_results"

# Structure analysis for forms
& scripts/analyze_scanned.ps1 `
    -InputFile "application_form.pdf" `
    -Mode "structure"
```

### extract_tables.ps1

Extracts tables from scanned PDFs using advanced OCR and layout analysis.

**Parameters:**
- `-InputFile` (required): Path to the scanned PDF
- `-OutputFile` (optional): Output CSV/Excel file
- `-Pages` (optional): Specific pages containing tables

**Example:**
```powershell
& scripts/extract_tables.ps1 `
    -InputFile "invoice.pdf" `
    -OutputFile "tables.csv"
```

## Workflow Patterns

### Pattern 1: Visual Inspection of Scanned Document

When you need to "see" what is in a scanned PDF:

```powershell
# Step 1: Convert to images
& scripts/pdf_to_images.ps1 `
    -InputFile "scanned_contract.pdf" `
    -Dpi 300

# Step 2: Images are now in ./pdf_images/ folder
# You can view them or use with vision-capable AI models
Get-ChildItem ./pdf_images/*.png
```

### Pattern 2: Text Extraction from Scanned PDF

When standard text extraction fails:

```powershell
# Check if it is a scanned PDF (no text layer)
& "$env:USERPROFILE\.config\agents\skills\pdf-processor\scripts\pdf_info.ps1" `
    -InputFile "document.pdf"

# If it is scanned, use OCR
& scripts/ocr_extract.ps1 `
    -InputFile "document.pdf" `
    -Language "chi_sim+eng" `
    -OutputFile "content.txt"
```

### Pattern 3: Complex Document Analysis

For documents with tables, forms, or mixed content:

```powershell
# Full analysis workflow
& scripts/analyze_scanned.ps1 `
    -InputFile "complex_invoice.pdf" `
    -Mode "full" `
    -OutputDir "./invoice_analysis"

# Results will include:
# - Page images (for visual reference)
# - Extracted text files
# - Detected tables (if any)
# - Layout structure information
```

### Pattern 4: Batch Processing

Process multiple scanned documents:

```powershell
# Create output directory
mkdir ./batch_output

# Process all PDFs in folder
$pdfs = Get-ChildItem "./scanned_docs/*.pdf"
foreach ($pdf in $pdfs) {
    $outputName = $pdf.BaseName
    & scripts/ocr_extract.ps1 `
        -InputFile $pdf.FullName `
        -OutputFile "./batch_output/$outputName.txt" `
        -Language "chi_sim+eng"
}
```

## Comparison: Standard PDF vs Scanned PDF

| Feature | Standard PDF | Scanned PDF |
|---------|-------------|-------------|
| Text extraction | Direct (PyPDF2/pdfplumber) | Requires OCR |
| Accuracy | 100% (exact text) | Depends on scan quality |
| Speed | Fast | Slower (image processing) |
| Tables | Structured extraction | OCR + layout analysis |
| Images | Already images | Converted from pages |
| Searchable | Yes | No (unless OCRed) |

## Troubleshooting

### "Tesseract not found" Error

**Solution**: Install Tesseract OCR
```powershell
# Windows (using Chocolatey)
choco install tesseract

# Or download from:
# https://github.com/UBKMannheim/tesseract/wiki
```

### "Poppler not found" Error

**Solution**: Install Poppler for pdf2image
```powershell
# Windows: Download from
# https://github.com/oschwartz10612/poppler-windows/releases

# Add to PATH or specify location:
$env:PATH += ";C:\\path\\to\\poppler\\bin"
```

### Poor OCR Quality

**Solutions**:
1. Increase DPI (300-600 recommended)
2. Use appropriate language pack
3. Pre-process images (contrast, denoise)
4. For handwritten text: use specialized OCR models

### Very Large PDFs

**Solution**: Process in chunks
```powershell
# Process first 10 pages
& scripts/ocr_extract.ps1 `
    -InputFile "large_scan.pdf" `
    -Pages "1-10"

# Then process next batch
& scripts/ocr_extract.ps1 `
    -InputFile "large_scan.pdf" `
    -Pages "11-20"
```

## Advanced Usage

### Custom Pre-processing

For low-quality scans, pre-process images:

```powershell
# Convert to images first
& scripts/pdf_to_images.ps1 -InputFile "poor_scan.pdf" -Dpi 400

# Then use Python with OpenCV for enhancement
python -c "
import cv2
import numpy as np
from PIL import Image

# Load image
img = cv2.imread('page_1.png', 0)

# Denoise and enhance
img = cv2.fastNlMeansDenoising(img, None, 10, 7, 21)
_, img = cv2.threshold(img, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

# Save enhanced image
cv2.imwrite('page_1_enhanced.png', img)
"
```

### Integration with Vision Models

Convert scanned PDFs for AI vision analysis:

```powershell
# Step 1: Convert to images
& scripts/pdf_to_images.ps1 `
    -InputFile "scanned_report.pdf" `
    -Dpi 300

# Step 2: Use images with vision-capable AI
# The images in ./pdf_images/ can be analyzed by AI models
```

## Limitations

- **OCR accuracy**: Depends on scan quality (300+ DPI recommended)
- **Handwritten text**: May require specialized OCR models
- **Complex layouts**: Tables and forms may need manual verification
- **Processing time**: Slower than standard PDF text extraction
- **Resource intensive**: High-resolution images require more memory

## Related Skills

- **pdf-processor**: For standard PDFs with embedded text
- **docx-processor**: For Word documents
- **scanned-pdf-processor**: For image-based/scanned PDFs (this skill)

## See Also

- [Tesseract OCR Documentation](https://github.com/tesseract-ocr/tesseract)
- [PyMuPDF Documentation](https://pymupdf.readthedocs.io/)
- [pdf2image Documentation](https://github.com/Belval/pdf2image)
