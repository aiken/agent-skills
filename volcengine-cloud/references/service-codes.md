# Volcengine Service Codes Reference

Complete mapping of `ve` CLI service codes to Volcengine products, including known pitfalls.

## Critical Mismatches

The `ve` CLI often merges multiple products under a single service code, and action names may differ from OpenAPI names.

| Product | You might expect | Actual `ve` service | Actual action | Returns field |
|---|---|---|---|---|
| EIP | `eip` `DescribeEipAddresses` | **`vpc`** | `DescribeEipAddresses` | `Result.EipAddresses` |
| Security Group | `ecs` `DescribeSecurityGroups` | **`vpc`** | `DescribeSecurityGroups` | `Result.SecurityGroups` |
| RDS MySQL instance list | `rds_mysql` `DescribeDBInstances` | `rds_mysql` | **`ListDBInstances`** | **`Result.Datas`** |

## Compute

| Product | `ve` code | Common actions | Parameter quirks |
|---|---|---|---|
| ECS | `ecs` | `DescribeInstances`, `RunInstances`, `StopInstances`, `StartInstances`, `DeleteInstances`, `DescribeKeyPairs`, `CreateKeyPair`, `DeleteKeyPairs` | `DescribeInstances` supports `--RegionId` and `--MaxResults`. `DescribeKeyPairs` supports `--MaxResults` but **not** `--RegionId`. |
| Auto Scaling | `autoscaling` | `DescribeScalingGroups`, `DescribeScalingInstances` | |
| VKE (K8s) | `vke` | `ListClusters`, `CreateCluster`, `DeleteCluster` | |
| FunctionCompute | `fc` | `ListFunctions`, `InvokeFunction` | |

## Networking

| Product | `ve` code | Common actions | Parameter quirks |
|---|---|---|---|
| VPC | `vpc` | `DescribeVpcs`, `CreateVpc`, `DeleteVpc`, `DescribeSubnets`, `CreateSubnet`, `DeleteSubnet` | Standard `--RegionId` + `--MaxResults`. |
| CLB | `clb` | `DescribeLoadBalancers`, `CreateLoadBalancer`, `DeleteLoadBalancer`, `DescribeListeners`, `CreateListener` | Standard `--RegionId` + `--MaxResults`. |
| ALB | `alb` | `DescribeLoadBalancers`, `CreateLoadBalancer`, `DeleteLoadBalancer` | |
| EIP | **`vpc`** | **`DescribeEipAddresses`**, `AllocateEipAddress`, `AssociateEipAddress`, `DisassociateEipAddress`, **`ReleaseEipAddress`** | **Does NOT support `--MaxResults` or `--RegionId`**. Returns all EIPs in the profile region. |
| NAT Gateway | `natgateway` | `DescribeNatGateways`, `CreateNatGateway`, `DeleteNatGateway` | Standard `--RegionId` + `--MaxResults`. |
| Security Group | **`vpc`** | **`DescribeSecurityGroups`**, `CreateSecurityGroup`, **`DeleteSecurityGroup`**, `DescribeSecurityGroupAttributes` | Standard `--RegionId` + `--MaxResults`. |
| VPN | `vpn` | `DescribeVpnGateways`, `CreateVpnGateway` | |

## Storage

| Product | `ve` code | Common actions | Parameter quirks |
|---|---|---|---|
| TOS (Object Storage) | `tos` | `ListBuckets`, `CreateBucket`, `DeleteBucket`, `ListObjects`, `PutObject` | |
| vePFS | `vepfs` | `ListFileSystems`, `CreateFileSystem` | |

## Database

| Product | `ve` code | Common actions | Parameter quirks |
|---|---|---|---|
| RDS MySQL | `rds_mysql` | **`ListDBInstances`**, `DescribeDBInstance`, `CreateDBInstance`, `DeleteDBInstance`, `ListAccounts`, `CreateAccount` | `ListDBInstances` supports `--RegionId` but **not** `--MaxResults`. Returns **`Result.Datas`**. `DescribeDBInstance` requires `--InstanceId`. |
| RDS PostgreSQL | `rds_postgresql` | `DescribeDBInstances`, `CreateDBInstance`, `DeleteDBInstance` | |
| Redis | `redis` | `DescribeDBInstances`, `CreateDBInstance`, `DeleteDBInstance` | |
| MongoDB | `mongodb` | `DescribeDBInstances`, `CreateDBInstance`, `DeleteDBInstance` | |

## Container & DevOps

| Product | `ve` code | Common actions |
|---|---|---|
| CR (Container Registry) | `cr` | `ListRepositories`, `CreateRepository`, `DeleteRepository` |
| CI/CD | `ci` | `ListPipelines`, `RunPipeline` |

## Security & IAM

| Product | `ve` code | Common actions |
|---|---|---|
| IAM | `iam` | `ListUsers`, `ListRoles`, `ListPolicies` |
| KMS | `kms` | `ListKeys`, `CreateKey`, `Encrypt`, `Decrypt` |
| WAF | `waf` | `DescribeInstances`, `CreateInstance` |

## AI & Big Data

| Product | `ve` code | Common actions |
|---|---|---|
| Ark (LLM) | `ark` | `ListEndpoints`, `ChatCompletions` |
| ML Platform | `ml_platform` | `ListJobs`, `SubmitJob` |
| Bytehouse | `bytehouse` | `ListWarehouses`, `ExecuteSQL` |

## Tips

- **Case sensitivity**: Service codes and action names are case-sensitive in the `ve` CLI.
- **Versioned APIs**: Some products have date-suffixed service codes (e.g., `apig20221112`). Use `ve --help` to discover them.
- **Region endpoints**: Most services use the standard endpoint `open.volcengineapi.com`. The CLI resolves the correct endpoint per service automatically.
