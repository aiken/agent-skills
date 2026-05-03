<#
.SYNOPSIS
    Extract text from scanned PDFs using OCR

.DESCRIPTION
    Uses Tesseract OCR to extract text from scanned/image-based PDF documents.

.PARAMETER InputFile
    Path to the scanned PDF file

.PARAMETER OutputFile
    Optional output file for extracted text

.PARAMETER Language
    OCR language(s) - default: chi_sim+eng

.PARAMETER Pages
    Specific pages to process (e.g., "1-5,7,10")

.PARAMETER PreserveLayout
    Preserve original layout in output

.EXAMPLE
    ./ocr_extract.ps1 -InputFile "scanned.pdf"
    ./ocr_extract.ps1 -InputFile "scanned.pdf" -Language "chi_sim" -OutputFile "text.txt"
#>
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$Language = "chi_sim+eng",
    
    [Parameter(Mandatory=$false)]
    [string]$Pages,
    
    [Parameter(Mandatory=$false)]
    [bool]$PreserveLayout = $true
)

begin {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        $python = Get-Command py -ErrorAction SilentlyContinue
    }
    if (-not $python) {
        Write-Error "Python is required but not found (checked 'python' and 'py')."
        exit 1
    }
    $script:pythonCmd = $python.Source
}

process {
    $InputFile = Resolve-Path $InputFile -ErrorAction Stop
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
    
    Write-Host "Performing OCR on scanned PDF..." -ForegroundColor Cyan
    Write-Host "Input: $InputFile" -ForegroundColor Gray
    Write-Host "Language: $Language" -ForegroundColor Gray
    
    $pyScript = @"
import fitz
import pytesseract
from PIL import Image
import io
import os
import sys

pdf_path = r'$InputFile'
language = '$Language'
pages_spec = r'$Pages'
preserve_layout = '$PreserveLayout' == 'True'

# Configure pytesseract path for Windows
tesseract_paths = [
    r'C:\\Program Files\\Tesseract-OCR\\tesseract.exe',
    r'C:\\Program Files (x86)\\Tesseract-OCR\\tesseract.exe',
]
for tp in tesseract_paths:
    if os.path.exists(tp):
        pytesseract.pytesseract.tesseract_cmd = tp
        break

doc = fitz.open(pdf_path)
print(f"Processing PDF with {len(doc)} pages...")

# Determine pages
if pages_spec:
    page_nums = []
    for part in pages_spec.split(','):
        if '-' in part:
            start, end = map(int, part.split('-'))
            page_nums.extend(range(start-1, min(end, len(doc))))
        else:
            page_nums.append(int(part)-1)
    page_nums = [p for p in page_nums if 0 <= p < len(doc)]
else:
    page_nums = range(len(doc))

all_text = []

for page_num in page_nums:
    print(f"Processing page {page_num+1}...")
    page = doc[page_num]
    
    # Render at 300 DPI for OCR
    zoom = 300 / 72
    mat = fitz.Matrix(zoom, zoom)
    pix = page.get_pixmap(matrix=mat)
    
    # Convert to PIL Image
    img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
    
    # Perform OCR
    config = '--psm 6' if not preserve_layout else '--psm 3'
    text = pytesseract.image_to_string(img, lang=language, config=config)
    
    all_text.append(f"=== Page {page_num+1} ===")
    all_text.append(text)
    all_text.append("")

doc.close()

# Output result
result = "\\n".join(all_text)
print("\\n" + "="*50)
print("EXTRACTED TEXT:")
print("="*50)
print(result[:2000])  # Print first 2000 chars
if len(result) > 2000:
    print(f"\\n... ({len(result) - 2000} more characters)")

# Save to file if specified
output_file = r'$OutputFile'
if output_file:
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(result)
    print(f"\\nSaved to: {output_file}")
"@

    $tempScript = [System.IO.Path]::GetTempFileName() + ".py"
    $pyScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    try {
        & $script:pythonCmd $tempScript
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nOCR extraction complete!" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "OCR failed. Make sure Tesseract is installed."
        Write-Host "Download from: https://github.com/UBKMannheim/tesseract/wiki" -ForegroundColor Yellow
    }
    finally {
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    }
}
