<#
.SYNOPSIS
    System Integrity & Artifact Audit Script
.DESCRIPTION
    Checks for cleared Recycle Bins, Prefetch file wiping, ActivitiesCache status,
    and the runtime states of restrictable services.
#>

# Ensure running as Administrator for Prefetch and Service access
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Please re-run this script as an Administrator to query Prefetch and Service statuses."
    Exit
}

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "        SYSTEM ARTIFACT & SERVICE AUDIT             " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "Generated on: $(Get-Date)" -ForegroundColor Gray
Write-Host ""

# ----------------------------------------------------------------
# 1. RECYCLE BIN AUDIT
# ----------------------------------------------------------------
Write-Host "[+] Auditing Recycle Bin..." -ForegroundColor Yellow
$RecyclePath = "C:\`$Recycle.Bin"
$RecycleItems = Get-ChildItem -Path $RecyclePath -Recurse -Force -ErrorAction SilentlyContinue

$IFilesCount = ($RecycleItems | Where-Object { $_.Name -like "`$I*" }).Count
$RFilesCount = ($RecycleItems | Where-Object { $_.Name -like "`$R*" }).Count

Write-Host "  - Total tracking (\$I) files: $IFilesCount"
Write-Host "  - Total payload (\$R) files: $RFilesCount"

if ($IFilesCount -eq 0) {
    Write-Host "  - ALERT: Recycle Bin is completely empty or recently cleared." -ForegroundColor Red
} else {
    Write-Host "  - Status: Items present." -ForegroundColor Green
}
Write-Host ""

# ----------------------------------------------------------------
# 2. PREFETCH AUDIT
# ----------------------------------------------------------------
Write-Host "[+] Auditing Prefetch Directory..." -ForegroundColor Yellow
$PrefetchPath = "C:\Windows\Prefetch"

if (Test-Path $PrefetchPath) {
    $PrefetchFiles = Get-ChildItem -Path $PrefetchPath -Filter "*.pf" -ErrorAction SilentlyContinue
    $TotalPfCount = $PrefetchFiles.Count
    
    Write-Host "  - Total Prefetch (.pf) files found: $TotalPfCount"
    
    # Check for low count thresholds indicating a recent manual wipe
    if ($TotalPfCount -lt 30) {
        Write-Host "  - WARNING: Abnormally low prefetch count ($TotalPfCount). Prefetch may have been wiped." -ForegroundColor Red
    } else {
        Write-Host "  - Status: Pass (Standard prefetch volume metadata intact)." -ForegroundColor Green
    }
} else {
    Write-Host "  - CRITICAL: Prefetch folder is missing or inaccessible." -ForegroundColor Red
}
Write-Host ""

# ----------------------------------------------------------------
# 3. ACTIVITIES CACHE AUDIT
# ----------------------------------------------------------------
Write-Host "[+] Auditing Activities Cache (Windows Timeline)..." -ForegroundColor Yellow
$CDPPath = "$env:USERPROFILE\AppData\Local\ConnectedDevicesPlatform"
$ActivitiesDb = Get-ChildItem -Path $CDPPath -Filter "ActivitiesCache.db" -Recurse -ErrorAction SilentlyContinue

if ($ActivitiesDb) {
    foreach ($db in $ActivitiesDb) {
        $DbSizeKB = [math]::round($db.Length / 1KB, 2)
        Write-Host "  - Found: $($db.FullName)"
        Write-Host "  - Database Size: $DbSizeKB KB"
        
        if ($DbSizeKB -lt 30) {
            Write-Host "  - WARNING: ActivitiesCache.db size is extremely small ($DbSizeKB KB). It might have been cleared." -ForegroundColor Red
        } else {
            Write-Host "  - Status: Pass." -ForegroundColor Green
        }
    }
} else {
    Write-Host "  - CRITICAL: ActivitiesCache.db file could not be found! (Service disabled or history wiped)" -ForegroundColor Red
}
Write-Host ""

# ----------------------------------------------------------------
# 4. RESTRICTED SERVICES STATUS CHECK
# ----------------------------------------------------------------
Write-Host "[+] Auditing Critical Monitoring & Performance Services..." -ForegroundColor Yellow

# Array of services defined in your policy requirements
$CriticalServices = @(
    @{ Name = "SysMain";       Desc = "System performance monitoring" }
    @{ Name = "CDPUserSvc*";   Desc = "Connected Devices Platform" }
    @{ Name = "PcaSvc";         Desc = "Program Compatibility Assistant" }
    @{ Name = "DPS";            Desc = "Diagnostic Policy Service" }
    @{ Name = "EventLog";       Desc = "Event logging for system monitoring" }
    @{ Name = "Schedule";       Desc = "Task Scheduler" }
    @{ Name = "WSearch";        Desc = "Search indexing for file visibility (SearchIndexer)" }
    @{ Name = "bam";            Desc = "Background Activity Moderator" }
    @{ Name = "DusmSvc";        Desc = "Data Usage Service" }
    @{ Name = "Appinfo";        Desc = "Application Information Service" }
)

# Format structural layout
$FormatLayout = "{0,-15} | {1,-10} | {2,-10} | {3}"
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host [string]::Format($FormatLayout, "Service Name", "Status", "StartupType", "Description")
Write-Host "----------------------------------------------------------------------------" -ForegroundColor Gray

foreach ($Svc in $CriticalServices) {
    $ServiceInstance = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
    
    foreach ($Target in $ServiceInstance) {
        if ($Target) {
            $Status = $Target.Status
            $Startup = $Target.StartType
            
            # Highlight non-running services as potential infractions
            if ($Status -ne 'Running') {
                Write-Host [string]::Format($FormatLayout, $Target.Name, "STOPPED", $Startup, $Svc.Desc) -ForegroundColor Red
            } else {
                Write-Host [string]::Format($FormatLayout, $Target.Name, "Running", $Startup, $Svc.Desc) -ForegroundColor Green
            }
        }
    }
    
    if (-not $ServiceInstance) {
        Write-Host [string]::Format($FormatLayout, $Svc.Name, "MISSING", "N/A", ($Svc.Desc + " (Service not found/disabled)")) -ForegroundColor Red
    }
}

Write-Host "----------------------------------------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Audit completed successfully." -ForegroundColor Cyan
