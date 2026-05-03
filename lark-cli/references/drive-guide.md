# Drive (File Management) Reference

Complete guide for `lark-cli drive` commands.

## Table of Contents

1. [Upload](#upload)
2. [Download](#download)
3. [Search](#search)
4. [Folders](#folders)
5. [Import/Export](#importexport)
6. [Permissions](#permissions)

## Upload

### Upload a File

**Recommended:** Use the bundled script to avoid PowerShell `@` issues:

```powershell
$token = .\scripts\upload-file.ps1 -FilePath "report.pdf" -FolderToken "fldxxxx"
```

**Direct CLI (careful with PowerShell):**

```powershell
npx @larksuite/cli drive files upload --data '{"file_name":"report.pdf","folder_token":"fldxxxx"}' --file "report.pdf"
```

### Upload to Root

```powershell
npx @larksuite/cli drive files upload --data '{"file_name":"report.pdf"}' --file "report.pdf"
```

## Download

### Download by File Token

```powershell
npx @larksuite/cli drive +download --file-token "boxxxxx" --output "./downloads/"
```

### Download via API

```powershell
npx @larksuite/cli api GET /open-apis/drive/v1/files/boxxxxx/download --output "file.pdf"
```

## Search

### Search Drive Files

```powershell
npx @larksuite/cli drive +search --query "contract"
npx @larksuite/cli drive +search --query "contract" --format pretty
```

### Search with Filters

```powershell
npx @larksuite/cli drive +search --query "report" --format json -q '.data.items[] | {name, type, url}'
```

## Folders

### Create a Folder

```powershell
npx @larksuite/cli drive +create-folder --name "Project-A" --folder-token "fldxxxx"
```

### Move a File

```powershell
npx @larksuite/cli drive +move --file-token "boxxxxx" --folder-token "fldyyyy"
```

### Delete a File

```powershell
npx @larksuite/cli drive +delete --file-token "boxxxxx"
```

## Import/Export

### Import Local File as Cloud Document

```powershell
npx @larksuite/cli drive +import --file "local.docx" --type docx --folder-token "fldxxxx"
```

### Export Cloud Document

```powershell
npx @larksuite/cli drive +export --file-token "docxxxx" --type pdf --output "./exports/"
```

### Check Async Task Status

```powershell
npx @larksuite/cli drive +task_result --ticket "ticket-xxxx"
```

## Permissions

### Apply for Permission

```powershell
npx @larksuite/cli drive +apply-permission --file-token "boxxxxx"
```

### List Permission Members

```powershell
npx @larksuite/cli drive permission.members list --params '{"token":"boxxxxx","type":"file"}'
```

## Sync (Pull/Push)

### Pull from Drive to Local

```powershell
npx @larksuite/cli drive +pull --folder-token "fldxxxx" --local-path "./drive-mirror/"
```

### Push Local to Drive

```powershell
npx @larksuite/cli drive +push --folder-token "fldxxxx" --local-path "./drive-mirror/"
```

### Check Status

```powershell
npx @larksuite/cli drive +status --folder-token "fldxxxx" --local-path "./drive-mirror/"
```
