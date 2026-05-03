<#
.SYNOPSIS
    Safely upload a local file to Lark/Feishu Drive.

.DESCRIPTION
    Wraps lark-cli drive upload handling PowerShell-specific issues:
    - Avoids @file syntax (PowerShell splatting operator conflict)
    - Validates file exists before upload
    - Returns the file_token for further use

.PARAMETER FilePath
    Path to the local file to upload.

.PARAMETER FolderToken
    Optional destination folder token (fldxxxx). If omitted, uploads to root.

.PARAMETER FileName
    Optional custom filename. Default: original filename.

.EXAMPLE
    .\upload-file.ps1 -FilePath "report.pdf"
    .\upload-file.ps1 -FilePath "report.pdf" -FolderToken "fldxxxx" -FileName "Q1-Report.pdf"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,

    [Parameter(Mandatory=$false)]
    [string]$FolderToken,

    [Parameter(Mandatory=$false)]
    [string]$FileName
)

$FilePath = Resolve-Path $FilePath -ErrorAction Stop

if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

$actualName = if ($FileName) { $FileName } else { [System.IO.Path]::GetFileName($FilePath) }

Write-Host "Uploading $actualName to Lark Drive ..." -ForegroundColor Cyan

# Build data JSON
$dataObj = @{ file_name = $actualName }
if ($FolderToken) {
    $dataObj.folder_token = $FolderToken
}
$dataJson = $dataObj | ConvertTo-Json -Compress

# Use cmd /c to bypass PowerShell's interpretation of @ and other special chars
# lark-cli drive files upload requires --data and --file
$cmd = "npx @larksuite/cli drive files upload --data `"$dataJson`" --file `"$FilePath`" --format json"

# Escape for cmd
$cmdEscaped = $cmd -replace '"', '\"'
$resultText = cmd /c "$cmdEscaped" 2>$null

# Try to parse JSON response
$result = $resultText | ConvertFrom-Json -ErrorAction SilentlyContinue

if ($result -and $result.data -and $result.data.file_token) {
    $token = $result.data.file_token
    Write-Host "Upload successful. File token: $token" -ForegroundColor Green
    return $token
} else {
    Write-Warning "Upload may have succeeded but response parsing failed."
    Write-Host "Raw response:" -ForegroundColor Gray
    Write-Host $resultText
    return $null
}
