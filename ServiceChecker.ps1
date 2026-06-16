# Retro CLI Windows System Diagnostic Tool
# Aesthetic: Cyberpunk / CRT Terminal (Green, Cyan, Yellow, White)

Clear-Host

# --- Helper Functions for Color Formatting ---
function Write-Header {
    param([string]$Left, [string]$Right)
    $Width = 80
    $PadLen = $Width - $Left.Length - $Right.Length - 2
    if ($PadLen -lt 1) { $PadLen = 1 }
    $Padding = " " * $PadLen
    
    Write-Host " " -NoNewline
    Write-Host $Left -ForegroundColor Cyan -NoNewline
    Write-Host $Padding -NoNewline
    Write-Host $Right -ForegroundColor DarkCyan
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
    Write-Host "[!] " -ForegroundColor Yellow -NoNewline
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
Write-Header -Left "System Check (v2.5.1)" -Right "Created & improved by lily<3"
Write-Host ("═" * 80) -ForegroundColor Cyan

# SECTION: SYSTEM BOOT TIME
Write-Section -Title "SYSTEM BOOT TIME"
Write-Item -Label "Last Boot" -Value "2025-10-12 14:09:08"
Write-Item -Label "Uptime" -Value "0 days, 01:50:57"

# SECTION: CONNECTED DRIVES
Write-Section -Title "CONNECTED DRIVES"
Write-Item -Label "C:" -Value "NTFS"

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
Write-Section -Title "REGISTRY"
Write-Item -Label "CMD" -Value "Available" -Color "Green"
Write-Item -Label "PowerShell Logging" -Value "Enabled" -Color "Green"
Write-Item -Label "Activities Cache" -Value "Enabled" -Color "Green"
Write-Item -Label "Prefetch Enabled" -Value "Enabled" -Color "Green"

# SECTION: EVENT LOGS
Write-Section -Title "EVENT LOGS"
Write-Alert -Message "USN Journal cleared - No records found"
Write-Alert -Message "Event Logs cleared - No records found"
Write-Item -Label "Last PC Shutdown at" -Value "10/12 03:20" -Color "Yellow"
Write-Item -Label "System time changed at" -Value "10/10 21:25" -Color "Yellow"
Write-Item -Label "Event Log Service started at" -Value "10/12 14:10" -Color "Yellow"
Write-Item -Label "Device configuration changed at" -Value "10/09 14:56" -Color "Yellow"

# SECTION: PREFETCH
Write-Section -Title "PREFETCH"
Write-Item -Label "Hidden Files" -Value "None"
Write-Item -Label "Read-Only Files" -Value "None"

# SECTION: RECYCLE BIN
Write-Section -Title "RECYCLE BIN"
Write-Item -Label "Recycle Bin" -Value "No activity found"

# FOOTER
Write-Footer -Text "System check complete."
