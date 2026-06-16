# Targeted-ServiceChecker.ps1
Clear-Host

# Define the explicit list of important services from your list
$importantServices = @(
    "SysMain", "PcaSvc", "DPS", "EventLog", "Schedule", "WSearch", 
    "BAM", "DAM", "DusmSvc", "Appinfo", "DiagTrack", "DcomLaunch", 
    "RpcSs", "RpcEptMapper", "Winmgmt", "ProfSvc", "BFE", "MpsSvc", 
    "WpnService", "TimeBrokerSvc", "StateRepository", "AppXSvc", 
    "ClipSVC", "TokenBroker", "UserManager", "DeviceAssociationService", 
    "NlaSvc", "LanmanWorkstation", "LanmanServer", "Dhcp", "Dnscache", 
    "Wecsvc", "EventSystem", "CryptSvc", "PlugPlay", "Power", "Themes", 
    "ShellHWDetection", "SecurityHealthService", "WinDefend", "W32Time", 
    "UsoSvc", "wuauserv", "BITS", "SgrmBroker", "WdiServiceHost", "WdiSystemHost", "CDPSvc"
)

# Define regex patterns for user-specific per-session services (the ones ending in _*)
$perSessionPatterns = "^(CDPUserSvc|UdkUserSvc|ConsentUxUserSvc|CaptureService|cbdhsvc|OneSyncSvc|UnistoreSvc|MessagingService)_"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "         CRITICAL SERVICES & ARTIFACT SCANNER      " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Scanning prioritized system services...`n"

# Get all running/stopped services to filter against
$allServices = Get-Service
$foundCount = 0
$runningCount = 0

foreach ($service in $allServices) {
    # Check if it matches our explicit list OR the wildcard per-session pattern
    if ($importantServices -contains $service.Name -or $service.Name -match $perSessionPatterns) {
        $foundCount++
        
        if ($service.Status -eq 'Running') {
            $runningCount++
            Write-Host "[ RUNNING ] " -ForegroundColor Green -NoNewline
            Write-Host "$($service.Name) ($($service.DisplayName))"
        } else {
            Write-Host "[ STOPPED ] " -ForegroundColor Red -NoNewline
            Write-Host "$($service.Name) ($($service.DisplayName))" -ForegroundColor DarkGray
        }
    }
}

# Forensic Artifact Check Section
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "          FORENSIC ARTIFACT LOCATIONS             " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Checking availability of key activity databases...`n"

$artifacts = @{
    "Prefetch (.pf files)"     = "$env:SystemRoot\Prefetch"
    "Recent Files History"     = "$env:APPDATA\Microsoft\Windows\Recent"
    "Jump Lists"               = "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations"
    "SRUM Database"            = "$env:SystemRoot\System32\sru\SRUDB.dat"
    "ActivitiesCache (Timeline)"= "$env:USERPROFILE\AppData\Local\ConnectedDevicesPlatform"
}

foreach ($artifact in $artifacts.GetEnumerator()) {
    if (Test-Path $artifact.Value) {
        Write-Host "[ AVAILABLE ] " -ForegroundColor Green -NoNewline
        Write-Host $artifact.Key
    } else {
        Write-Host "[ NOT FOUND ] " -ForegroundColor Yellow -NoNewline
        Write-Host "$($artifact.Key) (Requires Admin/Custom Path)" -ForegroundColor DarkGray
    }
}

# Final Summary
$stoppedCount = $foundCount - $runningCount
Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "                SCANNER SUMMARY                   " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " Core Services Tracked: " -NoNewline; Write-Host $foundCount -ForegroundColor Cyan
Write-Host " Running:               " -NoNewline; Write-Host $runningCount -ForegroundColor Green
Write-Host " Stopped:               " -NoNewline; Write-Host $stoppedCount -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor Cyan
