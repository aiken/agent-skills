<#
.SYNOPSIS
    Sync tasks from a Lark/Feishu tasklist to a local JSON index.

.DESCRIPTION
    Queries a tasklist via lark-cli, extracts task metadata (id, title, status,
    due date, assignees), and writes a local JSON file. This JSON is a read-only
    snapshot; the tasklist in Lark remains the source of truth.

.PARAMETER TasklistGuid
    The GUID of the tasklist to sync.

.PARAMETER OutputPath
    Output JSON file path. Default: ./project_index.json

.PARAMETER IncludeCompleted
    Also include completed tasks. Default: $false (only incomplete)

.EXAMPLE
    .\sync-task-index.ps1 -TasklistGuid "1a984d45-b3b9-4143-9f05-4539fce893a2"
    .\sync-task-index.ps1 -TasklistGuid "guid" -OutputPath "tasks.json" -IncludeCompleted
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$TasklistGuid,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "./project_index.json",

    [Parameter(Mandatory=$false)]
    [bool]$IncludeCompleted = $false
)

Write-Host "Syncing tasklist $TasklistGuid ..." -ForegroundColor Cyan

$apiPath = "/open-apis/task/v2/tasklists/$TasklistGuid/tasks"
$resultText = npx @larksuite/cli api GET "$apiPath" --format json 2>$null
$result = $resultText | ConvertFrom-Json -ErrorAction SilentlyContinue

if (-not $result -or -not $result.data -or -not $result.data.items) {
    Write-Error "Failed to fetch tasks or no tasks found."
    exit 1
}

[array]$tasks = $result.data.items | ForEach-Object {
    [PSCustomObject]@{
        guid        = $_.guid
        summary     = $_.summary
        status      = if ($_.completed_at -and $_.completed_at -ne "0") { "done" } else { "todo" }
        due         = if ($_.due) { $_.due.timestamp } else { $null }
        assignees   = ($_.members | Where-Object { $_.role -eq "assignee" } | ForEach-Object { $_.id }) -join ", "
        url         = "https://applink.feishu.cn/client/todo/detail?guid=$($_.guid)"
    }
}

if (-not $IncludeCompleted) {
    $tasks = $tasks | Where-Object { $_.status -ne "done" }
}

$index = [PSCustomObject]@{
    synced_at  = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    tasklist   = $TasklistGuid
    task_count = $tasks.Count
    tasks      = $tasks
}

$index | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "Synced $($tasks.Count) tasks to $OutputPath" -ForegroundColor Green
