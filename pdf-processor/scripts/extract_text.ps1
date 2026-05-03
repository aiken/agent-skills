#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Extract text content from PDF files

.DESCRIPTION
    Extracts text from PDF files using available tools.
    Tries multiple methods: pdftotext (xpdf), Python PyPDF2, or .NET iTextSharp

.PARAMETER InputFile
    Path to the PDF file

.PARAMETER OutputFile
    Optional path to save extracted text

.PARAMETER Pages
    Specific pages to extract (e.g., "1-5,7,10")

.EXAMPLE
    ./extract_text.ps1 -InputFile "document.pdf"
    ./extract_text.ps1 -InputFile "document.pdf" -OutputFile "content.txt" -Pages "1-10"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$Pages
)

$InputFile = Resolve-Path $InputFile -ErrorAction Stop

function Extract-WithPdfToText {
    param($pdfPath, $outPath, $pageRange)
    
    $pdftotext = Get-Command pdftotext -ErrorAction SilentlyContinue
    if (-not $pdftotext) {
        # Check common locations
        $commonPaths = @(
            "C:\Program Files\xpdf\pdftotext.exe",
            "C:\Program Files (x86)\xpdf\pdftotext.exe",
            "$env:LOCALAPPDATA\xpdf\pdftotext.exe"
        )
        foreach ($p in $commonPaths) {
            if (Test-Path $p) {
                $pdftotext = $p
                break
            }
        }
    }
    
    if ($pdftotext) {
        $args = @("-layout")
        if ($pageRange) { $args += @("-f", $pageRange.Split("-")[0], "-l", $pageRange.Split("-")[1].Split(",")[0]) }
        $args += @("`"$pdfPath`"", "`"$outPath`"")
        & $pdftotext @args
        return $true
    }
    return $false
}

function Extract-WithPython {
    param($pdfPath, $outPath, $pageRange)
    
    $pyScript = @"
import sys
try:
    import PyPDF2
    import pdfplumber
    use_plumber = True
except:
    use_plumber = False

pdf_path = sys.argv[1]
out_path = sys.argv[2]
pages = sys.argv[3] if len(sys.argv) > 3 else None

text = ""
if use_plumber:
    with pdfplumber.open(pdf_path) as pdf:
        if pages:
            page_nums = []
            for part in pages.split(','):
                if '-' in part:
                    start, end = map(int, part.split('-'))
                    page_nums.extend(range(start-1, end))
                else:
                    page_nums.append(int(part)-1)
            for i in page_nums:
                if i < len(pdf.pages):
                    text += pdf.pages[i].extract_text() + "\n\n"
        else:
            for page in pdf.pages:
                text += page.extract_text() + "\n\n"
else:
    with open(pdf_path, 'rb') as f:
        reader = PyPDF2.PdfReader(f)
        if pages:
            page_nums = []
            for part in pages.split(','):
                if '-' in part:
                    start, end = map(int, part.split('-'))
                    page_nums.extend(range(start-1, end))
                else:
                    page_nums.append(int(part)-1)
            for i in page_nums:
                if i < len(reader.pages):
                    text += reader.pages[i].extract_text() + "\n\n"
        else:
            for page in reader.pages:
                text += page.extract_text() + "\n\n"

with open(out_path, 'w', encoding='utf-8') as f:
    f.write(text)
print("Extraction complete")
"@
    
    $tempScript = [System.IO.Path]::GetTempFileName() + ".py"
    $pyScript | Out-File -FilePath $tempScript -Encoding UTF8
    
    try {
        python $tempScript "$pdfPath" "$outPath" "$pageRange"
        return $?
    }
    finally {
        Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
    }
}

function Extract-WithDotNet {
    param($pdfPath, $outPath)
    
    # Use iTextSharp via PowerShell script
    $code = @"
using System;
using System.IO;
using iText.Kernel.Pdf;
using iText.Kernel.Pdf.Canvas.Parser;
using iText.Kernel.Pdf.Canvas.Parser.Listener;

public class PdfTextExtractor {
    public static string Extract(string pdfPath) {
        using (PdfReader reader = new PdfReader(pdfPath)) {
            using (PdfDocument pdf = new PdfDocument(reader)) {
                string text = "";
                for (int i = 1; i <= pdf.GetNumberOfPages(); i++) {
                    var page = pdf.GetPage(i);
                    text += PdfTextExtractor.GetTextFromPage(page) + "\n\n";
                }
                return text;
            }
        }
    }
}
"@
    
    # Check if iText is available
    try {
        Add-Type -TypeDefinition $code -ReferencedAssemblies @("itext.kernel.dll", "itext.io.dll") -ErrorAction Stop
        $text = [PdfTextExtractor]::Extract($pdfPath)
        $text | Out-File -FilePath $outPath -Encoding UTF8
        return $true
    }
    catch {
        return $false
    }
}

# Main execution
$tempOutput = [System.IO.Path]::GetTempFileName()

try {
    $success = $false
    
    # Try pdftotext first
    if (-not $success) {
        $success = Extract-WithPdfToText -pdfPath $InputFile -outPath $tempOutput -pageRange $Pages
    }
    
    # Try Python next
    if (-not $success) {
        $success = Extract-WithPython -pdfPath $InputFile -outPath $tempOutput -pageRange $Pages
    }
    
    # Try .NET last
    if (-not $success) {
        $success = Extract-WithDotNet -pdfPath $InputFile -outPath $tempOutput
    }
    
    if ($success) {
        $content = Get-Content $tempOutput -Encoding UTF8 -Raw
        if ($OutputFile) {
            $content | Out-File -FilePath $OutputFile -Encoding UTF8
            Write-Host "Text extracted to: $OutputFile"
        } else {
            Write-Output $content
        }
    } else {
        Write-Error "Failed to extract text. Please install xpdf (pdftotext) or Python with PyPDF2/pdfplumber."
    }
}
finally {
    if (Test-Path $tempOutput) {
        Remove-Item $tempOutput -Force
    }
}
