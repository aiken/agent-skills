#Requires -Version 5.1
<#
.SYNOPSIS
    Batch-query all major Volcengine resources in a region and save to JSON.
.DESCRIPTION
    Uses the official `ve` CLI to list ECS, VPC, Subnets, CLB, EIP, NAT Gateway,
    RDS MySQL, Security Groups, and KeyPairs. Handles service-code mismatches,
    parameter incompatibilities, and PowerShell pipeline quirks.
.PARAMETER RegionId
    Volcengine region (default: cn-beijing).
.PARAMETER OutputPath
    Path for the output JSON file (default: ./volc-resources.json).
.PARAMETER VePath
    Path to the `ve` executable if not in PATH.
.EXAMPLE
    .\list-all.ps1
    .\list-all.ps1 -RegionId cn-shanghai -OutputPath ./resources.json
#>
param(
    [string]$RegionId = 'cn-beijing',
    [string]$OutputPath = 'volc-resources.json',
    [string]$VePath = 've'
)

$ErrorActionPreference = 'Continue'

function Invoke-VeFile($service, $action, $extraArgs = @()) {
    <#
    Use file-based capture to avoid PowerShell pipeline data-loss
    when chaining multiple ve calls with ConvertFrom-Json.
    #>
    $tmp = [System.IO.Path]::GetTempFileName()
    $allArgs = @($service, $action) + $extraArgs
    try {
        & $VePath @allArgs > $tmp 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }
        $content = Get-Content $tmp -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) { return $null }
        return $content | ConvertFrom-Json -ErrorAction SilentlyContinue
    } catch { return $null } finally {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }
    }
}

function Drill-Result($resp, $path) {
    <#
    Navigate a nested path like "Result.Datas" on a PSCustomObject.
    #>
    if (-not $resp) { return $null }
    $data = $resp
    foreach ($segment in $path.Split('.')) {
        if ($data -is [hashtable]) {
            if ($data.ContainsKey($segment)) { $data = $data[$segment] } else { return $null }
        } elseif ($data -is [System.Management.Automation.PSCustomObject]) {
            $prop = $data.PSObject.Properties[$segment]
            if ($prop) { $data = $prop.Value } else { return $null }
        } else {
            return $null
        }
    }
    return $data
}

$result = @{}

# ECS: supports --RegionId and --MaxResults
$resp = Invoke-VeFile 'ecs' 'DescribeInstances' @('--RegionId', $RegionId, '--MaxResults', '100')
$result.ECS = Drill-Result $resp 'Result.Instances'

# VPC: supports --RegionId and --MaxResults
$resp = Invoke-VeFile 'vpc' 'DescribeVpcs' @('--RegionId', $RegionId, '--MaxResults', '100')
$result.VPC = Drill-Result $resp 'Result.Vpcs'

# Subnets: supports --RegionId and --MaxResults
$resp = Invoke-VeFile 'vpc' 'DescribeSubnets' @('--RegionId', $RegionId, '--MaxResults', '100')
$result.Subnets = Drill-Result $resp 'Result.Subnets'

# CLB: supports --RegionId and --MaxResults
$resp = Invoke-VeFile 'clb' 'DescribeLoadBalancers' @('--RegionId', $RegionId, '--MaxResults', '100')
$result.CLB = Drill-Result $resp 'Result.LoadBalancers'

# EIP: under vpc service; does NOT support --MaxResults or --RegionId
$resp = Invoke-VeFile 'vpc' 'DescribeEipAddresses'
$result.EIP = Drill-Result $resp 'Result.EipAddresses'

# NAT Gateway: supports --RegionId and --MaxResults
$resp = Invoke-VeFile 'natgateway' 'DescribeNatGateways' @('--RegionId', $RegionId, '--MaxResults', '100')
$result.NAT = Drill-Result $resp 'Result.NatGateways'

# RDS MySQL: action is ListDBInstances (not DescribeDBInstances);
# supports --RegionId but NOT --MaxResults; returns Result.Datas
$resp = Invoke-VeFile 'rds_mysql' 'ListDBInstances' @('--RegionId', $RegionId)
$result.RDS = Drill-Result $resp 'Result.Datas'

# Security Groups: under vpc service; supports --RegionId and --MaxResults
$resp = Invoke-VeFile 'vpc' 'DescribeSecurityGroups' @('--RegionId', $RegionId, '--MaxResults', '100')
$result.SecurityGroups = Drill-Result $resp 'Result.SecurityGroups'

# KeyPairs: under ecs service; supports --MaxResults but NOT --RegionId
$resp = Invoke-VeFile 'ecs' 'DescribeKeyPairs' @('--MaxResults', '100')
$result.KeyPairs = Drill-Result $resp 'Result.KeyPairs'

# TOS Buckets (global list)
$resp = Invoke-VeFile 'tos' 'ListBuckets'
$result.TOSBuckets = Drill-Result $resp 'Result.Buckets'

# Summary
$counts = @{}
$result.GetEnumerator() | ForEach-Object {
    $count = if ($_.Value -is [array]) { $_.Value.Count } else { 0 }
    $counts[$_.Key] = $count
}

$result | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8

Write-Host "Saved to $OutputPath"
$counts.GetEnumerator() | Sort-Object Key | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}
