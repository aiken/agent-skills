#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Display information about a PDF file

.DESCRIPTION
    Shows metadata, page count, and other information about a PDF file.

.PARAMETER InputFile
    Path to the PDF file

.EXAMPLE
    ./pdf_info.ps1 -InputFile "document.pdf"
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile
)

$InputFile = Resolve-Path $InputFile -ErrorAction Stop

$pythonCode = @"
import sys
from PyPDF2 import PdfReader

pdf_path = sys.argv[1]
reader = PdfReader(pdf_path)

info = reader.metadata

print(f"文件: {pdf_path}")
print(f"页数: {len(reader.pages)}")
print("")

if info:
    print("PDF 元数据:")
    if info.title:
        print(f"  标题: {info.title}")
    if info.author:
        print(f"  作者: {info.author}")
    if info.subject:
        print(f"  主题: {info.subject}")
    if info.creator:
        print(f"  创建者: {info.creator}")
    if info.producer:
        print(f"  生成器: {info.producer}")
    if info.creation_date:
        print(f"  创建日期: {info.creation_date}")
    if info.modification_date:
        print(f"  修改日期: {info.modification_date}")
else:
    print("无元数据")

# Check for encryption
if reader.is_encrypted:
    print("\n状态: 已加密")
else:
    print("\n状态: 未加密")

# Sample text from first page
if len(reader.pages) > 0:
    try:
        first_page_text = reader.pages[0].extract_text()[:200]
        if first_page_text:
            print(f"\n第一页预览:\n{first_page_text}...")
    except:
        pass
"@

$tempScript = [System.IO.Path]::GetTempFileName() + ".py"
$pythonCode | Out-File -FilePath $tempScript -Encoding UTF8

try {
    python $tempScript $InputFile
}
catch {
    Write-Error "Failed to read PDF info. Please install Python with PyPDF2."
}
finally {
    Remove-Item $tempScript -Force -ErrorAction SilentlyContinue
}
