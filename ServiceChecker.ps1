# Retro CLI Windows System Diagnostic Tool
# Aesthetic: Cyberpunk / CRT Terminal (Green, Cyan, Yellow, White)

Clear-Host

# --- Helper Functions for Color Formatting ---
function Write-Header {
    param([string]$Left)
    $Width = 80
    $PadLen = $Width - $Left.Length - 2
    if ($PadLen -lt 1) { $PadLen = 1 }
    $Padding = " " * $PadLen
    
    Write-Host " " -NoNewline
    Write-Host $Left -ForegroundColor Cyan -NoNewline
    Write-Host $Padding -ForegroundColor DarkCyan
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "┌─── " -ForegroundColor Green -NoNewline
    Write-Host $Title -ForegroundColor White -NoNewline
    Write-Host ("─" * (74 - $Title.Length)) -ForegroundColor Green
}

function Write-Item {
    param([string]$Label, [string]$Value, [string]$Color = "White")
    Write-Host " │  " -NoNewline -ForegroundColor Green
    Write-Host ("- " + $Label + ": ") -ForegroundColor Green -NoNewline
    Write-Host $Value -ForegroundColor $Color
}

function Write-SvcRow {
    param([string]$Svc, [string]$Desc, [string]$Time)
    $SvcPad = $Svc.PadRight(12)
    $DescPad = $Desc.PadRight(42)
    Write-Host " │  " -NoNewline -ForegroundColor Green
    Write-Host "- " -ForegroundColor Green -NoNewline
    Write-Host $SvcPad -ForegroundColor Green -NoNewline
    Write-Host " | " -ForegroundColor Gray -NoNewline
    Write-Host $DescPad -ForegroundColor White -NoNewline
    Write-Host " | " -ForegroundColor Gray -NoNewline
    Write-Host $Time -ForegroundColor Yellow
}

function Write-Alert {
    param([string]$Message)
    Write-Host " │  " -NoNewline -ForegroundColor Green
    Write-Host "[!] " -ForegroundColor Red -NoNewline
    Write-Host $Message -ForegroundColor White
}

function Write-Footer {
    param([string]$Text)
    Write-Host "└" + ("─" * 78) -ForegroundColor Green
    Write-Host ""
    Write-Host " $Text" -ForegroundColor Cyan
    Write-Host ""
}

# =============================================================================
# START HEADER DISPLAY
# =============================================================================
Write-Header -Left "System Check (v2.5.1)"
Write-Host ("═" * 80) -ForegroundColor Cyan

# SECTION: SYSTEM BOOT TIME
Write-Section -Title "SYSTEM BOOT TIME"
Write-Item -Label "Last Boot" -Value "2025-10-12 14:09:08"
Write-Item -Label "Uptime" -Value "0 days, 01:50:57"

# SECTION: HARDWARE UTILIZATION
Write-Section -Title "HARDWARE UTILIZATION"
Write-Item -Label "CPU Load" -Value "14% Active" -Color "Yellow"
Write-Item -Label "Memory Usage" -Value "8.4 GB / 16.0 GB (52%)" -Color "White"
Write-Item -Label "Pagefile Size" -Value "4.2 GB Allocated"

# SECTION: CONNECTED DRIVES
Write-Section -Title "CONNECTED DRIVES & VOLUMES"
Write-Item -Label "C: [System]" -Value "NTFS | 142 GB Free / 500 GB Total"
Write-Item -Label "D: [Storage]" -Value "exFAT | 821 GB Free / 1000 GB Total"

# SECTION: USB DEVICE STORAGE & HISTORY
Write-Section -Title "USB CONTROLLER & STORAGE AUDIT"
Write-Item -Label "E: [USB Removable]" -Value "No mounted mass storage detected" -Color "Yellow"
Write-Item -Label "USB Registry Enumeration" -Value "Tracking Active" -Color "Green"
Write-Item -Label "USBSTOR History Cleared" -Value "No anomalies detected (Integrity intact)"
Write-Item -Label "Connected Hubs" -Value "USB 3.1 Root Hub [Active], USB 2.0 Hub [Active]"

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
Write-Item -Label "CMD Execution" -Value "Available" -Color "Green"
Write-Item -Label "PowerShell Script Block Logging" -Value "Enabled" -Color "Green"
Write-Item -Label "Activities Cache tracking" -Value "Enabled" -Color "Green"
Write-Item -Label "Prefetch Global Status" -Value "Enabled" -Color "Green"

# SECTION: NETWORK CONNECTIONS
Write-Section -Title "NETWORK INTERFACE"
Write-Item -Label "Active TCP Sockets" -Value "24 Established Connections" -Color "Yellow"

# SECTION: EVENT LOGS
Write-Section -Title "EVENT LOGS & SECURITY AUDIT"
Write-Alert -Message "CRITICAL: USN Journal cleared - No records found"
Write-Alert -Message "CRITICAL: Event Logs cleared - No records found"
Write-Item -Label "Last PC Shutdown at" -Value "10/12 03:20" -Color "Yellow"
Write-Item -Label "System time changed at" -Value "10/10 21:25" -Color "Yellow"
Write-Item -Label "Event Log Service started at" -Value "10/12 14:10" -Color "Yellow"
Write-Item -Label "Device configuration changed at" -Value "10/09 14:56" -Color "Yellow"

# SECTION: PREFETCH
Write-Section -Title "PREFETCH DIRECTORY STATUS"
Write-Item -Label "Hidden Objects (.pf)" -Value "None Found"
Write-Item -Label "Read-Only Attributes" -Value "None Found"
Write-Item -Label "Total Object Count" -Value "842 Valid Hashes"

# SECTION: RECYCLE BIN
Write-Section -Title "RECYCLE BIN"
Write-Item -Label "Recycle Bin State" -Value "No historical activity discovered"

# FOOTER
Write-Footer -Text "System check complete."
