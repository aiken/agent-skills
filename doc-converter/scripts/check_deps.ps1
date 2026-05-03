#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Check document conversion dependencies
.DESCRIPTION
    Detects available converters (Pandoc, LaTeX engines) and reports their status
.EXAMPLE
    .\check_deps.ps1
#>

[CmdletBinding()]
param()

$results = @{
    Pandoc = $null
    XeLaTeX = $null
    Pdflatex = $null
    LuaLaTeX = $null
    LibreOffice = $null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Document Converter Dependencies" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check Pandoc
try {
    $pandocVersion = (pandoc --version) | Select-Object -First 1
    if ($pandocVersion -match "pandoc.exe\s+(.+)") {
        $results.Pandoc = $matches[1]
        Write-Host "✓ Pandoc: " -NoNewline -ForegroundColor Green
        Write-Host $results.Pandoc
    }
} catch {
    Write-Host "✗ Pandoc: Not found" -ForegroundColor Red
    Write-Host "  Install from: https://pandoc.org/installing.html" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "PDF Engines:" -ForegroundColor Cyan

# Check XeLaTeX
try {
    $xelatexVersion = (xelatex --version) | Select-Object -First 1
    if ($xelatexVersion) {
        $results.XeLaTeX = "available"
        Write-Host "✓ XeLaTeX: " -NoNewline -ForegroundColor Green
        Write-Host "available (recommended for Chinese)" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ XeLaTeX: Not found" -ForegroundColor Red
}

# Check pdflatex
try {
    $pdflatexVersion = (pdflatex --version) | Select-Object -First 1
    if ($pdflatexVersion) {
        $results.Pdflatex = "available"
        Write-Host "✓ pdflatex: " -NoNewline -ForegroundColor Green
        Write-Host "available (limited Unicode support)"
    }
} catch {
    Write-Host "✗ pdflatex: Not found" -ForegroundColor Gray
}

# Check LuaLaTeX
try {
    $lualatexVersion = (lualatex --version) | Select-Object -First 1
    if ($lualatexVersion) {
        $results.LuaLaTeX = "available"
        Write-Host "✓ LuaLaTeX: " -NoNewline -ForegroundColor Green
        Write-Host "available"
    }
} catch {
    Write-Host "✗ LuaLaTeX: Not found" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Office Suites:" -ForegroundColor Cyan

# Check LibreOffice
try {
    $soffice = Get-Command soffice -ErrorAction Stop
    Write-Host "✓ LibreOffice: " -NoNewline -ForegroundColor Green
    Write-Host "available (for DOCX->PDF conversion)"
    $results.LibreOffice = "available"
} catch {
    Write-Host "✗ LibreOffice: Not found" -ForegroundColor Gray
    Write-Host "  (Optional - needed for DOCX->PDF without LaTeX)" -ForegroundColor DarkGray
}

# Check Microsoft Word (for DOCX->PDF conversion)
try {
    $word = New-Object -ComObject Word.Application -ErrorAction Stop
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    Write-Host "✓ Microsoft Word COM: " -NoNewline -ForegroundColor Green
    Write-Host "available (best for DOCX->PDF)"
    $results.WordCOM = "available"
} catch {
    Write-Host "✗ Microsoft Word COM: Not available" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan

# Recommendations
Write-Host ""
Write-Host "Recommendations:" -ForegroundColor Cyan

if (-not $results.Pandoc) {
    Write-Host "❌ Pandoc is REQUIRED. Please install it first." -ForegroundColor Red
} elseif (-not $results.XeLaTeX -and -not $results.Pdflatex) {
    Write-Host "⚠️  No LaTeX found. PDF generation will use fallback methods." -ForegroundColor Yellow
    Write-Host "   For best results, install TinyTeX:" -ForegroundColor Yellow
    Write-Host "   Invoke-WebRequest -Uri 'https://yihui.org/tinytex/install-bin-windows.bat' -OutFile 'install-tinytex.bat'; .\install-tinytex.bat" -ForegroundColor White
} elseif (-not $results.XeLaTeX -and $results.Pdflatex) {
    Write-Host "⚠️  pdflatex found but XeLaTeX is recommended for Chinese documents." -ForegroundColor Yellow
} else {
    Write-Host "✅ All recommended tools are available!" -ForegroundColor Green
}

Write-Host ""

# Return results for programmatic use
return $results
