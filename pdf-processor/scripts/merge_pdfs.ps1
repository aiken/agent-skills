#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Merge multiple PDF files into one

.DESCRIPTION
    Combines multiple PDF files into a single PDF document.

.PARAMETER InputFiles
    Array of PDF file paths to merge (in order)

.PARAMETER OutputFile
    Path for the merged output PDF

.EXAMPLE
    ./merge_pdfs.ps1 -InputFiles @("file1.pdf", "file2.pdf") -OutputFile "merged.pdf"
    Get-ChildItem *.pdf | ./merge_pdfs.ps1 -OutputFile "combined.pdf"
#>
param(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string[]]$InputFiles,
    
    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

begin {
    $files = @()
}

process {
    $files += $InputFiles
}

end {
    if ($files.Count -lt 2) {
        Write-Error "At least 2 PDF files are required for merging"
        return
    }
    
    # Resolve paths
    $resolvedFiles = $files | ForEach-Object { Resolve-Path $_ -ErrorAction Stop }
    $outputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
    
    # Ensure output directory exists
    $outputDir = Split-Path -Parent $outputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    function Merge-WithPdfLib {
        param($inFiles, $outFile)
        
        $code = @"
using System;
using System.IO;
using iText.Kernel.Pdf;

public class PdfMerger {
    public static void Merge(string[] inputFiles, string outputFile) {
        using (PdfWriter writer = new PdfWriter(outputFile)) {
            using (PdfDocument merged = new PdfDocument(writer)) {
                foreach (string file in inputFiles) {
                    using (PdfReader reader = new PdfReader(file)) {
                        using (PdfDocument doc = new PdfDocument(reader)) {
                            doc.CopyPagesTo(1, doc.GetNumberOfPages(), merged);
                        }
                    }
                }
            }
        }
    }
}
"@
        try {
            Add-Type -TypeDefinition $code -ReferencedAssemblies @("itext.kernel.dll", "itext.io.dll") -ErrorAction Stop
            [PdfMerger]::Merge($inFiles, $outFile)
            return $true
        }
        catch {
            return $false
        }
    }
    
    function Merge-WithPython {
        param($inFiles, $outFile)
        
        $pyScript = @"
import sys
from PyPDF2 import PdfMerger

files = sys.argv[1:-1]
output = sys.argv[-1]

merger = PdfMerger()
for pdf in files:
    merger.append(pdf)
merger.write(output)
merger.close()
print("Merge complete")
"@
        
        $tempScript = [System.IO.Path]::GetTempFileName() + ".py"
        $pyScript | Out-File -FilePath $tempScript -Encoding UTF8
        
        try {
            python $tempScript @inFiles $outFile
            return $?
        }
        finally {
            Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
        }
    }
    
    $success = Merge-WithPdfLib -inFiles $resolvedFiles -outFile $outputPath
    
    if (-not $success) {
        $success = Merge-WithPython -inFiles $resolvedFiles -outFile $outputPath
    }
    
    if ($success) {
        Write-Host "Merged PDF saved to: $outputPath"
    } else {
        Write-Error "Failed to merge PDFs. Please install Python with PyPDF2 or iText libraries."
    }
}
