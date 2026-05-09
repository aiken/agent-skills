#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generate PDF from HTML using Edge headless mode with cache-safe defaults.

.DESCRIPTION
    This script wraps the Edge headless --print-to-pdf command with all
    recommended anti-cache and security flags, so agents don't need to
    remember the correct incantation.

    Built-in protections:
    - --user-data-dir + --incognito  -> isolate from running Edge sessions
    - --no-first-run                 -> skip first-run UX
    - --disk-cache-size=1            -> effectively disable disk cache
    - --no-pdf-header-footer         -> prevent local file path leakage in PDF

.PARAMETER InputHtml
    Path to the input HTML file.

.PARAMETER OutputPdf
    Path for the generated PDF file.

.PARAMETER WindowSize
    Browser viewport size, e.g. "1920x1080". Default: "1920x1080".

.PARAMETER TimeoutMs
    Maximum wait time in milliseconds before capturing. Default: 30000.

.EXAMPLE
    .\edge_to_pdf.ps1 -InputHtml "report.html" -OutputPdf "report.pdf"

.EXAMPLE
    .\edge_to_pdf.ps1 -InputHtml "C:\tmp\report.html" -OutputPdf "C:\out\report.pdf" -WindowSize "1440x900"
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$InputHtml,

    [Parameter(Mandatory = $true)]
    [string]$OutputPdf,

    [string]$WindowSize = "1920x1080",

    [int]$TimeoutMs = 30000
)

# Resolve paths to absolute
$HtmlPath = Resolve-Path $InputHtml -ErrorAction Stop | Select-Object -ExpandProperty Path
$PdfPath  = if ([System.IO.Path]::IsPathRooted($OutputPdf)) { $OutputPdf } else { Join-Path (Get-Location).Path $OutputPdf }

# Auto-detect Edge executable
$EdgeCandidates = @(
    "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
    "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe",
    "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe"
)
$Edge = $EdgeCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $Edge) {
    Write-Error "Microsoft Edge not found. Please install Edge or set `$Edge manually."
    exit 1
}

# Create a temporary profile directory (deleted automatically)
$TempProfile = Join-Path $env:TEMP ("edge-pdf-profile-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
New-Item -ItemType Directory -Force -Path $TempProfile | Out-Null

try {
    $width, $height = $WindowSize -split "x"

    $Arguments = @(
        "--headless",
        "--disable-gpu",
        "--no-pdf-header-footer",
        "--window-size=${width},${height}",
        "--timeout=$TimeoutMs",
        "--user-data-dir=`"$TempProfile`"",
        "--incognito",
        "--no-first-run",
        "--disk-cache-size=1",
        "--print-to-pdf=`"$PdfPath`"",
        "file:///$HtmlPath"
    )

    Write-Host "Generating PDF..."
    Write-Host "  Edge:    $Edge"
    Write-Host "  HTML:    $HtmlPath"
    Write-Host "  PDF:     $PdfPath"
    Write-Host "  Profile: $TempProfile"

    $proc = Start-Process -FilePath $Edge -ArgumentList $Arguments -Wait -PassThru -WindowStyle Hidden

    if ($proc.ExitCode -ne 0) {
        Write-Error "Edge exited with code $($proc.ExitCode)"
        exit 1
    }

    if (-not (Test-Path $PdfPath)) {
        Write-Error "PDF was not created at $PdfPath"
        exit 1
    }

    $size = (Get-Item $PdfPath).Length
    Write-Host "Success: $PdfPath ($size bytes)"
} finally {
    # Always clean up temp profile
    if (Test-Path $TempProfile) {
        Remove-Item -Recurse -Force $TempProfile -ErrorAction SilentlyContinue
    }
}
