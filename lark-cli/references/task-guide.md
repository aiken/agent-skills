# Task Management Reference

Complete guide for `lark-cli task` commands.

## Table of Contents

1. [Task Lists (Projects)](#task-lists)
2. [Tasks](#tasks)
3. [Bulk Operations](#bulk-operations)
4. [Comments & Attachments](#comments--attachments)
5. [Pagination](#pagination)

## Task Lists

### Search Task Lists

```powershell
npx @larksuite/cli task +tasklist-search
npx @larksuite/cli task +tasklist-search --query "Project"
```

### Create a Task List

```powershell
npx @larksuite/cli task +tasklist-create --name "Project Alpha"
```

### Add Tasks to a List

```powershell
npx @larksuite/cli task +tasklist-task-add --tasklist-id "guid" --task-id "guid"
```

### List Tasks in a Task List

**Note:** The subcommand `task tasklists tasks list` accepts `--params` for query parameters only. The required `tasklist_guid` is a path parameter, so `--params` cannot pass it correctly. Use the generic API instead:

```powershell
npx @larksuite/cli api GET /open-apis/task/v2/tasklists/guid/tasks --format pretty

# With filters
npx @larksuite/cli api GET /open-apis/task/v2/tasklists/guid/tasks --params '{"completed":"false","page_size":50}'
```

## Tasks

### Create a Task

```powershell
npx @larksuite/cli task +create --summary "Review PR" --due "+3d"
npx @larksuite/cli task +create --summary "Deploy" --due "2026-06-01T10:00:00+08:00"
```

Using the API command for more control:

```powershell
npx @larksuite/cli api POST /open-apis/task/v2/tasks --data '{
  "summary": "Review PR",
  "due": { "timestamp": "1717200000", "timezone": "Asia/Shanghai" },
  "description": "Check code quality"
}'
```

### Update a Task

```powershell
# Update title
npx @larksuite/cli task +update --task-id "guid" --summary "New title"

# Update due date
npx @larksuite/cli task +update --task-id "guid" --due "+7d"

# Update description (supports markdown)
npx @larksuite/cli task +update --task-id "guid" --description "Updated info..."
```

**Note:** `task +update` uses `--task-id` (not `--task-guid`). For updating `description`, the string can be multi-line markdown. On Windows, passing long descriptions directly in PowerShell is fragile — use the Python subprocess pattern (see known-issues.md) or write to a file and use `--description (Get-Content desc.txt -Raw)`.

### Complete / Reopen

```powershell
npx @larksuite/cli task +complete --task-id "guid"
npx @larksuite/cli task +reopen --task-id "guid"
```

### Get Task Details

```powershell
# Shortcut command
npx @larksuite/cli task tasks get --params '{"task_guid":"guid-xxxx"}'

# Or via generic API
npx @larksuite/cli api GET /open-apis/task/v2/tasks/guid-xxxx
```

**Response includes:** `description`, `attachments` (file list with `file_token`, `name`, `url`), `subtask_count`, `parent_task_guid`, `tasklists`, etc.

**Note:** Task attachments contain a temporary `url` (valid for 3 minutes, max 3 downloads). To persistently access an attachment, use its `file_token` with Drive APIs.

### Search Tasks

```powershell
npx @larksuite/cli task +search --query "contract"
```

### Get My Tasks

```powershell
npx @larksuite/cli task +get-my-tasks --format pretty
npx @larksuite/cli task +get-my-tasks -q '.data.items[] | {id: .guid, title: .summary, done: .completed}'
```

## Bulk Operations

For batch creation, use the bundled script:

```powershell
.\scripts\task-create-batch.ps1 -InputFile "tasks.json" -TasklistGuid "guid"
```

For batch completion (PowerShell pipeline):

```powershell
$tasks = npx @larksuite/cli task +get-my-tasks --format json | ConvertFrom-Json
$tasks.data.items | Where-Object { $_.summary -like "*review*" } | ForEach-Object {
    npx @larksuite/cli task +complete --task-id $_.guid
}
```

## Comments & Attachments

### Add a Comment

```powershell
npx @larksuite/cli task +comment --task-id "guid" --content "LGTM"
```

### Upload Attachment

Note: `task_attachment` API exists but the `--file` flag has a filename bug in v1.0.23.
Workaround: upload to Drive first, then attach the file_token.

```powershell
# 1. Upload to Drive
$token = .\scripts\upload-file.ps1 -FilePath "doc.pdf"

# 2. Attach to task (if supported by your CLI version)
npx @larksuite/cli task task_attachment create --params '{"task_guid":"guid"}' --data '{"file_token":"'$token'"}'
```

## Pagination

CLI supports automatic pagination:

```powershell
npx @larksuite/cli task +get-my-tasks --page-all --page-size 50
```

For manual pagination via API:

```powershell
npx @larksuite/cli api GET /open-apis/task/v2/tasks --params '{"page_size":50}'
# Use next_page_token from response for subsequent pages
```
