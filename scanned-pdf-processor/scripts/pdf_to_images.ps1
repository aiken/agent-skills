<#
.SYNOPSIS
    Convert scanned PDF pages to images

.DESCRIPTION
    Converts PDF pages to high-quality images for visual analysis and OCR processing.

.PARAMETER InputFile
    Path to the scanned PDF file

.PARAMETER OutputDir
    Output directory for images (default: ./pdf_images)

.PARAMETER Dpi
    Resolution in DPI (default: 300)

.PARAMETER Format
    Image format: png, jpg, tiff (default: png)

.PARAMETER Pages
    Specific pages to convert (e.g., "1-5,7,10")

.EXAMPLE
    ./pdf_to_images.ps1 -InputFile "scanned.pdf"
    ./pdf_to_images.ps1 -InputFile "scanned.pdf" -Dpi 600 -Pages "1-10"
#>
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "./pdf_images",
    
    [Parameter(Mandatory=$false)]
    [int]$Dpi = 300,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("png", "jpg", "tiff")]
    [string]$Format = "png",
    
    [Parameter(Mandatory=$false)]
    [string]$Pages
)

begin {
    # Check if Python is available (try 'python' first, then 'py' on Windows)
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) {
        $python = Get-Command py -ErrorAction SilentlyContinue
    }
    if (-not $python) {
        Write-Error "Python is required but not found (checked 'python' and 'py'). Please install Python."
        exit 1
    }
    $script:pythonCmd = $python.Source
    
    # Create output directory
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    $OutputDir = Resolve-Path $OutputDir
}

process {
    $InputFile = Resolve-Path $InputFile -ErrorAction Stop
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)
    
    Write-Host "Converting PDF to images..." -ForegroundColor Cyan
    Write-Host "Input: $InputFile" -ForegroundColor Gray
    Write-Host "Output: $OutputDir" -ForegroundColor Gray
    Write-Host "DPI: $Dpi, Format: $Format" -ForegroundColor Gray
    
    $pyScript = @"
import fitz  # PyMuPDF
import os
import sys

pdf_path = r'$InputFile'
output_dir = r'$OutputDir'
dpi = $Dpi
img_format = '$Format'
pages_spec = r'$Pages'

# Open PDF
doc = fitz.open(pdf_path)
print(f"PDF has {len(doc)} pages")

# Determine pages to process
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

print(f"Processing {len(page_nums)} pages...")

# Convert each page
for i, page_num in enumerate(page_nums, 1):
    page = doc[page_num]
    
    # Calculate zoom based on DPI
    zoom = dpi / 72  # PDF default is 72 DPI
    mat = fitz.Matrix(zoom, zoom)
    
    # Render page to pixmap
    pix = page.get_pixmap(matrix=mat)
    
    # Save image
    base_name = os.path.splitext(os.path.basename(pdf_path))[0]
    output_file = os.path.join(output_dir, f"{base_name}_page_{page_num+1:04d}.{img_format}")
    
    if img_format == "png":
        pix.save(output_file)
    elif img_format == "jpg":
        # Convert to PIL Image for JPEG
        from PIL import Image
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        img.save(output_file, "JPEG", quality=95)
    elif img_format == "tiff":
        from PIL import Image
        img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
        img.save(output_file, "TIFF")
    
    print(f"  Page {page_num+1} -> {os.path.basename(output_file)} ({pix.width}x{pix.height})")

doc.close()
print(f"\\nConversion complete. Images saved to: {output_dir}")
"@

    $tempScript = [System.IO.Path]::GetTempFileName() + ".py"
    $pyScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    try {
        & $script:pythonCmd $tempScript
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "`nConversion successful!" -ForegroundColor Green
            $images = Get-ChildItem "$OutputDir\${fileName}_page_*.$Format"
            Write-Host "Generated $($images.Count) images" -ForegroundColor Green
        }
    }
    finally {
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    }
}
