#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Extract structured content from a .docx file with metadata

.DESCRIPTION
    Reads a Word document and extracts text with paragraph numbers and structure info.
    Useful for analysis and precise text replacement planning.

.PARAMETER InputFile
    Path to the .docx file to analyze

.PARAMETER OutputFile
    Optional path to save structured output as JSON

.PARAMETER Format
    Output format: Text, Json, or List

.EXAMPLE
    ./extract_docx.ps1 -InputFile "document.docx" -Format Json
    ./extract_docx.ps1 -InputFile "document.docx" -OutputFile "content.json" -Format Json
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Text", "Json", "List")]
    [string]$Format = "List"
)

$InputFile = Resolve-Path $InputFile -ErrorAction Stop
$tempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($InputFile, $tempDir)
    
    $docPath = Join-Path $tempDir "word\document.xml"
    if (-not (Test-Path $docPath)) {
        throw "Invalid .docx file"
    }
    
    [xml]$xml = Get-Content $docPath -Encoding UTF8 -Raw
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace('w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main')
    
    $paragraphs = $xml.SelectNodes('//w:p', $ns)
    $items = [System.Collections.ArrayList]::new()
    $index = 0
    
    foreach ($p in $paragraphs) {
        $textNodes = $p.SelectNodes('.//w:t', $ns)
        $paraText = ''
        foreach ($t in $textNodes) {
            if ($t.InnerText) {
                $paraText += $t.InnerText
            }
        }
        if ($paraText -ne '') {
            $index++
            [void]$items.Add(@{
                index = $index
                text = $paraText
            })
        }
    }
    
    switch ($Format) {
        "Json" {
            $output = $items | ConvertTo-Json -Depth 3
        }
        "List" {
            $output = $items | ForEach-Object { "$($_.index): $($_.text)" }
            $output = $output -join "`r`n"
        }
        "Text" {
            $output = $items.text -join "`r`n"
        }
    }
    
    if ($OutputFile) {
        $output | Out-File -FilePath $OutputFile -Encoding UTF8
        Write-Host "Content extracted to: $OutputFile"
    } else {
        Write-Output $output
    }
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}
