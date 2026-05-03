---
name: lark-cli
description: Manage Lark/Feishu (飞书) resources via the official lark-cli. Covers task management, drive files, IM messages, contacts, calendar, base/bitable, docs, and wiki. Use when Kimi needs to (1) create/update/complete tasks or task lists, (2) upload/download/manage files in Drive, (3) send messages to chats or users, (4) query contacts or calendars, (5) work with spreadsheets or documents, (6) troubleshoot lark-cli issues on Windows/PowerShell.
---

# Lark CLI Skill

Manage Lark/Feishu via `npx @larksuite/cli`.

## Quick Start

### Authentication

```powershell
# Login (opens browser for OAuth)
npx @larksuite/cli auth login

# Check status
npx @larksuite/cli auth status
npx @larksuite/cli doctor
```

**Windows/PowerShell critical:** The `@` symbol is a splatting operator in PowerShell. When passing `@file` to CLI flags, it will be misinterpreted. See [Known Issues](references/known-issues.md) for workarounds.

### Core Modules

| Module | Key Commands | Reference |
|--------|-------------|-----------|
| **Task** | `task +create`, `task +complete`, `task tasklists tasks list` | [task-guide.md](references/task-guide.md) |
| **Drive** | `drive +upload`, `drive +download`, `drive +search` | [drive-guide.md](references/drive-guide.md) |
| **IM** | `im +messages-send`, `im +chat-create` | [im-guide.md](references/im-guide.md) |
| **Contact** | `contact +search-user`, `contact +get-user` | See CLI `--help` |
| **Calendar** | `calendar +agenda`, `calendar events instance_view` | See CLI `--help` |
| **Base** | `base tables list`, `base records create` | See CLI `--help` |
| **Docs** | `docs list`, `docs get` | See CLI `--help` |
| **Wiki** | `wiki spaces list`, `wiki nodes list` | See CLI `--help` |

### Output Formats

```powershell
# Pretty-printed table (human readable)
npx @larksuite/cli task +get-my-tasks --format pretty

# JSON (default, good for piping)
npx @larksuite/cli task +get-my-tasks --format json

# Filter with jq
npx @larksuite/cli task +get-my-tasks -q '.data.items[] | {id, summary}'
```

## Project Management Workflow

### 1. Create a Task List (Project)

```powershell
npx @larksuite/cli task +tasklist-create --name "Project-A"
```

### 2. Create a Task

```powershell
npx @larksuite/cli task +create `
  --summary "Review contract draft" `
  --due "+3d" `
  --description "Check legal terms"
```

### 3. Add Task to List

```powershell
npx @larksuite/cli task +tasklist-task-add `
  --tasklist-id "guid-xxxx" `
  --task-id "guid-yyyy"
```

### 4. Mark Complete

```powershell
npx @larksuite/cli task +complete --task-id "guid-yyyy"
```

### 5. Sync Local Index

Use bundled script instead of writing from scratch:

```powershell
.\scripts\sync-task-index.ps1 -TasklistGuid "guid-xxxx" -OutputPath "project_index.json"
```

## File Management Workflow

### Upload a File

**Do NOT use `--file @path` directly in PowerShell.** Use the bundled script:

```powershell
.\scripts\upload-file.ps1 -FilePath "contract.docx" -FolderToken "fldxxxx"
```

Or use the API command with inline data:

```powershell
# First upload via API (returns file_token)
npx @larksuite/cli drive files upload --data '{"file_name":"report.pdf"}' --file "report.pdf"
```

### Search Files

```powershell
npx @larksuite/cli drive +search --query "contract" --format pretty
```

### Download a File

```powershell
npx @larksuite/cli drive +download --file-token "boxxxxx" --output "./downloads/"
```

## Message Notification Workflow

### Send a Message

```powershell
npx @larksuite/cli im +messages-send `
  --chat-id "oc_xxx" `
  --msg-type text `
  --content '{"text":"Task completed: Review contract"}'
```

### Create a Group Chat

```powershell
npx @larksuite/cli im +chat-create `
  --name "Project-A Team" `
  --user-ids '["ou_xxx","ou_yyy"]'
```

## Windows/PowerShell Critical Notes

1. **`@` is a splatting operator** — Never pass `@file` in PowerShell strings to CLI flags. Use `--data` with inline JSON, or use the bundled `upload-file.ps1` script.

2. **Single quotes for JSON** — PowerShell expands variables in double quotes. Pass JSON with single quotes: `--data '{"key":"value"}'`.

3. **Line continuations** — Use backtick `` ` `` for multi-line commands.

4. **File upload filename bug** — `lark-cli` v1.0.23 has a bug where `--file` uploads show as `unknown-file` in Feishu. PR #730 fixes this. Workaround: upload via Feishu App manually, or use Drive web upload API.

5. **Tilde expansion** — PowerShell does NOT expand `~` to `$HOME` in CLI arguments. Use `$env:USERPROFILE` or full paths.

## Bundled Scripts

| Script | Purpose |
|--------|---------|
| `scripts/sync-task-index.ps1` | Sync tasks from a tasklist to local JSON index |
| `scripts/upload-file.ps1` | Safely upload files handling PowerShell `@` issues |
| `scripts/task-create-batch.ps1` | Batch create tasks from a JSON file |

## References

- **[task-guide.md](references/task-guide.md)** — Complete task/tasklist commands, pagination, filtering, bulk operations
- **[drive-guide.md](references/drive-guide.md)** — File upload/download, folder management, permissions, import/export
- **[im-guide.md](references/im-guide.md)** — Message types, group chat, thread replies, resource downloads
- **[known-issues.md](references/known-issues.md)** — PowerShell quirks, CLI bugs, workarounds, FAQ

## Schema Discovery

Use `schema` to inspect any API method's parameters:

```powershell
npx @larksuite/cli schema task.tasks.create --format pretty
npx @larksuite/cli schema drive.files.upload --format pretty
```

## Generic API Calls

When a specific CLI subcommand is unavailable, fall back to the generic API:

```powershell
npx @larksuite/cli api GET /open-apis/task/v2/tasks --params '{"page_size":50}'
npx @larksuite/cli api POST /open-apis/im/v1/messages --data '{"receive_id":"oc_xxx","msg_type":"text","content":"{\"text\":\"hello\"}"}'
```
