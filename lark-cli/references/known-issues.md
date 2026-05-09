# Known Issues & Workarounds

## Windows/PowerShell Specific

### 1. `@` Splatting Operator Conflict

**Problem:** PowerShell interprets `@file` as a splatting operator, not as a file reference.

**Affected commands:** Any CLI flag that uses `@path` syntax, especially `--file @localpath`.

**Workarounds:**

```powershell
# BAD — PowerShell tries to splat
npx @larksuite/cli drive files upload --file @path/to/file

# GOOD — Use the bundled upload-file.ps1 script
.\scripts\upload-file.ps1 -FilePath "path/to/file"

# GOOD — Use cmd /c to bypass PowerShell interpretation
$cmd = 'npx @larksuite/cli drive files upload --data "{...}" --file "path/to/file"'
cmd /c $cmd

# GOOD — Use --data with inline content instead of @file where possible
```

### 2. JSON String Quoting

**Problem:** PowerShell expands variables in double quotes, which corrupts JSON.

**Solution:** Use single quotes for JSON strings passed to `--data` and `--params`:

```powershell
# BAD — PowerShell expands $null, $true, etc.
npx @larksuite/cli ... --data "{\"key\":\"value\"}"

# GOOD
npx @larksuite/cli ... --data '{"key":"value"}'
```

### 3. Tilde (`~`) Not Expanded

**Problem:** `~` is not expanded to `$HOME` in PowerShell CLI arguments.

**Solution:** Use `$env:USERPROFILE` or full paths:

```powershell
# BAD
npx @larksuite/cli ... --output ~/downloads/

# GOOD
npx @larksuite/cli ... --output "$env:USERPROFILE\Downloads"
```

### 4. Line Continuation

Use backtick `` ` `` for multi-line commands:

```powershell
npx @larksuite/cli task +create `
  --summary "Title" `
  --due "+3d"
```

## lark-cli Bugs

### File Upload Filename Bug (v1.0.23)

**Issue:** Using `--file` to upload files results in the file being named `unknown-file` in Feishu Drive.

**GitHub:** Issue #729, PR #730 (pending merge)

**Workarounds:**
1. Upload via Feishu App web interface manually
2. Use Drive web upload API instead of CLI
3. Wait for v1.0.24 which should include the fix
4. Use the bundled `upload-file.ps1` which attempts to work around this

### Auth Token Expiration

**Issue:** CLI auth token may expire silently, causing commands to fail with auth errors.

**Solution:**

```powershell
# Check auth status
npx @larksuite/cli auth status

# Re-login if needed
npx @larksuite/cli auth login

# Or use doctor to diagnose
npx @larksuite/cli doctor
```

## API-Specific Quirks

### Task Due Date Format

The `+3d` relative format works in shortcut commands (`+create`) but not in raw API calls. Use ISO 8601 for API:

```powershell
# Shortcut (relative)
npx @larksuite/cli task +create --due "+3d"

# API (absolute)
npx @larksuite/cli api POST /open-apis/task/v2/tasks --data '{
  "due": { "timestamp": "1717200000", "timezone": "Asia/Shanghai" }
}'
```

### Task List vs Task Group

- **Task List** (`tasklist`) — Created via CLI, contains tasks
- **Task Group** (`section`) — Kanban columns within a task list, **NOT** creatable via CLI
- To organize tasks in columns, use Feishu App manually after creation

### Drive File Token Prefixes

| Prefix | Type |
|--------|------|
| `boxxxxx` | File in Drive |
| `docxxxx` | Doc/Docx document |
| `shtxxxx` | Spreadsheet |
| `bitxxxx` | Bitable (Base) |
| `fldxxxx` | Folder |
| `wiki_xxx` | Wiki node |

## PowerShell JSON & Data Passing Pitfalls

### `--data` JSON Validation Fails Despite Correct Syntax

**Problem:** Even when using single quotes and valid JSON, `--data` frequently returns `invalid JSON format` or `invalid format, expected JSON object`.

**Root cause:** PowerShell's argument parsing and encoding handling subtly corrupt JSON strings before they reach Node.js.

**Reliable workaround — Python + `@file`:**
```powershell
# Step 1: Use Python to write a clean UTF-8 JSON file
.venv\Scripts\python.exe -c "import json; json.dump({'key':'value'}, open('data.json','w',encoding='utf-8'), ensure_ascii=False)"

# Step 2: Reference it with a relative-path @file
npx @larksuite/cli api POST /open-apis/task/v2/tasks --data "@data.json"
```

**Critical:** `@file` paths **must be relative** to the current directory. Absolute paths are rejected:
```powershell
# BAD — absolute path rejected
--data "@D:\project\data.json"

# GOOD — cd first, then relative
D:\project> npx @larksuite/cli api POST ... --data "@data.json"
```

### `--params` Rejects Empty Query Strings

**Problem:** `task +search --query ""` returns `query is empty and no filter is provided`.

**Workaround:** Use a non-empty keyword or omit `--query` entirely and use the generic API:
```powershell
# Search with a keyword
npx @larksuite/cli task +search --query "contract"

# Or list all via API
npx @larksuite/cli api GET /open-apis/task/v2/tasks
```

## Task Management Quirks

### Cannot Set Parent Task via `task.tasks.patch`

**Problem:** `parent_task_guid` is **not** in the `update_fields` whitelist for `task.tasks.patch`.

**Error:**
```
Invalid Param 'update_fields'. Only 'summary', 'description', 'due', ... are supported.
```

**Workaround:** You cannot convert an existing task into a subtask via API. Options:
1. Create new subtasks under the parent with `task.subtasks.create` (loses original GUID)
2. Use Feishu App to manually drag-and-drop tasks into parent-child relationships

### `drive +delete` Flag Changes (v1.0.25+)

**Problem:** Older versions accepted positional arguments like `drive +delete token`. v1.0.25+ requires explicit flags.

**Solution:** Use `--file-token` + `--type` + `--yes`:
```powershell
# BAD — positional args no longer supported
npx @larksuite/cli drive +delete "boxxxxx"

# GOOD
npx @larksuite/cli drive +delete --file-token "boxxxxx" --type docx --yes
```

### `drive +import` Flag Changes (v1.0.25+)

**Problem:** `--data @json` was removed. Now uses direct flags.

**Solution:**
```powershell
# BAD — old syntax
npx @larksuite/cli drive +import --data @import.json

# GOOD — v1.0.25+
npx @larksuite/cli drive +import `
  --file "contract.docx" `
  --folder-token "fldxxxx" `
  --name "Contract V2" `
  --type docx
```

### Document Replace Workflow

When updating a document that is referenced elsewhere (task descriptions, indices, etc.), follow this sequence to avoid broken links:

1. **Import the new version** — record the returned `token` and `url`
2. **Update all references** — task descriptions, indices, emails, etc.
3. **Delete the old version** — only after confirming the new one is accessible

```powershell
# Step 1: Import new version
$import = npx @larksuite/cli drive +import `
  --file "contract_v2.docx" `
  --folder-token "fldxxxx" `
  --name "Contract (Latest)" `
  --type docx | ConvertFrom-Json
$newToken = $import.data.token
$newUrl   = $import.data.url

# Step 2: Update references (example: task description)
npx @larksuite/cli task +update `
  --task-id "guid-xxxx" `
  --description "New doc: $newUrl"

# Step 3: Delete old version
npx @larksuite/cli drive +delete `
  --file-token "OLD_TOKEN" `
  --type docx --yes
```

## Drive File Operations

### `drive +upload` Large File Limit (>20MB)

**Problem:** Despite documentation claiming "files > 20MB use multipart upload automatically", uploads still fail with:
```
API error: [1061043] file size beyond limit.
```

**Workarounds:**
1. Compress the file before upload
2. Upload large files via Feishu web interface manually
3. Split into smaller files

### `drive +import` vs `drive +upload`

| Command | Output | Best For |
|---------|--------|----------|
| `drive +upload` | Raw file (PDF, DOCX as attachments) | Final deliverables, scans |
| `drive +import` | Editable Feishu cloud document | Contracts, proposals, reports that need collaborative editing |

**Recommendation:** For any document that will be edited or reviewed in Feishu, use `drive +import --type docx` instead of `drive +upload`.

## Schema Discovery Limitations

### Some Schema Queries Return `Unknown service` or `Unknown method`

**Problem:** `npx @larksuite/cli schema docx.document.create` returns `Unknown service: docx` even though docx operations exist.

**Workaround:** When `schema` fails, use `--help` or trial-and-error with the actual `api` command. Check the CLI's built-in help instead:
```powershell
npx @larksuite/cli drive --help
npx @larksuite/cli task --help
```

## PowerShell Subprocess Best Practice (Windows)

When lark-cli flags are complex or contain special characters, the most reliable approach on Windows is to invoke via Python `subprocess` rather than direct PowerShell:

```python
# save as run_lark.py
import subprocess, json, os
os.chdir(r'D:\project')

def lark(*args):
    result = subprocess.run(
        ['npx', '@larksuite/cli'] + list(args),
        capture_output=True, text=True, encoding='utf-8', shell=True
    )
    return json.loads(result.stdout) if result.stdout else {}

# Example: list folder files
data = lark('drive', 'files', 'list', '--params', '@list_params.json')
print(data['data']['files'])

# Example: import document
data = lark('drive', '+import',
    '--file', 'contract.docx',
    '--folder-token', 'fldxxxx',
    '--name', 'Contract',
    '--type', 'docx')
print(data['data']['url'])
```

**Why:** This completely bypasses PowerShell's argument parsing, splatting (`@`), and line-continuation quirks. The only requirement is that JSON parameter files must still use relative paths for `@file` references.

## Performance Tips

### Rate Limiting

Add delays between bulk operations:

```powershell
# Built into task-create-batch.ps1 with -DelayMs parameter
.\scripts\task-create-batch.ps1 -InputFile "tasks.json" -DelayMs 500
```

### Pagination

Use `--page-all` for automatic pagination, or `--page-size` with manual handling:

```powershell
npx @larksuite/cli task +get-my-tasks --page-all --page-size 50 --page-delay 200
```

### Filtering with jq

Reduce data transfer by filtering at the CLI level:

```powershell
npx @larksuite/cli task +get-my-tasks -q '.data.items[] | {id: .guid, title: .summary}'
```
