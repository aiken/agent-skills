#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Batch convert multiple documents
.DESCRIPTION
    Convert multiple files to the same output format
.PARAMETER InputFiles
    Array of input file paths
.PARAMETER OutputFormat
    Target format (pdf, html, docx, md)
.PARAMETER OutputDir
    Output directory (default: same as input)
.PARAMETER PdfEngine
    PDF engine for PDF output (auto, xelatex, pdflatex)
.EXAMPLE
    $files = Get-ChildItem "*.md" | Select-Object -ExpandProperty FullName
    .\batch_convert.ps1 -InputFiles $files -OutputFormat pdf -OutputDir "output/"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string[]]$InputFiles,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("pdf", "html", "docx", "md", "markdown")]
    [string]$OutputFormat,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDir = $null,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("auto", "xelatex", "pdflatex", "lualatex")]
    [string]$PdfEngine = "auto"
)

# Get the convert script path
$convertScript = Join-Path $PSScriptRoot "convert.ps1"

if (-not (Test-Path $convertScript)) {
    Write-Error "Convert script not found: $convertScript"
    exit 1
}

# Create output directory if specified
if ($OutputDir -and -not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Extension mapping
$extMap = @{
    "pdf" = ".pdf"
    "html" = ".html"
    "docx" = ".docx"
    "md" = ".md"
    "markdown" = ".md"
}

$outputExt = $extMap[$OutputFormat]

# Statistics
$success = 0
$failed = 0
$skipped = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Batch Conversion" -ForegroundColor Cyan
Write-Host "  Format: $OutputFormat" -ForegroundColor Cyan
Write-Host "  Files: $($InputFiles.Count)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($inputFile in $InputFiles) {
    if (-not (Test-Path $inputFile)) {
        Write-Host "⚠️  Skipping (not found): $inputFile" -ForegroundColor Yellow
        $skipped++
        continue
    }
    
    # Determine output path
    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFile)
    
    if ($OutputDir) {
        $outputFile = Join-Path $OutputDir ($baseName + $outputExt)
    } else {
        $inputDir = Split-Path -Parent $inputFile
        $outputFile = Join-Path $inputDir ($baseName + $outputExt)
    }
    
    # Skip if output exists and is newer than input
    if (Test-Path $outputFile) {
        $inputTime = (Get-Item $inputFile).LastWriteTime
        $outputTime = (Get-Item $outputFile).LastWriteTime
        
        if ($outputTime -gt $inputTime) {
            Write-Host "⏭️  Skipping (up to date): $([System.IO.Path]::GetFileName($inputFile))" -ForegroundColor Gray
            $skipped++
            continue
        }
    }
    
    Write-Host "Converting: $([System.IO.Path]::GetFileName($inputFile)) → $([System.IO.Path]::GetFileName($outputFile))" -ForegroundColor Cyan
    
    try {
        & $convertScript -InputFile $inputFile -OutputFile $outputFile -PdfEngine $PdfEngine
        
        if (Test-Path $outputFile) {
            $success++
        } else {
            $failed++
        }
    } catch {
        Write-Host "❌ Failed: $_" -ForegroundColor Red
        $failed++
    }
    
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Conversion Complete" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ Success: $success" -ForegroundColor Green
if ($failed -gt 0) {
    Write-Host "✗ Failed: $failed" -ForegroundColor Red
}
if ($skipped -gt 0) {
    Write-Host "⏭️  Skipped: $skipped" -ForegroundColor Yellow
}
