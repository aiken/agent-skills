#Requires -Version 5.1
<#
.SYNOPSIS
    Compare live Volcengine resources against Terraform state to find orphans.
.DESCRIPTION
    Reads a JSON file produced by list-all.ps1 (live resources) and a Terraform
    state JSON (from `terraform show -json`), then produces orphaned-resources.json
    containing cloud resources not tracked by Terraform.
.PARAMETER LiveJsonPath
    Path to the live resources JSON (from list-all.ps1).
.PARAMETER StateJsonPath
    Path to the Terraform state JSON.
.PARAMETER OutputPath
    Path for the orphaned resources report (default: ./orphaned-resources.json).
.EXAMPLE
    .\compare-tfstate.ps1 -LiveJsonPath ./volc-resources.json -StateJsonPath ./terraform.tfstate
#>
param(
    [Parameter(Mandatory)]
    [string]$LiveJsonPath,
    [Parameter(Mandatory)]
    [string]$StateJsonPath,
    [string]$OutputPath = 'orphaned-resources.json'
)

$ErrorActionPreference = 'Stop'

function Read-Json($path) {
    $content = Get-Content -Path $path -Raw -Encoding UTF8
    return $content | ConvertFrom-Json -AsHashtable
}

$live = Read-Json $LiveJsonPath
$state = Read-Json $StateJsonPath

# Extract Terraform-managed resource IDs
$managedIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

if ($state.values -and $state.values.root_module -and $state.values.root_module.resources) {
    foreach ($res in $state.values.root_module.resources) {
        # Direct resource ID fields
        if ($res.values) {
            $idFields = @('id','instance_id','vpc_id','subnet_id','load_balancer_id','allocation_id','nat_gateway_id','security_group_id','key_pair_name','bucket_name')
            foreach ($f in $idFields) {
                if ($res.values[$f]) { [void]$managedIds.Add($res.values[$f]) }
            }
            # Nested blocks (e.g. servers in CLB server group)
            if ($res.values.servers -and $res.values.servers -is [array]) {
                foreach ($s in $res.values.servers) {
                    if ($s.instance_id) { [void]$managedIds.Add($s.instance_id) }
                }
            }
        }
    }
}

# Also check child modules
function Walk-Modules($mod) {
    if ($mod.resources) {
        foreach ($res in $mod.resources) {
            if ($res.values) {
                $idFields = @('id','instance_id','vpc_id','subnet_id','load_balancer_id','allocation_id','nat_gateway_id','security_group_id','key_pair_name','bucket_name')
                foreach ($f in $idFields) {
                    if ($res.values[$f]) { [void]$managedIds.Add($res.values[$f]) }
                }
            }
        }
    }
    if ($mod.child_modules) {
        foreach ($child in $mod.child_modules) { Walk-Modules $child }
    }
}

if ($state.values -and $state.values.root_module) {
    Walk-Modules $state.values.root_module
}

# Identify orphaned resources per category
$orphans = @{}

$categoryMap = @{
    'ECS'            = @{ Array = $live.ECS;            IdField = 'InstanceId' }
    'VPC'            = @{ Array = $live.VPC;            IdField = 'VpcId' }
    'Subnets'        = @{ Array = $live.Subnets;        IdField = 'SubnetId' }
    'CLB'            = @{ Array = $live.CLB;            IdField = 'LoadBalancerId' }
    'EIP'            = @{ Array = $live.EIP;            IdField = 'AllocationId' }
    'NAT'            = @{ Array = $live.NAT;            IdField = 'NatGatewayId' }
    'RDS'            = @{ Array = $live.RDS;            IdField = 'InstanceId' }
    'SecurityGroups' = @{ Array = $live.SecurityGroups; IdField = 'SecurityGroupId' }
    'KeyPairs'       = @{ Array = $live.KeyPairs;       IdField = 'KeyPairName' }
    'TOSBuckets'     = @{ Array = $live.TOSBuckets;     IdField = 'Name' }
}

foreach ($cat in $categoryMap.Keys) {
    $cfg = $categoryMap[$cat]
    if (-not $cfg.Array) { continue }
    $orphanList = $cfg.Array | Where-Object {
        $id = $_.($cfg.IdField)
        -not $managedIds.Contains($id)
    }
    if ($orphanList) {
        $orphans[$cat] = $orphanList
    }
}

$orphans | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8

Write-Host "Managed resource IDs found in state: $($managedIds.Count)"
Write-Host "Orphaned resources by category:"
$orphans.Keys | ForEach-Object {
    $count = if ($orphans[$_] -is [array]) { $orphans[$_].Count } else { 0 }
    Write-Host "  $_ : $count"
}
Write-Host "Report saved to $OutputPath"
