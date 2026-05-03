#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Edit text content in a .docx file using string replacement

.DESCRIPTION
    Modifies a Word document by replacing specified text strings.
    Creates a backup of the original file before editing.

.PARAMETER InputFile
    Path to the .docx file to edit

.PARAMETER OutputFile
    Path to save the modified .docx file. If not specified, overwrites original.

.PARAMETER Replacements
    Hashtable of text replacements (oldText -> newText)

.PARAMETER Backup
    Create a backup of the original file

.EXAMPLE
    ./edit_docx.ps1 -InputFile "doc.docx" -Replacements @{"OLD"="NEW"; "[Name]"="John"}
    ./edit_docx.ps1 -InputFile "doc.docx" -OutputFile "doc_new.docx" -Replacements @{"OLD"="NEW"} -Backup
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory=$true)]
    [hashtable]$Replacements,
    
    [Parameter(Mandatory=$false)]
    [switch]$Backup
)

# Resolve paths
$InputFile = Resolve-Path $InputFile -ErrorAction Stop
if (-not $OutputFile) {
    $OutputFile = $InputFile
}

# Create backup if requested
if ($Backup -and $OutputFile -eq $InputFile) {
    $backupPath = "$InputFile.backup"
    Copy-Item -Path $InputFile -Destination $backupPath -Force
    Write-Host "Backup created: $backupPath"
}

# Create temp directory
$tempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    # Extract docx
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($InputFile, $tempDir)
    
    # Edit document.xml
    $docPath = Join-Path $tempDir "word\document.xml"
    if (-not (Test-Path $docPath)) {
        throw "Invalid .docx file: document.xml not found"
    }
    
    $content = Get-Content $docPath -Encoding UTF8 -Raw
    
    # Perform replacements
    foreach ($old in $Replacements.Keys) {
        $new = $Replacements[$old]
        # Escape XML special characters in replacement text
        $new = $new -replace '&', '&amp;'
        $new = $new -replace '<', '&lt;'
        $new = $new -replace '>', '&gt;'
        $new = $new -replace '"', '&quot;'
        $content = $content -replace [regex]::Escape($old), $new
    }
    
    # Save modified content
    $content | Out-File -FilePath $docPath -Encoding UTF8 -NoNewline
    
    # Repackage docx
    if (Test-Path $OutputFile) {
        Remove-Item -Path $OutputFile -Force
    }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $OutputFile)
    
    Write-Host "Document saved: $OutputFile"
}
finally {
    # Cleanup
    if (Test-Path $tempDir) {
        Remove-Item -Path $tempDir -Recurse -Force
    }
}
