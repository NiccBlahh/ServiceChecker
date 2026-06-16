# Targeted-Color-ServiceChecker.ps1
Clear-Host

# Group 1: Specific high-priority services to flag with a distinct color (Yellow/Orange Alert)
$priorityAlertServices = @(
    "SysMain", "PcaSvc", "DPS", "EventLog", "Schedule", 
    "WSearch", "BAM", "DAM", "DusmSvc", "Appinfo", "CDPSvc"
)

# Per-session priority patterns (e.g., CDPUserSvc_661a8)
$prioritySessionPatterns = "^(CDPUserSvc)_"

# Group 2: Other critical infrastructure services from your list (Standard Cyan Blue/Gray handling)
$standardCriticalServices = @(
    "DcomLaunch", "RpcSs", "RpcEptMapper", "Winmgmt", "ProfSvc", "BFE", "MpsSvc", 
    "WpnService", "TimeBrokerSvc", "StateRepository", "AppXSvc", "ClipSVC", "TokenBroker", 
    "UserManager", "DeviceAssociationService", "NlaSvc", "LanmanWorkstation", "LanmanServer", 
    "Dhcp", "Dnscache", "Wecsvc", "EventSystem", "CryptSvc", "PlugPlay", "Power", "Themes", 
    "ShellHWDetection", "SecurityHealthService", "WinDefend", "W32Time", "UsoSvc", "wuauserv", 
    "BITS", "SgrmBroker", "WdiServiceHost", "WdiSystemHost", "DiagTrack"
)

# Standard per-session patterns
$standardSessionPatterns = "^(ConsentUxUserSvc|CaptureService|cbdhsvc|OneSyncSvc|UnistoreSvc|MessagingService|UdkUserSvc)_"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "             SYSTEM COMPLIANCE & SERVICE SCANNER                     " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Scanning services... (Yellow = Priority Monitored / Green-Red = Standard)`n"

$allServices = Get-Service

foreach ($service in $allServices) {
    # 1. Check Priority Alert Services First
    if ($priorityAlertServices -contains $service.Name -or $service.Name -match $prioritySessionPatterns) {
        if ($service.Status -eq 'Running') {
            Write-Host "[ PRIORITY RUNNING ] " -ForegroundColor Yellow -NoNewline
            Write-Host "$($service.Name) ($($service.DisplayName))"
        } else {
            Write-Host "[ PRIORITY STOPPED ] " -ForegroundColor DarkYellow -NoNewline
            Write-Host "$($service.Name) ($($service.DisplayName))" -ForegroundColor Gray
        }
    }
    # 2. Check Standard Critical Services
    elseif ($standardCriticalServices -contains $service.Name -or $service.Name -match $standardSessionPatterns) {
        if ($service.Status -eq 'Running') {
            Write-Host "[ RUNNING ]          " -ForegroundColor Green -NoNewline
            Write-Host "$($service.Name) ($($service.DisplayName))"
        } else {
            Write-Host "[ STOPPED ]          " -ForegroundColor Red -NoNewline
            Write-Host "$($service.Name) ($($service.DisplayName))" -ForegroundColor DarkGray
        }
    }
}

# Forensic Activity Tracker Section (BAM/ActivitiesCache/JumpLists restriction checks)
Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "             ACTIVITY TRACKING & FORENSIC ARTIFACTS                  " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Checking activity cache tracking and history compliance...`n"

$artifacts = @{
    "ActivitiesCache (Timeline Database)" = "$env:USERPROFILE\AppData\Local\ConnectedDevicesPlatform"
    "Jump Lists (Recent Actions Cache)"   = "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations"
    "Prefetch Tracking (.pf files)"       = "$env:SystemRoot\Prefetch"
    "Recent Files History Logs"           = "$env:APPDATA\Microsoft\Windows\Recent"
    "SRUM System Resource Database"       = "$env:SystemRoot\System32\sru\SRUDB.dat"
}

foreach ($artifact in $artifacts.GetEnumerator()) {
    if (Test-Path $artifact.Value) {
        Write-Host "[ ACTIVE / PRESENT ] " -ForegroundColor Green -NoNewline
        Write-Host $artifact.Key
    } else {
        # Highlighting missing/disabled tracking artifacts in Red since they represent restrictive offenses
        Write-Host "[ HIDDEN / DISABLED ] " -ForegroundColor Red -NoNewline
        Write-Host "$($artifact.Key) (Potential Compliance Offense)" -ForegroundColor DarkGray
    }
}

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "Scan Complete." -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
