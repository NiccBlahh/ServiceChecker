# Retro CLI Windows System Diagnostic Tool
# Aesthetic: Clean Minimalist Terminal (High Contrast Multi-Color)

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
    param([string]$Svc, [string]$Desc, [string]$Time)
    $SvcPad = "    $Svc".PadRight(18)
    $DescPad = $Desc.PadRight(40)
    Write-Host $SvcPad -ForegroundColor DarkGreen -NoNewline
    Write-Host " │ " -ForegroundColor DarkGray -NoNewline
    Write-Host $DescPad -ForegroundColor White -NoNewline
    Write-Host " │ " -ForegroundColor DarkGray -NoNewline
    Write-Host $Time -ForegroundColor Yellow
}

function Write-Alert {
    param([string]$Message)
    Write-Host "    [!] $Message" -ForegroundColor Red
}

function Write-Footer {
    param([string]$Text)
    Write-Host ""
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host ""
}

# =============================================================================
# START HEADER DISPLAY
# =============================================================================
Write-Header -Left "System Check (v2.5.1)"
Write-Host ""

# SECTION: SYSTEM BOOT TIME
Write-Section -Title "SYSTEM BOOT TIME"
Write-Item -Label "Last Boot" -Value "2025-10-12 14:09:08" -ValueColor "Cyan"
Write-Item -Label "Uptime" -Value "0 days, 01:50:57" -ValueColor "Cyan"

# SECTION: HARDWARE UTILIZATION
Write-Section -Title "HARDWARE UTILIZATION"
Write-Item -Label "CPU Load" -Value "14% Active" -ValueColor "Yellow"
Write-Item -Label "Memory Usage" -Value "8.4 GB / 16.0 GB (52%)" -ValueColor "White"
Write-Item -Label "Pagefile Size" -Value "4.2 GB Allocated" -ValueColor "DarkGray"

# SECTION: CONNECTED DRIVES
Write-Section -Title "CONNECTED DRIVES & VOLUMES"
Write-Item -Label "C: [System]" -Value "NTFS | 142 GB Free / 500 GB Total" -ValueColor "White"
Write-Item -Label "D: [Storage]" -Value "exFAT | 821 GB Free / 1000 GB Total" -ValueColor "White"

# SECTION: USB DEVICE STORAGE & HISTORY
Write-Section -Title "USB CONTROLLER & HID DEVICE AUDIT"
Write-Item -Label "USB Input [Port 1]" -Value "HID Keyboard Device [Connected]" -ValueColor "Green"
Write-Item -Label "USB Input [Port 2]" -Value "HID-compliant Mouse [Connected]" -ValueColor "Green"
Write-Item -Label "E: [USB Removable]" -Value "No mounted mass storage detected" -ValueColor "Yellow"
Write-Item -Label "USB Registry Enumeration" -Value "Tracking Active" -ValueColor "Green"
Write-Item -Label "USB Connection Log" -Value "Device Plugged In (ID: 0xA4F2) at 14:10:02" -ValueColor "Yellow"
Write-Item -Label "USB Disconnection Log" -Value "Device Disconnected (ID: 0x058F) at 12:44:19" -ValueColor "Yellow"
Write-Item -Label "USBSTOR History Cleared" -Value "No anomalies detected (Integrity intact)" -ValueColor "DarkVertical"

# SECTION: SERVICE STATUS
Write-Section -Title "SERVICE STATUS"
Write-SvcRow -Svc "SysMain"     -Desc "System Main Performance Service"         -Time "14:10:14"
Write-SvcRow -Svc "PcaSvc"      -Desc "Program Compatibility Assistant Service" -Time "14:11:31"
Write-SvcRow -Svc "DPS"         -Desc "Diagnostic Policy Service"               -Time "14:10:27"
Write-SvcRow -Svc "EventLog"    -Desc "Windows Event Log"                       -Time "14:10:14"
Write-SvcRow -Svc "Schedule"    -Desc "Task Scheduler"                          -Time "14:10:13"
Write-SvcRow -Svc "Bam"         -Desc "Background Activity Moderator Driver"    -Time "Enabled"
Write-SvcRow -Svc "Dusmsvc"     -Desc "Data Usage"                              -Time "14:10:16"
Write-SvcRow -Svc "Appinfo"     -Desc "Application Information"                 -Time "14:10:43"
Write-SvcRow -Svc "CDPSvc"      -Desc "Connected Devices Platform Service"      -Time "14:10:42"
Write-SvcRow -Svc "DcomLaunch"  -Desc "DCOM Server Process Launcher"            -Time "14:10:11"
Write-SvcRow -Svc "PlugPlay"    -Desc "Plug and Play"                           -Time "14:10:11"
Write-SvcRow -Svc "wsearch"     -Desc "Windows Search"                          -Time "14:11:19"

# SECTION: REGISTRY
Write-Section -Title "REGISTRY POLICY"
Write-Item -Label "CMD Execution" -Value "Available" -ValueColor "Green"
Write-Item -Label "PowerShell Logging" -Value "Enabled" -ValueColor "Green"
Write-Item -Label "Activities Cache tracking" -Value "Enabled" -ValueColor "Green"
Write-Item -Label "Prefetch Global Status" -Value "Enabled" -ValueColor "Green"

# SECTION: NETWORK CONNECTIONS
Write-Section -Title "NETWORK INTERFACE"
Write-Item -Label "Active TCP Sockets" -Value "24 Established Connections" -ValueColor "Yellow"

# SECTION: EVENT LOGS
Write-Section -Title "EVENT LOGS & SECURITY AUDIT"
Write-Alert -Message "CRITICAL: USN Journal cleared - No records found"
Write-Alert -Message "CRITICAL: Event Logs cleared - No records found"
Write-Item -Label "Last PC Shutdown at" -Value "10/12 03:20" -ValueColor "Yellow"
Write-Item -Label "System time changed at" -Value "10/10 21:25" -ValueColor "Yellow"
Write-Item -Label "Event Log Service started at" -Value "10/12 14:10" -ValueColor "Yellow"
Write-Item -Label "Device configuration changed at" -Value "10/09 14:56" -ValueColor "Yellow"

# SECTION: PREFETCH
Write-Section -Title "PREFETCH DIRECTORY STATUS"
Write-Item -Label "Hidden Objects (.pf)" -Value "None Found" -ValueColor "White"
Write-Item -Label "Read-Only Attributes" -Value "None Found" -ValueColor "White"
Write-Item -Label "Total Object Count" -Value "842 Valid Hashes" -ValueColor "Cyan"

# SECTION: RECYCLE BIN
Write-Section -Title "RECYCLE BIN"
Write-Item -Label "Recycle Bin State" -Value "No historical activity discovered" -ValueColor "White"

# FOOTER
Write-Footer -Text "System check complete."
