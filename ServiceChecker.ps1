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

try { Add-Type -AssemblyName "System.ServiceProcess" -ErrorAction SilentlyContinue } catch {}

$identity  = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [System.Security.Principal.WindowsPrincipal]::new($identity)
$isAdmin   = $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  ADMINISTRATOR PRIVILEGES REQUIRED" -ForegroundColor Red
    Write-Host "  Please run this script as Administrator!" -ForegroundColor Red
    exit
}

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

function Write-Header {
    $ts = Get-Date -Format 'yyyy-MM-dd  HH:mm:ss'
    Write-Host ''
    Write-Host '   _____                 _              ________              __            ' -ForegroundColor Cyan
    Write-Host '  / ___/___  ______   __(_)_______     / ____/ /_  ___  _____/ /_____  _____' -ForegroundColor Cyan
    Write-Host '  \__ \/ _ \/ ___/ | / / / ___/ _ \   / /   / __ \/ _ \/ ___/ //_/ _ \/ ___/' -ForegroundColor Cyan
    Write-Host ' ___/ /  __/ /   | |/ / / /__/  __/  / /___/ / / /  __/ /__/ ,< /  __/ /    ' -ForegroundColor DarkCyan
    Write-Host '/____/\___/_/    |___/_/\___/\___/   \____/_/ /_/\___/\___/_/|_|\___/_/     ' -ForegroundColor DarkCyan
    Write-Host '                                                                            ' -ForegroundColor DarkCyan
    Write-Host '  >> ' -ForegroundColor Magenta -NoNewline
    Write-Host '@imnicc.dll ' -ForegroundColor Cyan -NoNewline
    Write-Host ':: ' -ForegroundColor DarkGray -NoNewline
    Write-Host "[$ts] " -ForegroundColor DarkCyan -NoNewline
    Write-Host '<<' -ForegroundColor Magenta
    Write-Host ''
}

function Write-Section {
    param([string]$Title)
    Write-Host ''
    Write-Host "  $([char]0x25A0) $Title" -ForegroundColor Magenta
}

function Write-Item {
    param([string]$Label, [string]$Value, [string]$ValueColor = 'White')
    $pad = ("    " + $Label).PadRight(35)
    Write-Host $pad -ForegroundColor Gray -NoNewline
    Write-Host ' : ' -ForegroundColor DarkGray -NoNewline
    Write-Host $Value -ForegroundColor $ValueColor
}

function Write-SvcRow {
    param([string]$Svc, [string]$Desc, [string]$Status, [string]$OverrideColor = '')
    $svcPad  = ("    " + $Svc).PadRight(20)
    $descPad = $Desc.PadRight(40)
    $color   = if ($OverrideColor) { $OverrideColor }
               elseif ($Status -eq 'Running') { 'Green' }
               elseif ($Status -eq 'Stopped') { 'Red' }
               else { 'Yellow' }
    Write-Host $svcPad  -ForegroundColor Cyan -NoNewline
    Write-Host '    '   -NoNewline
    Write-Host $descPad -ForegroundColor Gray -NoNewline
    Write-Host '    '   -NoNewline
    Write-Host $Status  -ForegroundColor $color
}

function Write-Alert {
    param([string]$Message)
    Write-Host "     [!] $Message" -ForegroundColor Red
}

function Check-EventLog {
    param([string]$LogName, [int]$EventID, [string]$Message)
    try {
        $ev = Get-WinEvent -LogName $LogName -FilterXPath "*[System[EventID=$EventID]]" -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($ev) { return "$Message at: $($ev.TimeCreated.ToString('MM/dd HH:mm'))" }
        else      { return "$Message - No records found" }
    } catch { return "$Message - Log inaccessible" }
}

function Check-RecentEventLog {
    param([string]$LogName, [int[]]$EventIDs, [string]$Message)
    try {
        $parts = $EventIDs | ForEach-Object { "EventID=$_" }
        $xpath = "*[System[($($parts -join ' or '))]]"
        $ev = Get-WinEvent -LogName $LogName -FilterXPath $xpath -MaxEvents 1 -ErrorAction SilentlyContinue
        if ($ev) { return "$Message (ID: $($ev.Id)) at: $($ev.TimeCreated.ToString('MM/dd HH:mm'))" }
        else      { return "$Message - No records found" }
    } catch { return "$Message - Log inaccessible" }
}

$ScriptErrors = @()

# ==============================================================================
# DATA QUERIES — safe defaults declared first so rendering never sees undef vars
# ==============================================================================
$BootTime          = $null
$UptimeStr         = 'Unavailable'
$CpuLoad           = 'N/A'
$TotalMem          = 0
$FreeMem           = 0
$UsedMem           = 0
$MemPercent        = 0
$AllSystemServices = @()
$CdpUserRealName   = 'CDPUserSvc'

try {
    $BootTime   = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $Uptime     = (Get-Date) - $BootTime
    $UptimeStr  = '{0} days, {1:d2}:{2:d2}:{3:d2}' -f $Uptime.Days, $Uptime.Hours, $Uptime.Minutes, $Uptime.Seconds

    $CpuLoad    = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $Mem        = Get-CimInstance Win32_OperatingSystem
    $TotalMem   = [math]::Round($Mem.TotalVisibleMemorySize / 1MB, 1)
    $FreeMem    = [math]::Round($Mem.FreePhysicalMemory     / 1MB, 1)
    $UsedMem    = [math]::Round($TotalMem - $FreeMem, 1)
    $MemPercent = [math]::Round(($UsedMem / $TotalMem) * 100, 0)

    try {
        $AllSystemServices = [System.ServiceProcess.ServiceController]::GetServices()
    } catch {
        $AllSystemServices = Get-CimInstance Win32_Service | Select-Object `
            @{N='ServiceName'; E={$_.Name}},
            @{N='Status';      E={if ($_.State -eq 'Running') {'Running'} else {'Stopped'}}}
    }

    $cdpMatch = $AllSystemServices | Where-Object { $_.ServiceName -like 'CDPUserSvc_*' } | Select-Object -First 1
    if ($cdpMatch) { $CdpUserRealName = $cdpMatch.ServiceName }

} catch {
    $ScriptErrors += "System data query failed: $($_.Exception.Message)"
}

# ==============================================================================
# RENDERING
# ==============================================================================
Write-Header

# ---- BOOT TIME ----
Write-Section -Title 'SYSTEM BOOT TIME'
if ($BootTime) {
    Write-Item -Label 'Last Boot Time' -Value $BootTime.ToString('yyyy-MM-dd HH:mm:ss') -ValueColor 'Cyan'
    Write-Item -Label 'System Uptime'  -Value $UptimeStr                                -ValueColor 'Cyan'
} else {
    Write-Alert -Message 'Failed to fetch operational uptime properties.'
    Write-Item  -Label 'System Uptime'  -Value $UptimeStr -ValueColor 'DarkGray'
}

# ---- HARDWARE ----
Write-Section -Title 'HARDWARE UTILIZATION'
Write-Item -Label 'CPU Load'     -Value "$CpuLoad % Active"                    -ValueColor 'Yellow'
Write-Item -Label 'Memory Usage' -Value "$UsedMem GB / $TotalMem GB ($MemPercent)%" -ValueColor 'White'

# ---- DRIVES ----
Write-Section -Title 'CONNECTED DRIVES and LOGICAL VOLUMES'
try {
    $drives = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -ne 5 }
    foreach ($d in $drives) {
        $freeGB = [math]::Round($d.FreeSpace / 1GB, 1)
        $sizeGB = [math]::Round($d.Size       / 1GB, 1)
        if ($sizeGB -gt 0) {
            Write-Item -Label "Volume [$($d.DeviceID)]" `
                       -Value "$($d.FileSystem) - $freeGB GB Free / $sizeGB GB Total" `
                       -ValueColor 'Green'
        }
    }
} catch { $ScriptErrors += "Drive parsing error: $($_.Exception.Message)" }

# ---- SERVICES ----
Write-Section -Title 'SERVICE STATUS and CORE MONITORING'

$TargetServices = @(
    @{ Name = 'SysMain';        Desc = 'System Performance/SysMain Monitoring'    }
    @{ Name = $CdpUserRealName; Desc = 'Connected Devices Platform'               }
    @{ Name = 'PcaSvc';         Desc = 'Program Compatibility Assistant'          }
    @{ Name = 'DPS';            Desc = 'Diagnostic Policy Service'                }
    @{ Name = 'EventLog';       Desc = 'Event Logging System Monitor'             }
    @{ Name = 'Schedule';       Desc = 'Task Scheduler Engine'                    }
    @{ Name = 'wsearch';        Desc = 'Windows Search Indexer'                   }
    @{ Name = 'Bam';            Desc = 'Background Activity Moderator'            }
    @{ Name = 'Dusmsvc';        Desc = 'Data Usage Service Monitor'               }
    @{ Name = 'Appinfo';        Desc = 'Application Information Service'          }
    @{ Name = 'DcomLaunch';     Desc = 'DCOM Server Process Launcher'             }
    @{ Name = 'PlugPlay';       Desc = 'Plug and Play Engine'                     }
    @{ Name = 'DiagTrack';      Desc = 'Telemetry / Diagnostic Tracking Service'  }
)

foreach ($svc in $TargetServices) {
    try {
        if ($svc.Name -eq 'Bam') {
            # BAM is a kernel driver — Win32_SystemDriver gives the real runtime State.
            $bamDrv = Get-CimInstance Win32_SystemDriver -Filter "Name='bam'" -ErrorAction SilentlyContinue
            $status = if ($null -ne $bamDrv) { $bamDrv.State } else { 'Missing' }
        } else {
            # Use Get-Service directly for a fresh live query instead of the cached array.
            $liveSvc = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
            $status  = if ($null -ne $liveSvc) { $liveSvc.Status.ToString() } else { 'Missing' }
        }
    } catch { $status = 'Query Error' }

    $displayName = switch ($svc.Name) {
        'Schedule' { 'Scheduler'     }
        'wsearch'  { 'SearchIndexer' }
        default    { $svc.Name       }
    }

    # DiagTrack is often intentionally disabled for privacy — show neutral color when stopped.
    $rowColor = if ($svc.Name -eq 'DiagTrack' -and $status -eq 'Stopped') { 'DarkGray' } else { '' }
    Write-SvcRow -Svc $displayName -Desc $svc.Desc -Status $status -OverrideColor $rowColor
}

# ---- REGISTRY POLICIES ----
Write-Section -Title 'REGISTRY POLICY AUDIT'
try {
    $regChecks = @(
        @{ Name='CMD Execution Rules';    Path='HKCU:\Software\Policies\Microsoft\Windows\System';                                             Key='DisableCMD';              Target=0; Warn='Restricted';      Safe='Available'       }
        @{ Name='PowerShell Logging';     Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging';                      Key='EnableScriptBlockLogging'; Target=1; Warn='Disabled';        Safe='Logging Enabled'  }
        @{ Name='Activities Cache Feed';  Path='HKLM:\SOFTWARE\Policies\Microsoft\Windows\System';                                             Key='EnableActivityFeed';       Target=1; Warn='Feed Blocked';    Safe='Tracking Enabled' }
        @{ Name='Prefetch Driver Status'; Path='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters';  Key='EnablePrefetcher';         Target=3; Warn='Modified/Disabled'; Safe='Enabled (Optimal)'}
    )
    foreach ($r in $regChecks) {
        $val = Get-ItemProperty -Path $r.Path -Name $r.Key -ErrorAction SilentlyContinue
        if ($val -and $val.($r.Key) -ne $r.Target) {
            Write-Item -Label $r.Name -Value $r.Warn -ValueColor 'Red'
        } else {
            Write-Item -Label $r.Name -Value $r.Safe -ValueColor 'Green'
        }
    }
} catch { $ScriptErrors += "Registry audit exception: $($_.Exception.Message)" }

# ---- EVENT LOGS ----
# FIX: Color logic is now inverted for tamper-detection events:
#   No records found = Green (clean — nothing suspicious detected)
#   Records found    = Red   (alert — this event indicates potential tampering)
Write-Section -Title 'CRITICAL EVENT LOG AUDIT'

$usnResult  = Check-EventLog       'Application' 3079       'USN Modification Event'
$logResult  = Check-RecentEventLog 'System'      @(104,1102) 'Clear Events Log Action'
$sdnResult  = Check-EventLog       'System'      1074        'Hardware Stop Command'
$timeResult = Check-EventLog       'Security'    4616        'Time Change Action'
$svcResult  = Check-EventLog       'System'      6005        'Event Log Upstream Start'

# Pre-compute colors — PowerShell does not allow inline if-expressions as function arguments
$usnColor  = if ($usnResult  -match 'No records|inaccessible') { 'Green' } else { 'Red'    }
$logColor  = if ($logResult  -match 'No records|inaccessible') { 'Green' } else { 'Red'    }
$sdnColor  = if ($sdnResult  -match 'No records|inaccessible') { 'Gray'  } else { 'Cyan'   }
$timeColor = if ($timeResult -match 'No records|inaccessible') { 'Green' } else { 'Yellow' }
$svcColor  = if ($svcResult  -match 'No records|inaccessible') { 'Gray'  } else { 'Green'  }

Write-Item -Label 'USN Journal Clearance'  -Value $usnResult  -ValueColor $usnColor
Write-Item -Label 'Windows Log Pipelines'  -Value $logResult  -ValueColor $logColor
Write-Item -Label 'Last Recorded Shutdown' -Value $sdnResult  -ValueColor $sdnColor
Write-Item -Label 'System Time Integrity'  -Value $timeResult -ValueColor $timeColor
Write-Item -Label 'Service Initialization' -Value $svcResult  -ValueColor $svcColor

# ---- PREFETCH ----
Write-Section -Title 'PREFETCH IMAGE INTEGRITY'
$pfPath = "$env:SystemRoot\Prefetch"
if (Test-Path $pfPath) {
    try {
        $pfFiles = Get-ChildItem -Path $pfPath -Filter '*.pf' -Force -ErrorAction SilentlyContinue
        if (-not $pfFiles -or $pfFiles.Count -eq 0) {
            Write-Alert -Message 'Prefetch catalog contains zero references.'
        } else {
            $hidden   = @($pfFiles | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::Hidden })
            $readOnly = @($pfFiles | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::ReadOnly })
            $hVal     = if ($hidden.Count -gt 0) { "$($hidden.Count) Anomaly Items Detected" } else { 'Clean' }
            $hColor   = if ($hidden.Count -gt 0) { 'Red' } else { 'Green' }
            Write-Item -Label 'Total Logged Hashes'      -Value "$($pfFiles.Count) File Objects"     -ValueColor 'Cyan'
            Write-Item -Label 'Hidden Modifications'     -Value $hVal                                -ValueColor $hColor
            Write-Item -Label 'Read-Only Locking Status' -Value "$($readOnly.Count) Flagged Files"   -ValueColor 'White'
        }
    } catch { $ScriptErrors += "Prefetch access violation: $($_.Exception.Message)" }
} else {
    Write-Alert -Message 'System Prefetch directory could not be resolved.'
}

# ---- RECYCLE BIN ----
Write-Section -Title 'STORAGE RECYCLE REPOSITORY'
try {
    $rbPath = $env:SystemDrive + '\$Recycle.Bin'
    if (Test-Path $rbPath) {
        $userFolders  = Get-ChildItem -LiteralPath $rbPath -Directory -Force -ErrorAction SilentlyContinue
        $folderCount  = 0
        $allItems     = @()
        $latestMod    = [DateTime]::MinValue

        if ($userFolders) {
            foreach ($uf in $userFolders) {
                if ($uf.LastWriteTime -gt $latestMod) { $latestMod = $uf.LastWriteTime }
                $folderCount++
                $items = Get-ChildItem -LiteralPath $uf.FullName -File -Force -ErrorAction SilentlyContinue
                if ($items) {
                    $allItems += $items
                    $newest = $items | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                    if ($newest -and $newest.LastWriteTime -gt $latestMod) { $latestMod = $newest.LastWriteTime }
                }
            }
        }

        if ($allItems.Count -gt 0) {
            Write-Item -Label 'Total Objects Cached'         -Value "$($allItems.Count) Items Pending"              -ValueColor 'Yellow'
            Write-Item -Label 'Last Modified Directory Time' -Value $latestMod.ToString('yyyy-MM-dd HH:mm:ss')      -ValueColor 'Cyan'
        } else {
            Write-Item -Label 'Recycle Bin' -Value "$folderCount user folder(s) found, 0 deleted items" -ValueColor 'Green'
        }
    } else {
        Write-Alert -Message 'Recycle Bin storage structure was missing or unreadable.'
    }
} catch { $ScriptErrors += "Recycle Bin query failed: $($_.Exception.Message)" }

# ---- CONSOLE HISTORY ----
Write-Section -Title 'CONSOLE SYSTEM ENVIRONMENT HISTORY'
$histPath = "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadline\ConsoleHost_history.txt"
if (Test-Path $histPath) {
    $hFile = Get-Item -Path $histPath -Force
    $hSize = [math]::Round($hFile.Length / 1KB, 2)
    Write-Item -Label 'PSReadline History Ledger' -Value "Tracking Connected $hSize KB"                              -ValueColor 'Green'
    Write-Item -Label 'Ledger Last Mutation Time' -Value $hFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')        -ValueColor 'Yellow'
} else {
    Write-Item -Label 'PSReadline History Ledger' -Value 'Inoperable or Not Used' -ValueColor 'Gray'
}

# ---- FOOTER ----
Write-Host ''
Write-Host '  System diagnostics complete.' -ForegroundColor Cyan
Write-Host ''
Write-Host '  Reach out to support @imnicc.dll for any errors! <3' -ForegroundColor Yellow

if ($ScriptErrors.Count -gt 0) {
    Write-Host ''
    Write-Host '  Muted Engine Exceptions:' -ForegroundColor DarkGray
    foreach ($err in $ScriptErrors) {
        Write-Host '    -> ' -ForegroundColor DarkGray -NoNewline
        Write-Host $err      -ForegroundColor DarkGray
    }
    Write-Host ''
}
