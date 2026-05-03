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
