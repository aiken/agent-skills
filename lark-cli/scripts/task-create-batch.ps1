<#
.SYNOPSIS
    Batch create tasks in Lark/Feishu from a JSON file.

.DESCRIPTION
    Reads a JSON array of task objects and creates each task via lark-cli.
    Each object supports: summary, due (ISO or relative like +3d), description,
    assignee_open_ids (array), and followers (array).

.PARAMETER InputFile
    Path to JSON file containing task array.

.PARAMETER TasklistGuid
    Optional tasklist GUID to add all created tasks to.

.PARAMETER DelayMs
    Delay between requests in milliseconds. Default: 500

.EXAMPLE
    .\task-create-batch.ps1 -InputFile "tasks.json"
    .\task-create-batch.ps1 -InputFile "tasks.json" -TasklistGuid "guid-xxxx"

    # tasks.json format:
    # [
    #   { "summary": "Task 1", "due": "+3d", "description": "Details" },
    #   { "summary": "Task 2", "due": "2026-06-01", "assignee_open_ids": ["ou_xxx"] }
    # ]
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$InputFile,

    [Parameter(Mandatory=$false)]
    [string]$TasklistGuid,

    [Parameter(Mandatory=$false)]
    [int]$DelayMs = 500
)

$InputFile = Resolve-Path $InputFile -ErrorAction Stop
$tasks = Get-Content $InputFile -Raw | ConvertFrom-Json

if (-not ($tasks -is [System.Collections.IEnumerable])) {
    Write-Error "Input file must contain a JSON array of tasks."
    exit 1
}

$created = @()

foreach ($t in $tasks) {
    if (-not $t.summary) {
        Write-Warning "Skipping task without summary."
        continue
    }

    $data = @{ summary = $t.summary }
    if ($t.due) { $data.due = $t.due }
    if ($t.description) { $data.description = $t.description }
    if ($t.assignee_open_ids) { $data.assignee_open_ids = $t.assignee_open_ids }
    if ($t.followers) { $data.followers = $t.followers }

    $dataJson = $data | ConvertTo-Json -Compress
    Write-Host "Creating: $($t.summary) ..." -ForegroundColor Cyan -NoNewline

    $resultText = npx @larksuite/cli task +create --data "$dataJson" --format json 2>$null
    $result = $resultText | ConvertFrom-Json -ErrorAction SilentlyContinue

    if ($result -and $result.data -and $result.data.guid) {
        $guid = $result.data.guid
        Write-Host " OK ($guid)" -ForegroundColor Green
        $created += $guid

        if ($TasklistGuid) {
            Start-Sleep -Milliseconds 200
            npx @larksuite/cli task +tasklist-task-add --tasklist-id "$TasklistGuid" --task-id "$guid" >$null 2>$null
        }
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-Host "  Response: $resultText" -ForegroundColor Gray
    }

    if ($DelayMs -gt 0) {
        Start-Sleep -Milliseconds $DelayMs
    }
}

Write-Host "`nCreated $($created.Count) / $($tasks.Count) tasks." -ForegroundColor Green

if ($TasklistGuid) {
    Write-Host "Added to tasklist: $TasklistGuid" -ForegroundColor Green
}
