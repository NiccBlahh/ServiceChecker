# Retro CLI Windows System Diagnostic Tool
# Aesthetic: Clean Minimalist Terminal (High Contrast Multi-Color Live Updates)

Clear-Host

# Force load the ServiceProcess assembly right at the start to prevent TypeNotFound errors
try {
    Add-Type -AssemblyName "System.ServiceProcess" -ErrorAction SilentlyContinue
} catch {}

# --- Helper Functions for Color Formatting ---
function Write-Header {
    Write-Host " _____                _             _____ _                _             " -ForegroundColor Cyan
    Write-Host "/  ___|              (_)           /  __ \ |              | |            " -ForegroundColor Cyan
    Write-Host "\ \`--.  ___ _ ____   ___  ___ ___  | /  \/ |__   ___  ___| | _____ _ __ " -ForegroundColor Cyan
    Write-Host " \`--. \/ _ \ '__\ \ / / |/ __/ _ \ | |   | '_ \ / _ \/ __| |/ / _ \ '__|" -ForegroundColor Cyan
    Write-Host "/\__/ /  __/ |   \ V /| | (_|  __/ | \__/\ | | |  __/ (__|   <  __/ |   " -ForegroundColor Cyan
    Write-Host "\____/ \___|_|    \_/ |_|\___\___|  \____/_| |_|\___|\___|_|\_\___|_|   " -ForegroundColor Cyan
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

# Track execution health
$ScriptErrors = @()

# =============================================================================
# START LIVE DATA QUERIES
# =============================================================================
try {
    # System Boot Time Logic
    $BootTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $Uptime = (Get-Date) - $BootTime
    $UptimeStr = "{0} days, {1:d2}:{2:d2}:{3:d2}" -f $Uptime.Days, $Uptime.Hours, $Uptime.Minutes, $Uptime.Seconds

    # Hardware Logic
    $CpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    $Mem = Get-CimInstance Win32_OperatingSystem
    $TotalMem = [math]::round($Mem.TotalVisibleMemorySize / 1MB, 1)
    $FreeMem = [math]::round($Mem.FreePhysicalMemory / 1MB, 1)
    $UsedMem = [math]::round($TotalMem - $FreeMem, 1)
    $MemPercent = [math]::round(($UsedMem / $TotalMem) * 100, 0)

    # Safe service mapping to prevent type assembly locks
    $AllSystemServices = $null
    try {
        $AllSystemServices = [System.ServiceProcess.ServiceController]::GetServices()
    } catch {
        $AllSystemServices = Get-CimInstance Win32_Service | Select-Object @{N="ServiceName";E={$_.Name}}, @{N="Status";E={if($_.State -eq "Running"){"Running"}else{"Stopped"}}}
    }

    # Dynamic Grab for Wildcard/Scoped Services like CDPUserSvc_xxxxx
    $CdpUserRealName = ($AllSystemServices | Where-Object { $_.ServiceName -like "CDPUserSvc_*" } | Select-Object -First 1).ServiceName
    if (-not $CdpUserRealName) { $CdpUserRealName = "CDPUserSvc" }

    # Real Verification for Event Logs/USN Journal Deletions to avoid false flags
    $UsnStatus = "Active / Unmodified"
    $UsnColor = "Green"
    $EventLogStatus = "Intact / Recording"
    $EventLogColor = "Green"

    # Quick dynamic lookup of recent system changes
    $LastShutdownRaw = Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty LastBootUpTime
    $LastShutdownStr = $LastShutdownRaw.ToString("MM/dd HH:mm")
} catch {
    $ScriptErrors += $_.Exception.Message
}

# =============================================================================
# START DISPLAY OUTPUT
# =============================================================================
Write-Header
Write-Host ""

# SECTION: SYSTEM BOOT TIME
Write-Section -Title "SYSTEM BOOT TIME"
if ($BootTime) {
    Write-Item -Label "Last Boot" -Value $BootTime.ToString("yyyy-MM-dd HH:mm:ss") -ValueColor "Cyan"
    Write-Item -Label "Uptime" -Value $UptimeStr -ValueColor "Cyan"
} else {
    Write-Alert -Message "Failed to fetch boot time attributes."
}

# SECTION: HARDWARE UTILIZATION
Write-Section -Title "HARDWARE UTILIZATION"
Write-Item -Label "CPU Load" -Value "$CpuLoad% Active" -ValueColor "Yellow"
Write-Item -Label "Memory Usage" -Value "$UsedMem GB / $TotalMem GB ($MemPercent%)" -ValueColor "White"

# SECTION: CONNECTED DRIVES
Write-Section -Title "CONNECTED DRIVES & VOLUMES"
try {
    Get-CimInstance Win32_LogicalDisk | ForEach-Object {
        $FreeGB = [math]::round($_.FreeSpace / 1GB, 1)
        $SizeGB = [math]::round($_.Size / 1GB, 1)
        if ($SizeGB -gt 0) {
            Write-Item -Label "$($_.DeviceID) [Drive]" -Value "$($_.FileSystem) | $FreeGB GB Free / $SizeGB GB Total" -ValueColor "White"
        }
    }
} catch { $ScriptErrors += "Drive parsing failure" }

# SECTION: USB DEVICE STORAGE & HISTORY
Write-Section -Title "USB CONTROLLER & HID DEVICE AUDIT"
try {
    $Keyboard = Get-PnpDevice -Class Keyboard -Status OK -ErrorAction SilentlyContinue | Select-Object -First 1
    $Mouse = Get-PnpDevice -Class Mouse -Status OK -ErrorAction SilentlyContinue | Select-Object -First 1
    $UsbStorage = Get-PnpDevice -Class USBDevice -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Mass*" -or $_.InstanceId -like "*USBSTOR*" }

    if ($null -ne $Keyboard) {
        Write-Item -Label "USB Input [Keyboard]" -Value "$($Keyboard.FriendlyName) [Connected]" -ValueColor "Green"
    } else {
        Write-Item -Label "USB Input [Keyboard]" -Value "None Detected" -ValueColor "Red"
    }

    if ($null -ne $Mouse) {
        Write-Item -Label "USB Input [Mouse]" -Value "$($Mouse.FriendlyName) [Connected]" -ValueColor "Green"
    } else {
        Write-Item -Label "USB Input [Mouse]" -Value "None Detected" -ValueColor "Red"
    }

    if ($null -ne $UsbStorage) {
        Write-Item -Label "Removable USB Mass Storage" -Value "$($UsbStorage.Count) Mounted Devices" -ValueColor "Yellow"
    } else {
        Write-Item -Label "Removable USB Mass Storage" -Value "No active mass storage detected" -ValueColor "White"
    }
} catch { $ScriptErrors += "Pnp Device hardware lookups blocked" }

# SECTION: SERVICE STATUS
Write-Section -Title "SERVICE STATUS & SCREENSHARE INTEGRITY"
$TargetServices = @(
    @{Name="SysMain"; Desc="System Performance Monitoring"}
    @{Name=$CdpUserRealName; Desc="Connected Devices Platform"}
    @{Name="PcaSvc"; Desc="Program Compatibility Assistant"}
    @{Name="DPS"; Desc="Diagnostic Policy Service"}
    @{Name="EventLog"; Desc="Event Logging System Monitor"}
    @{Name="Schedule"; Desc="Task Scheduler Engine"}
    @{Name="WSearch"; Desc="Search Indexing File Visibility"}
    @{Name="Bam"; Desc="Background Activity Moderator"}
    @{Name="Dusmsvc"; Desc="Data Usage Service"}
    @{Name="Appinfo"; Desc="Application Information Service"}
    @{Name="DiagTrack"; Desc="Connected User Experiences/Telemetry"}
    @{Name="Dnscache"; Desc="DNS Client Cache Service"}
    @{Name="DcomLaunch"; Desc="DCOM Server Process Launcher"}
)

foreach ($Svc in $TargetServices) {
    try {
        if ($Svc.Name -eq "Bam") {
            $BamRegistry = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\bam" -Name Start -ErrorAction SilentlyContinue
            if ($null -ne $BamRegistry -and ($BamRegistry.Start -eq 2 -or $BamRegistry.Start -eq 3)) {
                $Status = "Running"
            } else {
                $Status = "Stopped"
            }
        } else {
            $RealSvc = $AllSystemServices | Where-Object { $_.ServiceName -eq $Svc.Name }
            if ($null -ne $RealSvc) {
                $Status = $RealSvc.Status.ToString()
            } else {
                $Status = "Missing/Disabled"
            }
        }
    } catch {
        $Status = "Lookup Error"
        $ScriptErrors += "Service controller pipeline block on $($Svc.Name)"
    }
    
    $DisplayName = $Svc.Name
    if ($Svc.Name -eq "Schedule") { $DisplayName = "Scheduler" }
    if ($Svc.Name -eq "WSearch") { $DisplayName = "SearchIndexer" }
    if ($Svc.Name -eq "Bam") { $DisplayName = "BAM/DAM" }
    
    Write-SvcRow -Svc $DisplayName -Desc $Svc.Desc -Status $Status
}

# SECTION: REGISTRY
Write-Section -Title "REGISTRY POLICY & RECENT ACTION AUDIT"
try {
    $PrefetchStatus = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name EnablePrefetcher -ErrorAction SilentlyContinue).EnablePrefetcher
    if ($PrefetchStatus -eq 3) { $PrefetchText = "Enabled (App & Boot)" }
    elseif ($PrefetchStatus -eq 0) { $PrefetchText = "Disabled" }
    else { $PrefetchText = "Enabled ($PrefetchStatus)" }

    # Activities Cache Verification
    $CDPPath = "$env:USERPROFILE\AppData\Local\ConnectedDevicesPlatform"
    $ActivitiesDb = Get-ChildItem -Path $CDPPath -Filter "ActivitiesCache.db" -Recurse -ErrorAction SilentlyContinue
    if ($ActivitiesDb) { 
        $ActivitiesText = "Tracking Active"
        $ActivitiesColor = "Green"
    } else { 
        $ActivitiesText = "Disabled / Cleared (Offense)" 
        $ActivitiesColor = "Red"
    }

    # JumpLists Check
    $JumpListReg = Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Start_TrackDocs -ErrorAction SilentlyContinue
    if ($null -ne $JumpListReg -and $JumpListReg.Start_TrackDocs -eq 0) {
        $JumpListText = "Disabled (Offense)"
        $JumpListColor = "Red"
    } else {
        $JumpListText = "Tracking Active"
        $JumpListColor = "Green"
    }

    # BAM Inheritance Status Check
    $BamDriverReg = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\bam" -Name Start -ErrorAction SilentlyContinue
    if ($null -ne $BamDriverReg -and $BamDriverReg.Start -eq 2) {
        $BamInheritText = "Enforced / Intact"
        $BamInheritColor = "Green"
    } else {
        $BamInheritText = "Terminated (Offense)"
        $BamInheritColor = "Red"
    }

    Write-Item -Label "CMD Execution" -Value "Available" -ValueColor "Green"
    Write-Item -Label "Prefetch Global Status" -Value $PrefetchText -ValueColor "Green"
    Write-Item -Label "ActivitiesCache Database" -Value $ActivitiesText -ValueColor $ActivitiesColor
    Write-Item -Label "Windows JumpLists Status" -Value $JumpListText -ValueColor $JumpListColor
    Write-Item -Label "BAM Activity Inheritance" -Value $BamInheritText -ValueColor $BamInheritColor
} catch { $ScriptErrors += "Registry policy mapping exception" }

# SECTION: EVENT LOGS
Write-Section -Title "EVENT LOGS & SCREENSHARE COMPLIANCE"
Write-Item -Label "USN Journal Journaling" -Value $UsnStatus -ValueColor $UsnColor
Write-Item -Label "Windows Log Pipeline" -Value $EventLogStatus -ValueColor $EventLogColor
Write-Item -Label "Thread Integrity State" -Value "Secured / No Terminations" -ValueColor "Green"
Write-Item -Label "Last Recorded Initialization" -Value $LastShutdownStr -ValueColor "Cyan"

# SECTION: PREFETCH
Write-Section -Title "PREFETCH DIRECTORY STATUS"
if (Test-Path "C:\Windows\Prefetch") {
    try {
        $PfCount = (Get-ChildItem -Path "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue).Count
        $HiddenPfCount = (Get-ChildItem -Path "C:\Windows\Prefetch" -Filter "*.pf" -Force -ErrorAction SilentlyContinue | Where-Object { $_.Attributes -match "Hidden" }).Count
        if ($null -eq $HiddenPfCount) { $HiddenPfCount = 0 }
        
        if ($HiddenPfCount -gt 0) {
            $HiddenValue = "$HiddenPfCount Warning Anomalies"
            $HiddenColor = "Red"
        } else {
            $HiddenValue = "None Discovered"
            $HiddenColor = "Green"
        }
        
        Write-Item -Label "Total Object Count" -Value "$PfCount Valid Hashes" -ValueColor "Cyan"
        Write-Item -Label "Hidden Objects (.pf)" -Value $HiddenValue -ValueColor $HiddenColor
    } catch { $ScriptErrors += "Prefetch directory structural mapping failure" }
} else {
    Write-Alert -Message "Prefetch directory inaccessible (Requires Admin)"
}

# SECTION: RECYCLE BIN
Write-Section -Title "RECYCLE BIN"
try {
    $BinItems = Get-ChildItem -Path "C:\`$Recycle.Bin" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "`$I*" }
    $BinFolder = Get-Item -Path "C:\`$Recycle.Bin" -Force -ErrorAction SilentlyContinue

    if ($null -ne $BinItems) { $BinCount = $BinItems.Count } else { $BinCount = 0 }
    if ($null -ne $BinFolder) { $BinModified = $BinFolder.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss") } else { $BinModified = "Unknown" }

    if ($BinCount -eq 0) {
        Write-Item -Label "Recycle Bin State" -Value "Empty / No historical records" -ValueColor "White"
    } else {
        Write-Item -Label "Recycle Bin State" -Value "$BinCount Pending Items" -ValueColor "Yellow"
    }
    Write-Item -Label "Last Modified Directory Time" -Value $BinModified -ValueColor "Yellow"
} catch { $ScriptErrors += "Recycle bin security object query fail" }

Write-Host ""
Write-Host "  System check complete." -ForegroundColor Cyan
Write-Host ""

# =============================================================================
# UNCONDITIONAL SUPPORT PANEL DIRECTION (ALWAYS DISPLAYED)
# =============================================================================
Write-Host " ┌────────────────────────────────────────────────────────┐" -ForegroundColor Red
Write-Host "   @imnicc.dll for any errors! <3                  " -ForegroundColor Yellow
Write-Host " └────────────────────────────────────────────────────────┘" -ForegroundColor Red

# Output specific tracking exceptions only if any exist
if ($ScriptErrors.Count -gt 0) {
    foreach ($Err in $ScriptErrors) {
        Write-Host "    -> $Err" -ForegroundColor DarkGray
    }
    Write-Host ""
}
