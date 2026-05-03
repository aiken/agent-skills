#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Convert documents between various formats
.DESCRIPTION
    Converts documents using Pandoc with automatic LaTeX detection and Chinese support
.PARAMETER InputFile
    Source file path
.PARAMETER OutputFile
    Target file path
.PARAMETER PdfEngine
    PDF engine to use (xelatex, pdflatex, auto)
.EXAMPLE
    .\convert.ps1 -InputFile "doc.md" -OutputFile "doc.pdf"
    .\convert.ps1 -InputFile "doc.md" -OutputFile "doc.pdf" -PdfEngine xelatex
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$PdfEngine = "auto"
)

# Resolve full paths
$InputFile = Resolve-Path $InputFile | Select-Object -ExpandProperty Path
$OutputFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
$OutputDir = Split-Path -Parent $OutputFile

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# Check input file exists
if (-not (Test-Path $InputFile)) {
    Write-Error "Input file not found: $InputFile"
    exit 1
}

# Detect input and output formats
$inputExt = [System.IO.Path]::GetExtension($InputFile).ToLower()
$outputExt = [System.IO.Path]::GetExtension($OutputFile).ToLower()

$formatMap = @{
    ".md" = "markdown"
    ".markdown" = "markdown"
    ".docx" = "docx"
    ".pdf" = "pdf"
    ".html" = "html"
    ".htm" = "html"
    ".txt" = "plain"
    ".rst" = "rst"
}

$inputFormat = $formatMap[$inputExt]
$outputFormat = $formatMap[$outputExt]

if (-not $inputFormat) {
    Write-Error "Unsupported input format: $inputExt"
    exit 1
}

if (-not $outputFormat) {
    Write-Error "Unsupported output format: $outputExt"
    exit 1
}

Write-Host "Converting: $InputFile ($inputFormat) → $OutputFile ($outputFormat)" -ForegroundColor Cyan

# Function to check LaTeX availability
function Test-LaTeX {
    param([string]$Engine)
    try {
        $null = & $Engine --version 2>&1
        return $true
    } catch {
        return $false
    }
}

# Function to detect best PDF engine
function Get-BestPdfEngine {
    # Priority: xelatex > lualatex > pdflatex
    if (Test-LaTeX "xelatex") { return "xelatex" }
    if (Test-LaTeX "lualatex") { return "lualatex" }
    if (Test-LaTeX "pdflatex") { return "pdflatex" }
    return $null
}

# Handle DOCX to PDF conversion
if ($inputFormat -eq "docx" -and $outputFormat -eq "pdf") {
    Write-Host "DOCX to PDF conversion..." -ForegroundColor Yellow
    
    # Method 1: Try Microsoft Word COM (best quality for Windows)
    try {
        Write-Host "Trying Microsoft Word..." -ForegroundColor Green
        $word = New-Object -ComObject Word.Application -ErrorAction Stop
        $word.Visible = $false
        
        $doc = $word.Documents.Open($InputFile)
        $doc.SaveAs($OutputFile, 17)  # 17 = PDF format
        $doc.Close()
        $word.Quit()
        
        # Release COM objects
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($doc) | Out-Null
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
        [GC]::Collect()
        
        if (Test-Path $OutputFile) {
            Write-Host "✓ Conversion successful using Microsoft Word: $OutputFile" -ForegroundColor Green
            exit 0
        }
    } catch {
        Write-Host "Microsoft Word not available or failed: $_" -ForegroundColor Yellow
    }
    
    # Method 2: Try LibreOffice
    try {
        $soffice = Get-Command soffice -ErrorAction Stop
        Write-Host "Using LibreOffice..." -ForegroundColor Green
        $tempDir = [System.IO.Path]::GetTempPath()
        & soffice --headless --convert-to pdf --outdir $OutputDir $InputFile
        
        # LibreOffice saves with same name but .pdf extension
        $expectedOutput = [System.IO.Path]::ChangeExtension($InputFile, ".pdf")
        if (Test-Path $expectedOutput -and $expectedOutput -ne $OutputFile) {
            Move-Item $expectedOutput $OutputFile -Force
        }
        
        if (Test-Path $OutputFile) {
            Write-Host "✓ Conversion successful: $OutputFile" -ForegroundColor Green
            exit 0
        }
    } catch {
        Write-Host "LibreOffice not available, trying alternative method..." -ForegroundColor Yellow
    }
    
    # Method 3: Fallback - DOCX -> Markdown -> PDF
    Write-Host "Converting via Markdown intermediate..." -ForegroundColor Yellow
    $tempMd = [System.IO.Path]::GetTempFileName() + ".md"
    
    try {
        pandoc $InputFile -o $tempMd --wrap=none
        $InputFile = $tempMd
        $inputFormat = "markdown"
    } catch {
        Write-Error "Failed to convert DOCX to intermediate format"
        exit 1
    }
}

# Handle Markdown/text to PDF
if ($outputFormat -eq "pdf" -and $inputFormat -in @("markdown", "plain", "rst", "html")) {
    
    # Determine PDF engine
    if ($PdfEngine -eq "auto") {
        $PdfEngine = Get-BestPdfEngine
    }
    
    if (-not $PdfEngine) {
        Write-Host "⚠️  No LaTeX installation found!" -ForegroundColor Yellow
        Write-Host "Falling back to HTML output (open in browser to print as PDF)..." -ForegroundColor Yellow
        
        # Fallback to HTML
        $htmlOutput = [System.IO.Path]::ChangeExtension($OutputFile, ".html")
        pandoc $InputFile -o $htmlOutput --standalone
        
        if (Test-Path $htmlOutput) {
            Write-Host "✓ HTML generated (print to PDF in browser): $htmlOutput" -ForegroundColor Green
            Write-Host ""
            Write-Host "To install LaTeX for direct PDF conversion:" -ForegroundColor Cyan
            Write-Host "  Windows: Invoke-WebRequest -Uri 'https://yihui.org/tinytex/install-bin-windows.bat' -OutFile 'install-tinytex.bat'; .\install-tinytex.bat" -ForegroundColor White
            exit 0
        }
    }
    
    Write-Host "Using PDF engine: $PdfEngine" -ForegroundColor Green
    
    # Build pandoc arguments
    $pandocArgs = @(
        $InputFile,
        "-o", $OutputFile,
        "--pdf-engine=$PdfEngine"
    )
    
    # Add XeLaTeX specific options for Chinese support
    if ($PdfEngine -eq "xelatex") {
        $pandocArgs += "-V"
        $pandocArgs += "mainfont=Times New Roman"
        $pandocArgs += "-V"
        $pandocArgs += "CJKmainfont=SimSun"
        $pandocArgs += "-V"
        $pandocArgs += "geometry:margin=1in"
    }
    
    # Execute conversion
    try {
        & pandoc @pandocArgs 2>&1
        
        if (Test-Path $OutputFile) {
            Write-Host "✓ Conversion successful: $OutputFile" -ForegroundColor Green
        } else {
            Write-Error "Conversion failed - output file not created"
            exit 1
        }
    } catch {
        Write-Error "Pandoc conversion failed: $_"
        exit 1
    }
}
# Handle other conversions
else {
    try {
        pandoc $InputFile -o $OutputFile
        
        if (Test-Path $OutputFile) {
            Write-Host "✓ Conversion successful: $OutputFile" -ForegroundColor Green
        } else {
            Write-Error "Conversion failed - output file not created"
            exit 1
        }
    } catch {
        Write-Error "Pandoc conversion failed: $_"
        exit 1
    }
}

# Cleanup temp files
if ($tempMd -and (Test-Path $tempMd)) {
    Remove-Item $tempMd -Force
}
