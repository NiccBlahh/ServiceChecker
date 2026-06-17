<#
.SYNOPSIS
    Retro CLI Windows System Diagnostic Tool
.DESCRIPTION
    Consolidates advanced registry policies, live service states (including DiagTrack), 
    prefetch analytics, event logs, and an advanced Recycle Bin breakdown.
.NOTES
    Must be executed with elevated Administrator privileges.
#>

Clear-Host

# Force load the ServiceProcess assembly right at the start to prevent TypeNotFound errors
try {
    Add-Type -AssemblyName "System.ServiceProcess" -ErrorAction SilentlyContinue
} catch {}

# --- Admin Privilege Enforcement ---
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
$isAdmin = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "`n╔══════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║           ADMINISTRATOR PRIVILEGES REQUIRED       ║" -ForegroundColor Red
    Write-Host "║     Please run this script as Administrator!      ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════╝" -ForegroundColor Red
    exit
}

# --- Helper Functions for Formatting ---
function Write-Header {
    Write-Host ' _____                _             _____ _                _             ' -ForegroundColor Cyan
    Write-Host '/  ___|              (_)           /  __ \ |              | |            ' -ForegroundColor Cyan
    Write-Host '\ `--.  ___ _ ____   ___  ___ ___  | /  \/ |__   ___  ___| | _____ _ __ ' -ForegroundColor Cyan
    Write-Host ' `--. \/ _ \ __\ \ / / |/ __/ _ \ | |   | _ \ / _ \/ __| |/ / _ \ __|' -ForegroundColor Cyan
    Write-Host '/\__/ /  __/ |   \ V /| | (_|  __/ | \__/\ | | |  __/ (__|   <  __/ |   ' -ForegroundColor Cyan
    Write-Host '\____/ \___|_|    \_/ |_|\___\___|  \____/_| |_|\___|\___|_|\_\___|_|   ' -ForegroundColor Cyan
    Write-Host ""
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "  ■ $Title" -ForegroundColor Magenta
}

function Write-Item {
    param([string]$Label, [string]$Value, [string]$ValueColor = "White")
    $PadLabel = "    $Label".PadRight(35)
    Write-Host $PadLabel -ForegroundColor Gray -NoNewline
    Write-Host " : " -ForegroundColor DarkGray -NoNewline
    Write-Host $Value -ForegroundColor $ValueColor
}

function Write-SvcRow {
    param([string]$Svc, [string]$Desc, [string]$Status)
    $SvcPad = "    $Svc".PadRight(20)
    $DescPad = $Desc.PadRight(40)
    $Color = if ($Status -eq "Running" -or $Status -eq "Enabled") { "Cyan" } else { "Red" }
    Write-Host $SvcPad -ForegroundColor DarkGreen -NoNewline
    Write-Host "    " -NoNewline
    Write-Host $DescPad -ForegroundColor White -NoNewline
    Write-Host "    " -NoNewline
    Write-Host $Status -ForegroundColor $Color
}

function Write-Alert {
    param([string]$Message)
    Write-Host "     [!] $Message" -ForegroundColor Red
}

function Check-EventLog {
    param ($logName, $eventID, $message)
    $event = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$eventID]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($event) {
        return "$message at: $($event.TimeCreated.ToString('MM/dd HH:mm'))"
    } else {
        return "$message - No records found"
    }
}

function Check-RecentEventLog {
    param ($logName, $eventIDs, $message)
    $event = Get-WinEvent -LogName $logName -FilterXPath "*[System[EventID=$($eventIDs -join ' or EventID=')]]" -MaxEvents 1 -ErrorAction SilentlyContinue
    if ($event) {
        return "$message (ID: $($event.Id)) at: $($event.TimeCreated.ToString('MM/dd HH:mm'))"
    } else {
        return "$message - No records found"
    }
}

$ScriptErrors = @()

# =============================================================================
# DATA QUERIES
# =============================================================================
try {
    # System Boot Time
    $BootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $Uptime = (Get-Date) - $BootTime
    $UptimeStr = "{0} days, {1:d2}:{2:d2}:{3:d2}" -f $Uptime.Days, $Uptime.Hours, $Uptime.Minutes, $Uptime.Seconds

    # Hardware Performance
    $CpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $Mem = Get-CimInstance Win32_OperatingSystem
    $TotalMem = [math]::round($Mem.TotalVisibleMemorySize / 1MB, 1)
    $FreeMem = [math]::round($Mem.FreePhysicalMemory / 1MB, 1)
    $UsedMem = [math]::round($TotalMem - $FreeMem, 1)
    $MemPercent = [math]::round(($UsedMem / $TotalMem) * 100, 0)
    $MemStr = "$UsedMem GB / $TotalMem GB ($MemPercent)%"

    # Core System Service Assembly
    try {
        $AllSystemServices = [System.ServiceProcess.ServiceController]::GetServices()
    } catch {
        $AllSystemServices = Get-CimInstance Win32_Service | Select-Object @{N="ServiceName";E={$_.Name}}, @{N="Status";E={if($_.State -eq "Running"){"Running"}else{"Stopped"}}}
    }

    # Dynamic Scoped Name for Wildcard Services (e.g. CDPUserSvc_xxxxx)
    $CdpUserRealName = ($AllSystemServices | Where-Object { $_.ServiceName -like "CDPUserSvc_*" } | Select-Object -First 1).ServiceName
    if (-not $CdpUserRealName) { $CdpUserRealName = "CDPUserSvc" }

} catch {
    $ScriptErrors += $_.Exception.Message
}

# =============================================================================
# ENGINE RENDERING
# =============================================================================
Write-Header

# SECTION: SYSTEM BOOT TIME
Write-Section -Title "SYSTEM BOOT TIME"
if ($BootTime) {
    Write-Item -Label "Last Boot Time" -Value $BootTime.ToString("yyyy-MM-dd HH:mm:ss") -ValueColor "Cyan"
    Write-Item -Label "System Uptime" -Value $UptimeStr -ValueColor "Cyan"
} else {
    Write-Alert -Message "Failed to fetch operational uptime properties."
}

# SECTION: HARDWARE UTILIZATION
Write-Section -Title "HARDWARE UTILIZATION"
Write-Item -Label "CPU Load" -Value "$CpuLoad % Active" -ValueColor "Yellow"
$memStr = "$($UsedMem) GB / $($TotalMem) GB ($($MemPercent))%"
Write-Item -Label "Memory Usage" -Value $memStr -ValueColor "White"

# SECTION: CONNECTED DRIVES
Write-Section -Title "CONNECTED DRIVES and LOGICAL VOLUMES"
try {
    $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -ne 5 }
    foreach ($drive in $drives) {
        $FreeGB = [math]::round($drive.FreeSpace / 1GB, 1)
        $SizeGB = [math]::round($drive.Size / 1GB, 1)
        if ($SizeGB -gt 0) {
            $volStr = "$($drive.FileSystem) - $($FreeGB) GB Free / $($SizeGB) GB Total"
            Write-Item -Label "Volume [$($drive.DeviceID)]" -Value $volStr -ValueColor "Green"
        }
    }
} catch { $ScriptErrors += "Drive parsing framework error" }

# SECTION: SERVICE MONITORING
Write-Section -Title "SERVICE STATUS and CORE MONITORING"
$TargetServices = @(
    @{Name="SysMain"; Desc="System Performance/SysMain Monitoring"}
    @{Name=$CdpUserRealName; Desc="Connected Devices Platform"}
    @{Name="PcaSvc"; Desc="Program Compatibility Assistant"}
    @{Name="DPS"; Desc="Diagnostic Policy Service"}
    @{Name="EventLog"; Desc="Event Logging System Monitor"}
    @{Name="Schedule"; Desc="Task Scheduler Engine"}
    @{Name="wsearch"; Desc="Windows Search Indexer"}
    @{Name="Bam"; Desc="Background Activity Moderator"}
    @{Name="Dusmsvc"; Desc="Data Usage Service Monitor"}
    @{Name="Appinfo"; Desc="Application Information Service"}
    @{Name="DcomLaunch"; Desc="DCOM Server Process Launcher"}
    @{Name="PlugPlay"; Desc="Plug and Play Engine"}
    @{Name="DiagTrack"; Desc="Telemetry / Diagnostic Tracking Service"}
)

foreach ($Svc in $TargetServices) {
    try {
        if ($Svc.Name -eq "Bam") {
            $BamRegistry = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\bam" -Name Start -ErrorAction SilentlyContinue
            $Status = if ($null -ne $BamRegistry -and ($BamRegistry.Start -eq 2 -or $BamRegistry.Start -eq 3)) { "Running" } else { "Stopped" }
        } else {
            $RealSvc = $AllSystemServices | Where-Object { $_.ServiceName -eq $Svc.Name }
            $Status = if ($null -ne $RealSvc) { $RealSvc.Status.ToString() } else { "Missing" }
        }
    } catch {
        $Status = "Query Error"
    }
    
    $DisplayName = $Svc.Name
    if ($Svc.Name -eq "Schedule") { $DisplayName = "Scheduler" }
    if ($Svc.Name -eq "wsearch") { $DisplayName = "SearchIndexer" }
    
    Write-SvcRow -Svc $DisplayName -Desc $Svc.Desc -Status $Status
}

# SECTION: REGISTRY POLICIES
Write-Section -Title "REGISTRY POLICY AUDIT"
try {
    $settings = @(
        @{ Name = "CMD Execution Rules"; Path = "HKCU:\Software\Policies\Microsoft\Windows\System"; Key = "DisableCMD"; Target = 0; Warn = "Restricted"; Safe = "Available" },
        @{ Name = "PowerShell Logging"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"; Key = "EnableScriptBlockLogging"; Target = 1; Warn = "Disabled"; Safe = "Logging Enabled" },
        @{ Name = "Activities Cache Feed"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"; Key = "EnableActivityFeed"; Target = 1; Warn = "Feed Blocked"; Safe = "Tracking Enabled" },
        @{ Name = "Prefetch Driver Status"; Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"; Key = "EnablePrefetcher"; Target = 3; Warn = "Modified/Disabled"; Safe = "Enabled (Optimal)" }
    )

    foreach ($s in $settings) {
        $status = Get-ItemProperty -Path $s.Path -Name $s.Key -ErrorAction SilentlyContinue
        if ($status -and $status.$($s.Key) -ne $s.Target) {
            Write-Item -Label $s.Name -Value $s.Warn -ValueColor "Red"
        } else {
            Write-Item -Label $s.Name -Value $s.Safe -ValueColor "Green"
        }
    }
} catch { $ScriptErrors += "Registry schema tracking mapping exception" }

# SECTION: EVENT LOG INTEGRITY
Write-Section -Title "CRITICAL EVENT LOG AUDIT"
try {
    Write-Item -Label "USN Journal Clearance" -Value (Check-EventLog "Application" 3079 "USN Modification Event") -ValueColor "Yellow"
    Write-Item -Label "Windows Log Pipelines" -Value (Check-RecentEventLog "System" @(104, 1102) "Clear Events Log Action") -ValueColor "Yellow"
    Write-Item -Label "Last Recorded Shutdown" -Value (Check-EventLog "System" 1074 "Hardware Stop Command") -ValueColor "Cyan"
    Write-Item -Label "System Time Integrity" -Value (Check-EventLog "Security" 4616 "Time Change Action") -ValueColor "White"
    Write-Item -Label "Service Initialization" -Value (Check-EventLog "System" 6005 "Event Log Upstream Start") -ValueColor "Green"
} catch { $ScriptErrors += "Event Subsystem logs inaccessible" }

# SECTION: PREFETCH ANALYTICS
Write-Section -Title "PREFETCH IMAGE INTEGRITY"
$prefetchPath = "$env:SystemRoot\Prefetch"
if (Test-Path $prefetchPath) {
    try {
        $files = Get-ChildItem -Path $prefetchPath -Filter *.pf -Force -ErrorAction SilentlyContinue
        if (-not $files) {
            Write-Alert -Message "Prefetch catalog contains zero references."
        } else {
            $hiddenFiles = $files | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::Hidden }
            $readOnlyFiles = $files | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReadOnly }
            
            $HiddenValue = if ($hiddenFiles.Count -gt 0) { "$($hiddenFiles.Count) Anomaly Items Detected" } else { "Clean" }
            $HiddenColor = if ($hiddenFiles.Count -gt 0) { "Red" } else { "Green" }
            
            Write-Item -Label "Total Logged Hashes" -Value "$($files.Count) File Objects" -ValueColor "Cyan"
            Write-Item -Label "Hidden Modifications" -Value $HiddenValue -ValueColor $HiddenColor
            Write-Item -Label "Read-Only Locking Status" -Value "$($readOnlyFiles.Count) Flagged Files" -ValueColor "White"
        }
    } catch { $ScriptErrors += "Prefetch catalog access violation exception" }
} else {
    Write-Alert -Message "System Prefetch directory could not be resolved."
}

# SECTION: RECYCLE BIN
Write-Section -Title "STORAGE RECYCLE REPOSITORY"
try {
    $recycleBinPath = $env:SystemDrive + '\$Recycle.Bin'
    if (Test-Path $recycleBinPath) {
        $userFolders = Get-ChildItem -LiteralPath $recycleBinPath -Directory -Force -ErrorAction SilentlyContinue
        $folderCount = 0
        
        $allDeletedItems = @()
        $latestModTime = [DateTime]::MinValue
        
        if ($userFolders) {
            foreach ($uf in $userFolders) {
                if ($uf.LastWriteTime -gt $latestModTime) { $latestModTime = $uf.LastWriteTime }
                $folderCount++
                
                $userItems = Get-ChildItem -LiteralPath $uf.FullName -File -Force -ErrorAction SilentlyContinue
                if ($userItems) {
                    $allDeletedItems += $userItems
                    $latestFile = $userItems | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                    if ($latestFile -and $latestFile.LastWriteTime -gt $latestModTime) {
                        $latestModTime = $latestFile.LastWriteTime
                    }
                }
            }
        }
        
        $totalItemsCount = $allDeletedItems.Count
        if ($totalItemsCount -gt 0) {
            $formattedTime = $latestModTime.ToString("yyyy-MM-dd HH:mm:ss")
            Write-Item -Label "Total Objects Cached" -Value "$totalItemsCount Items Pending" -ValueColor "Yellow"
            Write-Item -Label "Last Modified Directory Time" -Value $formattedTime -ValueColor "Yellow"
        } else {
            Write-Item -Label "Recycle Bin" -Value "$folderCount user folder(s) found, 0 deleted items" -ValueColor "Green"
        }
    } else {
        Write-Alert -Message "Recycle Bin storage structure was missing or unreadable."
    }
} catch { $ScriptErrors += "Recycle Bin Object structural query failed" }

# SECTION: CONSOLE HISTORY
Write-Section -Title "CONSOLE SYSTEM ENVIRONMENT HISTORY"
$consoleHistoryPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
if (Test-Path $consoleHistoryPath) {
    $historyFile = Get-Item -Path $consoleHistoryPath -Force
    $fileSize = [math]::Round($historyFile.Length / 1KB, 2)
    $histStr = "Tracking Connected $fileSize KB"
    Write-Item -Label "PSReadline History Ledger" -Value $histStr -ValueColor "Green"
    Write-Item -Label "Ledger Last Mutation Time" -Value $historyFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") -ValueColor "Yellow"
} else {
    Write-Item -Label "PSReadline History Ledger" -Value "Inoperable or Not Used" -ValueColor "Gray"
}

# --- System Validation Complete & Support Routing ---
Write-Host ""
Write-Host "  System diagnostics complete." -ForegroundColor Cyan
Write-Host ""

Write-Host " ┌────────────────────────────────────────────────────────┐" -ForegroundColor Red
Write-Host '   Reach out to support @imnicc.dll for any errors!. <3  ' -ForegroundColor Yellow
Write-Host " └────────────────────────────────────────────────────────┘" -ForegroundColor Red

if ($ScriptErrors.Count -gt 0) {
    Write-Host "`n  Muted Engine Exceptions:" -ForegroundColor DarkGray
    foreach ($Err in $ScriptErrors) {
        Write-Host "    -> $Err" -ForegroundColor DarkGray
    }
    Write-Host ""
}
