#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Split a PDF file into multiple files

.DESCRIPTION
    Splits a PDF into individual pages or page ranges.

.PARAMETER InputFile
    Path to the PDF file to split

.PARAMETER OutputPattern
    Output filename pattern (default: "page_{0}.pdf")

.PARAMETER PageRange
    Specific pages to extract (e.g., "1-5,7,10-12")

.PARAMETER OutputDir
    Directory for output files

.EXAMPLE
    ./split_pdf.ps1 -InputFile "document.pdf"
    ./split_pdf.ps1 -InputFile "document.pdf" -PageRange "1-5" -OutputPattern "chapter1_{0}.pdf"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPattern = "page_{0}.pdf",
    
    [Parameter(Mandatory=$false)]
    [string]$PageRange,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir
)

$InputFile = Resolve-Path $InputFile -ErrorAction Stop

# Setup output directory
if (-not $OutputDir) {
    $OutputDir = Split-Path -Parent $InputFile
}
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

function Split-WithPython {
    param($inFile, $outPattern, $pageRange, $outDir)
    
    $pyScript = @"
import sys
from PyPDF2 import PdfReader, PdfWriter
import os

pdf_path = sys.argv[1]
out_pattern = sys.argv[2]
page_range = sys.argv[3] if len(sys.argv) > 3 else None
out_dir = sys.argv[4] if len(sys.argv) > 4 else os.path.dirname(pdf_path)

reader = PdfReader(pdf_path)
total_pages = len(reader.pages)

if page_range:
    # Parse page range
    pages = []
    for part in page_range.split(','):
        if '-' in part:
            start, end = map(int, part.split('-'))
            pages.extend(range(start-1, min(end, total_pages)))
        else:
            pages.append(int(part)-1)
else:
    pages = range(total_pages)

for i, page_num in enumerate(pages):
    writer = PdfWriter()
    writer.add_page(reader.pages[page_num])
    out_path = os.path.join(out_dir, out_pattern.format(page_num + 1))
    with open(out_path, 'wb') as f:
        writer.write(f)

print(f"Created {len(pages)} PDF files in {out_dir}")
"@
    
    $tempScript = [System.IO.Path]::GetTempFileName() + ".py"
    $pyScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    try {
        python $tempScript $inFile $outPattern $pageRange $outDir
        return $?
    }
    finally {
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    }
}

$success = Split-WithPython -inFile $InputFile -outPattern $OutputPattern -pageRange $PageRange -outDir $OutputDir

if ($success) {
    Write-Host "PDF split complete. Files saved to: $OutputDir"
} else {
    Write-Error "Failed to split PDF. Please install Python with PyPDF2."
}
