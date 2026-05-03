#Requires -Version 5.1
<#
.SYNOPSIS
    Safely delete orphaned Volcengine resources with dry-run support.
.DESCRIPTION
    Reads orphaned-resources.json (from compare-tfstate.ps1) and deletes
    resources in dependency-safe order. Requires explicit confirmation
    unless -DryRun is used.
.PARAMETER OrphanedJsonPath
    Path to the orphaned resources JSON.
.PARAMETER DryRun
    If set, only prints what would be deleted without executing.
.PARAMETER VePath
    Path to the `ve` executable if not in PATH.
.PARAMETER RegionId
    Target region (default: cn-beijing).
.EXAMPLE
    .\cleanup.ps1 -OrphanedJsonPath ./orphaned-resources.json -DryRun
    .\cleanup.ps1 -OrphanedJsonPath ./orphaned-resources.json
#>
param(
    [Parameter(Mandatory)]
    [string]$OrphanedJsonPath,
    [switch]$DryRun,
    [string]$VePath = 've',
    [string]$RegionId = 'cn-beijing'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $OrphanedJsonPath)) {
    throw "File not found: $OrphanedJsonPath"
}

$orphans = Get-Content -Path $OrphanedJsonPath -Raw -Encoding UTF8 | ConvertFrom-Json -AsHashtable
if (-not $orphans) {
    Write-Host "No orphaned resources found."
    exit 0
}

# Flatten into a typed deletion queue with dependency ordering
$queue = [System.Collections.Generic.List[PSObject]]::new()

function Add-Queue($category, $id, $name, $deps, $deleteCmd) {
    $queue.Add([PSCustomObject]@{
        Category  = $category
        Id        = $id
        Name      = $name
        Deps      = $deps
        DeleteCmd = $deleteCmd
    })
}

# Deletion order: EIP -> CLB -> NAT -> ECS -> RDS -> Subnet -> SecurityGroup -> VPC -> KeyPair -> TOS
# (highest dependency first)

if ($orphans.EIP) {
    foreach ($r in $orphans.EIP) {
        $cmd = @{ service='eip'; action='ReleaseEipAddress'; args=@("--AllocationId", $r.AllocationId) }
        Add-Queue 'EIP' $r.AllocationId $r.EipAddress @() $cmd
    }
}
if ($orphans.CLB) {
    foreach ($r in $orphans.CLB) {
        $cmd = @{ service='clb'; action='DeleteLoadBalancer'; args=@("--LoadBalancerId", $r.LoadBalancerId) }
        Add-Queue 'CLB' $r.LoadBalancerId $r.LoadBalancerName @() $cmd
    }
}
if ($orphans.NAT) {
    foreach ($r in $orphans.NAT) {
        $cmd = @{ service='natgateway'; action='DeleteNatGateway'; args=@("--NatGatewayId", $r.NatGatewayId) }
        Add-Queue 'NAT' $r.NatGatewayId $r.NatGatewayName @() $cmd
    }
}
if ($orphans.ECS) {
    foreach ($r in $orphans.ECS) {
        # ECS needs stop before delete; we chain two commands via a wrapper
        $cmd = @{
            service = 'ecs'
            action  = 'DeleteInstances'
            pre     = @{ service='ecs'; action='StopInstances'; args=@("--InstanceIds","[`"$($r.InstanceId)`"]","--ForceStop","true") }
            args    = @("--InstanceIds","[`"$($r.InstanceId)`"]","--ForceDelete","true")
        }
        Add-Queue 'ECS' $r.InstanceId $r.InstanceName @() $cmd
    }
}
if ($orphans.RDS) {
    foreach ($r in $orphans.RDS) {
        $cmd = @{ service='rds_mysql'; action='DeleteDBInstance'; args=@("--InstanceId", $r.InstanceId) }
        Add-Queue 'RDS' $r.InstanceId $r.InstanceName @() $cmd
    }
}
if ($orphans.Subnets) {
    foreach ($r in $orphans.Subnets) {
        $cmd = @{ service='vpc'; action='DeleteSubnet'; args=@("--SubnetId", $r.SubnetId) }
        Add-Queue 'Subnet' $r.SubnetId $r.SubnetName @() $cmd
    }
}
if ($orphans.SecurityGroups) {
    foreach ($r in $orphans.SecurityGroups) {
        $cmd = @{ service='ecs'; action='DeleteSecurityGroup'; args=@("--SecurityGroupId", $r.SecurityGroupId) }
        Add-Queue 'SecurityGroup' $r.SecurityGroupId $r.SecurityGroupName @() $cmd
    }
}
if ($orphans.VPC) {
    foreach ($r in $orphans.VPC) {
        $cmd = @{ service='vpc'; action='DeleteVpc'; args=@("--VpcId", $r.VpcId) }
        Add-Queue 'VPC' $r.VpcId $r.VpcName @() $cmd
    }
}
if ($orphans.KeyPairs) {
    foreach ($r in $orphans.KeyPairs) {
        $cmd = @{ service='ecs'; action='DeleteKeyPairs'; args=@("--KeyPairNames","[`"$($r.KeyPairName)`"]") }
        Add-Queue 'KeyPair' $r.KeyPairName $r.KeyPairName @() $cmd
    }
}
if ($orphans.TOSBuckets) {
    foreach ($r in $orphans.TOSBuckets) {
        $cmd = @{ service='tos'; action='DeleteBucket'; args=@("--BucketName", $r.Name) }
        Add-Queue 'TOS' $r.Name $r.Name @() $cmd
    }
}

if ($queue.Count -eq 0) {
    Write-Host "No deletable orphaned resources found."
    exit 0
}

Write-Host "`nResources to delete (order: dependency-safe):"
$queue | Format-Table Category, Id, Name -AutoSize

if ($DryRun) {
    Write-Host "`n[DryRun] No resources were deleted. Remove -DryRun to execute."
    exit 0
}

$confirm = Read-Host "`nType 'yes' to delete the above resources"
if ($confirm -ne 'yes') {
    Write-Host "Aborted."
    exit 1
}

foreach ($item in $queue) {
    $cmd = $item.DeleteCmd
    if ($cmd.pre) {
        Write-Host "Stopping $($item.Category) $($item.Id) ..."
        $preArgs = @($cmd.pre.service, $cmd.pre.action, '--RegionId', $RegionId) + $cmd.pre.args
        & $VePath @preArgs 2>$null
        Start-Sleep -Seconds 5
    }
    Write-Host "Deleting $($item.Category) $($item.Id) ..."
    $args = @($cmd.service, $cmd.action, '--RegionId', $RegionId) + $cmd.args
    & $VePath @args 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  OK"
    } else {
        Write-Host "  FAILED (exit $LASTEXITCODE)"
    }
}

Write-Host "`nDone."
