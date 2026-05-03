#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Convert images to a single PDF file

.DESCRIPTION
    Combines multiple image files (JPG, PNG, etc.) into a single PDF document.

.PARAMETER InputFiles
    Image file paths (in order)

.PARAMETER OutputFile
    Output PDF path

.PARAMETER Quality
    JPEG quality for compression (1-100, default: 85)

.EXAMPLE
    ./images_to_pdf.ps1 -InputFiles @("img1.jpg", "img2.png") -OutputFile "output.pdf"
    Get-ChildItem *.jpg | ./images_to_pdf.ps1 -OutputFile "photos.pdf"
#>
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string[]]$InputFiles,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [int]$Quality = 85
)

begin {
    $files = @()
}

process {
    $files += $InputFiles
}

end {
    if ($files.Count -eq 0) {
        Write-Error "No image files provided"
        return
    }
    
    $resolvedFiles = $files | ForEach-Object { Resolve-Path $_ -ErrorAction Stop }
    $outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
    
    # Check for Python with PIL/Pillow
    $pythonCode = @"
import sys
from PIL import Image
import os

image_files = sys.argv[1:-1]
output_file = sys.argv[-1]

images = []
for f in image_files:
    img = Image.open(f)
    if img.mode != 'RGB':
        img = img.convert('RGB')
    images.append(img)

if images:
    images[0].save(
        output_file,
        save_all=True,
        append_images=images[1:],
        resolution=100.0
    )
    print(f"PDF created: {output_file}")
"@
    
    $tempScript = [System.IO.Path]::GetTempFileName() + ".py"
    $pythonCode | Out-File -FilePath $tempScript -Encoding UTF8
    
    try {
        python $tempScript @resolvedFiles $outputPath
        if ($?) {
            Write-Host "PDF created: $outputPath"
        }
    }
    catch {
        Write-Error "Failed to create PDF. Please install Python with Pillow (pip install Pillow)"
    }
    finally {
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    }
}
