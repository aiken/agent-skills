# IM (Messaging) Reference

Complete guide for `lark-cli im` commands.

## Table of Contents

1. [Send Messages](#send-messages)
2. [Message Types](#message-types)
3. [Group Chats](#group-chats)
4. [Search & List](#search--list)
5. [Threads](#threads)
6. [Resources](#resources)

## Send Messages

### Send Text Message

```powershell
npx @larksuite/cli im +messages-send `
  --chat-id "oc_xxx" `
  --msg-type text `
  --content '{"text":"Hello team!"}'
```

### Send Markdown Message

```powershell
$npx @larksuite/cli im +messages-send `
  --chat-id "oc_xxx" `
  --msg-type interactive `
  --content '{"elements":[{"tag":"div","text":{"tag":"plain_text","content":"**Bold** text"}}]}'
```

### Send to User (Direct Message)

```powershell
npx @larksuite/cli im +messages-send `
  --user-id "ou_xxx" `
  --msg-type text `
  --content '{"text":"Hi!"}'
```

### Reply to a Message

```powershell
npx @larksuite/cli im +messages-reply `
  --message-id "om_xxx" `
  --msg-type text `
  --content '{"text":"Got it!"}'
```

## Message Types

| Type | Description | Content Format |
|------|-------------|----------------|
| `text` | Plain text | `{"text":"..."}` |
| `post` | Rich text post | Complex JSON with title and content |
| `image` | Image | `{"image_key":"img_xxx"}` |
| `file` | File attachment | `{"file_key":"file_xxx"}` |
| `interactive` | Card message | Card JSON with elements |
| `share_chat` | Share group chat | `{"share_chat_id":"oc_xxx"}` |

## Group Chats

### Create a Group Chat

```powershell
npx @larksuite/cli im +chat-create `
  --name "Project Team" `
  --user-ids '["ou_xxx","ou_yyy"]'
```

### Search Group Chats

```powershell
npx @larksuite/cli im +chat-search --query "Project"
```

### Update Chat Info

```powershell
npx @larksuite/cli im +chat-update --chat-id "oc_xxx" --name "New Name"
```

### List Chat Members

```powershell
npx @larksuite/cli im chat.members list --params '{"chat_id":"oc_xxx"}'
```

## Search & List

### Search Messages

```powershell
npx @larksuite/cli im +messages-search --query "contract" --format pretty
```

### List Messages in a Chat

```powershell
npx @larksuite/cli im +chat-messages-list --chat-id "oc_xxx" --format pretty
```

### Batch Get Messages

```powershell
npx @larksuite/cli im +messages-mget --message-ids '["om_xxx","om_yyy"]'
```

## Threads

### List Thread Messages

```powershell
npx @larksuite/cli im +threads-messages-list --thread-id "omt_xxx"
```

## Resources

### Download Image/File from Message

```powershell
npx @larksuite/cli im +messages-resources-download `
  --message-id "om_xxx" `
  --file-key "file_xxx" `
  --output "./downloads/"
```
