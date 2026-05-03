---
name: volcengine-cloud
description: |
  Manage Volcengine (ByteDance Cloud / 火山引擎) resources via the official `ve` CLI.
  Use when Kimi needs to: (1) query, list, or describe cloud resources on Volcengine,
  (2) compare live cloud resources against Terraform/Ansible/Pulumi state to find
  orphaned/unmanaged resources, (3) clean up or delete Volcengine resources safely,
  (4) troubleshoot provider drift by checking raw API responses, (5) convert
  Terraform resource attributes into `ve` CLI parameters. Covers ECS, VPC, Subnet,
  CLB/ALB, EIP, NAT Gateway, RDS MySQL, TOS, VKE, CR, IAM/Security Groups, KeyPairs,
  and Auto Scaling. Works with any region and any account.
---

# Volcengine Cloud Skill

## Prerequisites

1. **Install `ve` CLI** — Download the latest release for your OS from
   https://github.com/volcengine/volcengine-cli/releases.
   - Windows: `volcengine-cli_*_windows_amd64.zip` → extract `ve.exe` → add to PATH.
   - macOS/Linux: extract `ve` → `chmod +x ve` → move to `$PATH`.

2. **Configure credentials** (pick one):
   ```bash
   # Profile-based (recommended)
   ve configure set --profile default --region <region> --access-key <AK> --secret-key <SK>

   # Environment variables
   export VOLCENGINE_ACCESS_KEY=<AK>
   export VOLCENGINE_SECRET_KEY=<SK>
   export VOLCENGINE_REGION=<region>
   ```

3. **Verify**:
   ```bash
   ve ecs DescribeInstances --MaxResults 5
   ```

## Command Structure

```
ve <service> <action> [--parameter value ...]
```

- `ve --help` — list all services.
- `ve <service> --help` — list actions for a service.
- `ve <service> <action> --help` — view parameters and examples.

## Critical Pitfalls (Learned from Real Usage)

### 1. Service Code Mismatches

Many Volcengine products share a single `ve` service code. **Do not assume action names match OpenAPI names.**

| Product | Expected service | Actual `ve` service | Notes |
|---|---|---|---|
| EIP | `eip` | **`vpc`** | `DescribeEipAddresses`, `AllocateEipAddress`, `ReleaseEipAddress` are under `vpc` |
| Security Group | `ecs` | **`vpc`** | `DescribeSecurityGroups`, `CreateSecurityGroup`, `DeleteSecurityGroup` are under `vpc` |
| RDS MySQL instance list | `rds_mysql` `DescribeDBInstances` | **`rds_mysql` `ListDBInstances`** | Action name differs; returns `Result.Datas` not `Result.Instances` |

Always run `ve <service> --help` to discover the exact action names exposed by the CLI.

### 2. Parameter Support Varies by API

Not all `Describe*` APIs accept `--MaxResults` or `--RegionId`:

| API | `--RegionId` | `--MaxResults` | Notes |
|---|---|---|---|
| `ecs DescribeInstances` | ✅ | ✅ | Standard pagination |
| `vpc DescribeVpcs` | ✅ | ✅ | Standard pagination |
| `vpc DescribeSubnets` | ✅ | ✅ | Standard pagination |
| `clb DescribeLoadBalancers` | ✅ | ✅ | Standard pagination |
| `natgateway DescribeNatGateways` | ✅ | ✅ | Standard pagination |
| `vpc DescribeSecurityGroups` | ✅ | ✅ | Standard pagination |
| `ecs DescribeKeyPairs` | ❌ | ✅ | Region from profile only |
| `vpc DescribeEipAddresses` | ❌ | ❌ | No pagination params; returns all |
| `rds_mysql ListDBInstances` | ✅ | ❌ | Use `--RegionId`; no `--MaxResults` |

**If you get `unknown flag: --MaxResults` or `unknown flag: --RegionId`, remove that flag and retry.**

### 3. Response Field Names Differ

| API | Expected field | Actual field in `ve` output |
|---|---|---|
| `rds_mysql ListDBInstances` | `Result.Instances` | **`Result.Datas`** |
| `ecs DescribeKeyPairs` | `Result.KeyPairs` | `Result.KeyPairs` ✅ |
| `vpc DescribeEipAddresses` | `Result.EipAddresses` | `Result.EipAddresses` ✅ |

Always inspect raw JSON (`ve <svc> <act> | ConvertFrom-Json | ConvertTo-Json -Depth 3`) before writing selectors.

### 4. PowerShell Pipeline Quirks

In PowerShell, chaining multiple `ve` calls through `ConvertFrom-Json` in a single script can silently drop data for some APIs. **Use file-based capture for reliability:**

```powershell
$tmp = [System.IO.Path]::GetTempFileName()
ve ecs DescribeInstances --RegionId cn-beijing --MaxResults 100 > $tmp 2>$null
$json = Get-Content $tmp -Raw | ConvertFrom-Json
Remove-Item $tmp
```

The bundled `scripts/list-all.ps1` already handles this.

### 5. Signature Errors with SK

If `SignatureDoesNotMatch` occurs after `ve configure set`, the SK may be a base64-looking string that must be passed **verbatim** without decoding. Re-run:

```bash
ve configure set --profile default --region <region> --access-key <AK> --secret-key "<exact-SK-string>"
```

## Workflows

### 1. Discover All Resources in a Region

```bash
./scripts/list-all.ps1 -RegionId cn-beijing -OutputPath ./volc-resources.json
```

Outputs JSON with sections: `ECS`, `VPC`, `Subnets`, `CLB`, `EIP`, `NAT`, `RDS`, `SecurityGroups`, `KeyPairs`, `TOSBuckets`.

### 2. Find Orphaned / Unmanaged Resources

```bash
# If you have a Terraform state JSON file
./scripts/compare-tfstate.ps1 -LiveJsonPath ./volc-resources.json -StateJsonPath ./terraform.tfstate

# Or parse Terraform state inline
terraform show -json > tf-state.json
./scripts/compare-tfstate.ps1 -LiveJsonPath ./volc-resources.json -StateJsonPath ./tf-state.json
```

Produces `orphaned-resources.json`.

### 3. Safe Resource Cleanup

**Never delete without explicit user confirmation.**

```bash
./scripts/cleanup.ps1 -OrphanedJsonPath ./orphaned-resources.json -DryRun
```

Remove `-DryRun` after user confirms.

## Service Code Reference

See [`references/service-codes.md`](references/service-codes.md) for the full mapping of `ve` CLI service codes to Volcengine products and common actions.

Quick lookup for frequently used services:

| Product | `ve` code | List action | Delete action |
|---|---|---|---|
| ECS | `ecs` | `DescribeInstances` | `DeleteInstances` |
| VPC | `vpc` | `DescribeVpcs` | `DeleteVpc` |
| Subnet | `vpc` | `DescribeSubnets` | `DeleteSubnet` |
| CLB | `clb` | `DescribeLoadBalancers` | `DeleteLoadBalancer` |
| ALB | `alb` | `DescribeLoadBalancers` | `DeleteLoadBalancer` |
| EIP | **`vpc`** | **`DescribeEipAddresses`** | **`ReleaseEipAddress`** |
| NAT Gateway | `natgateway` | `DescribeNatGateways` | `DeleteNatGateway` |
| RDS MySQL | `rds_mysql` | **`ListDBInstances`** | `DeleteDBInstance` |
| Security Group | **`vpc`** | **`DescribeSecurityGroups`** | **`DeleteSecurityGroup`** |
| KeyPair | `ecs` | `DescribeKeyPairs` | `DeleteKeyPairs` |
| TOS Bucket | `tos` | `ListBuckets` | `DeleteBucket` |
| VKE Cluster | `vke` | `ListClusters` | `DeleteCluster` |
| CR Repository | `cr` | `ListRepositories` | `DeleteRepository` |

## Tips

1. **Pagination**: Default `MaxResults` is often 10–20. Pass `--MaxResults 100` for inventory scripts where supported. Use `--PageNumber` to iterate.
2. **Region parameter naming inconsistency**: Some APIs use `--RegionId`, others rely on the profile region. If a call fails with "region missing", try adding `--RegionId <region>`.
3. **Deletion dependencies**: Volcengine enforces dependency order (EIP disassociate before release; ECS stop before deletion; subnet empty before deletion). The `cleanup.ps1` script handles ordering automatically.
4. **Date formats**: API responses use ISO 8601 (`2026-04-22T07:38:32Z` or `+08:00`).
5. **Dry-run first**: Always run destructive commands with `-DryRun` before actual execution.
