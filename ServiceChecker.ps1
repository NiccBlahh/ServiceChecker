# Retro CLI Windows System Diagnostic Tool
# Aesthetic: Clean Minimalist Terminal (High Contrast Multi-Color Live Updates)

Clear-Host

# --- Helper Functions for Color Formatting ---
function Write-Header {
    param([string]$Left)
    Write-Host " $Left" -ForegroundColor Cyan
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "  $Title" -ForegroundColor Magenta
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
    $SvcPad = "    $Svc".PadRight(18)
    $DescPad = $Desc.PadRight(40)
    $Color = if ($Status -eq "Running" -or $Status -eq "Enabled") { "Green" } else { "Red" }
    Write-Host $SvcPad -ForegroundColor DarkGreen -NoNewline
    Write-Host "   " -NoNewline
    Write-Host $DescPad -ForegroundColor White -NoNewline
    Write-Host "   " -NoNewline
    Write-Host $Status -ForegroundColor $Color
}

function Write-Alert {
    param([string]$Message)
    Write-Host "    [!] $Message" -ForegroundColor Red
}

# =============================================================================
# START LIVE DATA QUERIES
# =============================================================================

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

# =============================================================================
# START DISPLAY OUTPUT
# =============================================================================
Write-Header -Left "System Check (v2.5.1)"
Write-Host ""

# SECTION: SYSTEM BOOT TIME
Write-Section -Title "SYSTEM BOOT TIME"
Write-Item -Label "Last Boot" -Value $BootTime.ToString("yyyy-MM-dd HH:mm:ss") -ValueColor "Cyan"
Write-Item -Label "Uptime" -Value $UptimeStr -ValueColor "Cyan"

# SECTION: HARDWARE UTILIZATION
Write-Section -Title "HARDWARE UTILIZATION"
Write-Item -Label "CPU Load" -Value "$CpuLoad% Active" -ValueColor "Yellow"
Write-Item -Label "Memory Usage" -Value "$UsedMem GB / $TotalMem GB ($MemPercent%)" -ValueColor "White"

# SECTION: CONNECTED DRIVES
Write-Section -Title "CONNECTED DRIVES & VOLUMES"
Get-CimInstance Win32_LogicalDisk | ForEach-Object {
    $FreeGB = [math]::round($_.FreeSpace / 1GB, 1)
    $SizeGB = [math]::round($_.Size / 1GB, 1)
    if ($SizeGB -gt 0) {
        Write-Item -Label "$($_.DeviceID) [Drive]" -Value "$($_.FileSystem) | $FreeGB GB Free / $SizeGB GB Total" -ValueColor "White"
    }
}

# SECTION: USB DEVICE STORAGE & HISTORY
Write-Section -Title "USB CONTROLLER & HID DEVICE AUDIT"
$Keyboard = Get-PnpDevice -Class Keyboard -Status OK -ErrorAction SilentlyContinue | Select-Object -First 1
$Mouse = Get-PnpDevice -Class Mouse -Status OK -ErrorAction SilentlyContinue | Select-Object -First 1
$UsbStorage = Get-PnpDevice -Class USBDevice -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -like "*Mass*" -or $_.InstanceId -like "*USBSTOR*" }

Write-Item -Label "USB Input [Keyboard]" -Value ($Keyboard ? "$($Keyboard.FriendlyName) [Connected]" : "None Detected") -ValueColor ($Keyboard ? "Green" : "Red")
Write-Item -Label "USB Input [Mouse]" -Value ($Mouse ? "$($Mouse.FriendlyName) [Connected]" : "None Detected") -ValueColor ($Mouse ? "Green" : "Red")
Write-Item -Label "Removable USB Mass Storage" -Value ($UsbStorage ? "$($UsbStorage.Count) Mounted Devices" : "No active mass storage detected") -ValueColor ($UsbStorage ? "Yellow" : "White")

# SECTION: SERVICE STATUS
Write-Section -Title "SERVICE STATUS"
$TargetServices = @(
    @{Name="SysMain"; Desc="System Main Performance Service"}
    @{Name="PcaSvc"; Desc="Program Compatibility Assistant"}
    @{Name="DPS"; Desc="Diagnostic Policy Service"}
    @{Name="EventLog"; Desc="Windows Event Log"}
    @{Name="Schedule"; Desc="Task Scheduler"}
    @{Name="Dusmsvc"; Desc="Data Usage Service"}
    @{Name="Appinfo"; Desc="Application Information"}
    @{Name="CDPSvc"; Desc="Connected Devices Platform"}
    @{Name="wsearch"; Desc="Windows Search"}
)

foreach ($Svc in $TargetServices) {
    $RealSvc = Get-Service -Name $Svc.Name -ErrorAction SilentlyContinue
    $Status = $RealSvc ? $RealSvc.Status.ToString() : "Missing/Disabled"
    Write-SvcRow -Svc $Svc.Name -Desc $Svc.Desc -Status $Status
}

# SECTION: REGISTRY
Write-Section -Title "REGISTRY POLICY"
$PrefetchStatus = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name EnablePrefetcher -ErrorAction SilentlyContinue).EnablePrefetcher
$PrefetchText = if ($PrefetchStatus -eq 3) { "Enabled (App & Boot)" } elseif ($PrefetchStatus -eq 0) { "Disabled" } else { "Enabled ($PrefetchStatus)" }

Write-Item -Label "CMD Execution" -Value "Available" -ValueColor "Green"
Write-Item -Label "Prefetch Global Status" -Value $PrefetchText -ValueColor "Green"

# SECTION: PREFETCH
Write-Section -Title "PREFETCH DIRECTORY STATUS"
if (Test-Path "C:\Windows\Prefetch") {
    $PfCount = (Get-ChildItem -Path "C:\Windows\Prefetch" -Filter "*.pf" -ErrorAction SilentlyContinue).Count
    Write-Item -Label "Total Object Count" -Value "$PfCount Valid Hashes" -ValueColor "Cyan"
} else {
    Write-Alert -Message "Prefetch directory inaccessible (Requires Admin)"
}

# SECTION: RECYCLE BIN
Write-Section -Title "RECYCLE BIN"
$BinItems = Get-ChildItem -Path "C:\`$Recycle.Bin" -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "`$I*" }
$BinCount = $BinItems ? $BinItems.Count : 0
if ($BinCount -eq 0) {
    Write-Item -Label "Recycle Bin State" -Value "Empty / No historical records" -ValueColor "White"
} else {
    Write-Item -Label "Recycle Bin State" -Value "$BinCount Pending Items" -ValueColor "Yellow"
}

Write-Host ""
Write-Host "  System check complete." -ForegroundColor Cyan
Write-Host ""
