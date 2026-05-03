#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Extract text content from a .docx file

.DESCRIPTION
    Reads a Word document (.docx) and extracts all text content while preserving
    paragraph structure. Output is written as UTF-8 encoded text.

.PARAMETER InputFile
    Path to the .docx file to read

.PARAMETER OutputFile
    Optional path to save extracted text. If not specified, outputs to stdout.

.EXAMPLE
    ./read_docx.ps1 -InputFile "document.docx"
    ./read_docx.ps1 -InputFile "document.docx" -OutputFile "content.txt"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile
)

# Resolve full path
$InputFile = Resolve-Path $InputFile -ErrorAction Stop

# Create temp directory
$tempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Extract docx (it's a zip file)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($InputFile, $tempDir)
    
    # Read document.xml
    $docPath = Join-Path $tempDir "word\document.xml"
    if (-not (Test-Path $docPath)) {
        throw "Invalid .docx file: document.xml not found"
    }
    
    # Load XML with proper namespace handling
    [xml]$xml = Get-Content $docPath -Encoding UTF8 -Raw
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
    
    # Extract text from all paragraphs
    $paragraphs = $xml.SelectNodes('//w:p', $ns)
    $result = [System.Collections.ArrayList]::new()
    
    foreach ($p in $paragraphs) {
        $textNodes = $p.SelectNodes('.//w:t', $ns)
        $paraText = ''
        foreach ($t in $textNodes) {
            if ($t.InnerText) {
                $paraText += $t.InnerText
            }
        }
        if ($paraText -ne '') {
            [void]$result.Add($paraText)
        }
    }
    
    # Output result
    $output = $result -join "`r`n"
    
    if ($OutputFile) {
        $output | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "Text extracted to: $OutputFile"
    } else {
        Write-Output $output
    }
}
finally {
    # Cleanup temp directory
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}
