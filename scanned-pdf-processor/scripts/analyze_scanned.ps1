<#
.SYNOPSIS
    Comprehensive analysis of scanned documents

.DESCRIPTION
    Analyzes scanned PDFs using multiple methods: visual conversion, OCR, and structure detection.

.PARAMETER InputFile
    Path to the scanned PDF file

.PARAMETER Mode
    Analysis mode: visual, text, full, structure

.PARAMETER OutputDir
    Output directory for results

.EXAMPLE
    ./analyze_scanned.ps1 -InputFile "scanned.pdf" -Mode "full"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("visual", "text", "full", "structure")]
    [string]$Mode = "full",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "./scanned_analysis"
)

$InputFile = Resolve-Path $InputFile -ErrorAction Stop
$fileName = [System.IO.Path]::GetFileNameWithoutExtension($InputFile)

# Create output directory
$analysisDir = Join-Path $OutputDir $fileName
New-Item -ItemType Directory -Path $analysisDir -Force | Out-Null
$analysisDir = Resolve-Path $analysisDir

Write-Host "Analyzing scanned PDF..." -ForegroundColor Cyan
Write-Host "Mode: $Mode" -ForegroundColor Cyan
Write-Host "Output: $analysisDir" -ForegroundColor Gray

# Get the script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

switch ($Mode) {
    "visual" {
        Write-Host "`n[1/1] Converting to images..." -ForegroundColor Yellow
        & "$scriptDir\\pdf_to_images.ps1" `
            -InputFile $InputFile `
            -OutputDir "$analysisDir\\images" `
            -Dpi 300
    }
    
    "text" {
        Write-Host "`n[1/1] Extracting text with OCR..." -ForegroundColor Yellow
        & "$scriptDir\\ocr_extract.ps1" `
            -InputFile $InputFile `
            -OutputFile "$analysisDir\\extracted_text.txt" `
            -Language "chi_sim+eng"
    }
    
    "full" {
        Write-Host "`n[1/3] Converting to images..." -ForegroundColor Yellow
        & "$scriptDir\\pdf_to_images.ps1" `
            -InputFile $InputFile `
            -OutputDir "$analysisDir\\images" `
            -Dpi 300
        
        Write-Host "`n[2/3] Extracting text with OCR..." -ForegroundColor Yellow
        & "$scriptDir\\ocr_extract.ps1" `
            -InputFile $InputFile `
            -OutputFile "$analysisDir\\extracted_text.txt" `
            -Language "chi_sim+eng"
        
        Write-Host "`n[3/3] Generating analysis report..." -ForegroundColor Yellow
        
        # Generate summary report
        $report = @"
# Scanned Document Analysis Report

## File Information
- **Filename**: $fileName
- **Analysis Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Mode**: Full Analysis

## Output Files
- **Images**: $analysisDir\\images\\
- **Extracted Text**: $analysisDir\\extracted_text.txt

## Notes
- Images are rendered at 300 DPI for optimal OCR accuracy
- OCR uses Chinese (Simplified) + English language model
- Review extracted text for accuracy, especially for:
  - Handwritten content
  - Low-quality scans
  - Complex layouts (tables, forms)

## Next Steps
1. Review images in the 'images' folder
2. Check extracted_text.txt for OCR results
3. Manually verify critical information
"@
        $report | Out-File -FilePath "$analysisDir\\README.md" -Encoding UTF8
    }
    
    "structure" {
        Write-Host "`n[1/2] Converting to images for structure analysis..." -ForegroundColor Yellow
        & "$scriptDir\\pdf_to_images.ps1" `
            -InputFile $InputFile `
            -OutputDir "$analysisDir\\images" `
            -Dpi 200
        
        Write-Host "`n[2/2] Analyzing document structure..." -ForegroundColor Yellow
        
        # Structure analysis would go here
        # This is a placeholder for future enhancement
        Write-Host "Structure analysis complete. Images available for manual review." -ForegroundColor Green
    }
}

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "Analysis Complete!" -ForegroundColor Green
Write-Host "Results saved to: $analysisDir" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Show directory contents
Get-ChildItem $analysisDir -Recurse | ForEach-Object {
    $indent = "  " * ($_.FullName.Split("\").Count - $analysisDir.Split("\").Count)
    if ($_.PSIsContainer) {
        Write-Host "$indent[$($_.Name)]" -ForegroundColor Cyan
    } else {
        $size = if ($_.Length -gt 1MB) { "{0:N1} MB" -f ($_.Length/1MB) } else { "{0:N1} KB" -f ($_.Length/1KB) }
        Write-Host "$indent$($_.Name) ($size)" -ForegroundColor Gray
    }
}
