# ServiceChecker

**Retro CLI Windows system diagnostic tool — service auditing, registry policy enforcement, event log integrity, prefetch analytics, and Recycle Bin forensics.**

ServiceChecker is an elevated PowerShell script that performs a comprehensive health and security audit of a Windows system. It consolidates live service states, registry policy compliance checks, critical event log queries, prefetch file analysis, and Recycle Bin structural inspection into a single retro-styled terminal report.

---

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Example Output](#example-output)
- [How It Works](#how-it-works)
- [Audited Services](#audited-services)
- [Registry Policies Checked](#registry-policies-checked)
- [Event Log Queries](#event-log-queries)
- [Technical Details](#technical-details)
- [Notes](#notes)

---

## Features

- **Administrator Enforcement** — Detects if the script is running with elevated privileges and exits with a clear message if not
- **System Boot Time & Uptime** — Displays last boot time and formatted uptime from WMI
- **Hardware Utilization** — Reports current CPU load percentage and physical memory usage (used / total GB with percent)
- **Connected Drives & Volumes** — Enumerates all non-CD/DVD logical volumes with filesystem type, free space, and total size
- **Service Status Monitoring** — Queries 13 critical Windows services including SysMain, DiagTrack (telemetry), DPS, EventLog, Task Scheduler, Windows Search, BAM, DCOM Launch, and Plug and Play — with color-coded running/stopped status
- **Registry Policy Audit** — Checks four key registry policies:
  - CMD Execution Restrictions
  - PowerShell Script Block Logging
  - Activity Feed / Timeline Tracking
  - Prefetcher Configuration
- **Event Log Integrity** — Queries Windows Event Logs for:
  - USN Journal modification events (potential forensic countermeasures)
  - Security/System log clearance events
  - System shutdown records
  - System time change events
  - EventLog service startup confirmation
- **Prefetch Analysis** — Scans `%SystemRoot%\Prefetch` for `.pf` files, counts total entries, detects hidden files, and reports read-only flags
- **Recycle Bin Forensics** — Walks `\$Recycle.Bin` directory structure, counts deleted item headers (`$I` files), and reports last modification time
- **Console History Check** — Reports PSReadline `ConsoleHost_history.txt` file size and last write time
- **Retro ASCII Banner** — "DIAGNOSTIC" ASCII art header in cyan
- **Color-Coded Output** — Green for healthy/active, Red for stopped/blocked, Yellow for warnings, Cyan for informational
- **Error Tolerant** — All failures are caught silently and reported in a summary section at the end

---

## Requirements

- **Operating System:** Windows 10 / Windows 11
- **PowerShell:** Version 5.1 (included with Windows)
- **Privileges:** **Must be run as Administrator** — many queries (service status, registry policies, prefetch, Recycle Bin, event logs) require elevation
- **Dependencies:** None. Uses .NET Framework 4.x and built-in Windows modules only

---

## Installation

**One-liner (run from CMD as Administrator):**

```cmd
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/ServiceChecker.ps1')"
```

**Or download and run locally:**

1. Download `ServiceChecker.ps1` to any directory
2. Open a Command Prompt **as Administrator**
3. Run:

```cmd
powershell -ExecutionPolicy Bypass -File "ServiceChecker.ps1"
```

> **⚠️ This script requires Administrator privileges.** It will exit immediately if not run elevated.

---

## Usage

```cmd
powershell -ExecutionPolicy Bypass -File "ServiceChecker.ps1"
```

**Run directly from GitHub:**
```cmd
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/NiccBlahh/MacroDetector/refs/heads/main/ServiceChecker.ps1')"
```

No installation required. Right-click Command Prompt and select "Run as administrator" before executing.

---

## Example Output

```
 _____                _             _____ _                _             
/  ___|              (_)           /  __ \ |              | |            
\ `--.  ___ _ ____   ___  ___ ___  | /  \/ |__   ___  ___| | _____ _ __ 
 `--. \/ _ \ __\ \ / / |/ __/ _ \ | |   | _ \ / _ \/ __| |/ / _ \ __|
/\__/ /  __/ |   \ V /| | (_|  __/ | \__/\ | | |  __/ (__|   <  __/ |   
\____/ \___|_|    \_/ |_|\___\___|  \____/_| |_|\___|\___|_|\_\___|_|   

  ■ SYSTEM BOOT TIME
    Last Boot Time                   : 2026-06-17 03:22:15
    System Uptime                    : 0 days, 00:45:30

  ■ HARDWARE UTILIZATION
    CPU Load                         : 12% Active
    Memory Usage                     : 6.2 GB / 15.9 GB (39%)

  ■ CONNECTED DRIVES and LOGICAL VOLUMES
    Volume [C:]                      : NTFS | 120.5 GB Free / 475.0 GB Total

  ■ SERVICE STATUS and CORE MONITORING
    SysMain              System Performance/SysMain Monitoring          Running
    CDPUserSvc_xxxxx     Connected Devices Platform                    Running
    PcaSvc               Program Compatibility Assistant                Stopped
    DPS                  Diagnostic Policy Service                     Running
    EventLog             Event Logging System Monitor                  Running
    Scheduler            Task Scheduler Engine                         Running
    SearchIndexer        Windows Search Indexer                        Running
    Bam                  Background Activity Moderator                 Running
    Dusmsvc              Data Usage Service Monitor                    Running
    Appinfo              Application Information Service               Running
    DcomLaunch           DCOM Server Process Launcher                  Running
    PlugPlay             Plug and Play Engine                          Running
    DiagTrack            Telemetry / Diagnostic Tracking Service       Running

  ■ REGISTRY POLICY AUDIT
    CMD Execution Rules              : Available
    PowerShell Logging               : Logging Enabled
    Activities Cache Feed            : Tracking Enabled
    Prefetch Driver Status           : Enabled (Optimal)

  ■ CRITICAL EVENT LOG AUDIT
    USN Journal Clearance            : USN Modification Event - No records found
    Windows Log Pipelines            : Clear Events Log Action - No records found
    Last Recorded Shutdown           : Hardware Stop Command at: 06/17 03:22
    System Time Integrity            : Time Change Action - No records found
    Service Initialization           : Event Log Upstream Start at: 06/17 03:22

  ■ PREFETCH IMAGE INTEGRITY
    Total Logged Hashes              : 1425 File Objects
    Hidden Modifications             : Clean
    Read-Only Locking Status         : 0 Flagged Files

  ■ STORAGE RECYCLE REPOSITORY
    Total Objects Cached             : 847 Items Pending
    Last Modified Directory Time     : 2026-06-17 03:45:22

  ■ CONSOLE SYSTEM ENVIRONMENT HISTORY
    PSReadline History Ledger        : Tracking Connected (12.45 KB)
    Ledger Last Mutation Time        : 2026-06-17 03:44:10

  System diagnostics complete.

 ┌────────────────────────────────────────────────────────┐
   Reach out to support @imnicc.dll for any errors!. <3  
 └────────────────────────────────────────────────────────┘
```

---

## How It Works

ServiceChecker operates in 10 sequential sections:

### 1. Admin Check
Uses `WindowsPrincipal` and `WindowsBuiltInRole::Administrator` to verify elevation. Exits immediately with a red-bordered message if not running as administrator.

### 2. System Boot Time
Queries `Win32_OperatingSystem` via `Get-CimInstance` for `LastBootUpTime`. Calculates uptime as a formatted duration string (days, hours, minutes, seconds).

### 3. Hardware Utilization
- **CPU**: Averages `LoadPercentage` across all processors via `Win32_Processor`
- **Memory**: Reads `TotalVisibleMemorySize` and `FreePhysicalMemory` from `Win32_OperatingSystem`, converts to GB, calculates used memory and percentage

### 4. Connected Drives
Queries `Win32_LogicalDisk` excluding drive type 5 (CD/DVD). For each volume, reports filesystem type, free space, and total size in GB.

### 5. Service Status
Targets 13 system services using `[System.ServiceProcess.ServiceController]::GetServices()`. For services with scoped/dynamic names (e.g., `CDPUserSvc_<suffix>`), performs a wildcard search. The BAM service is checked via registry startup type rather than service controller. Each service is displayed with a color-coded status (cyan for running, red for stopped).

### 6. Registry Policy Audit
Checks four registry paths against expected values:
- `DisableCMD` should be 0 (CMD available)
- `EnableScriptBlockLogging` should be 1 (PowerShell logging on)
- `EnableActivityFeed` should be 1 (timeline tracking on)
- `EnablePrefetcher` should be 3 (prefetch enabled for boot + apps)

Values that differ from the target are highlighted in red.

### 7. Event Log Integrity
Queries five Windows Event Logs using structured `FilterXPath` queries:
- Application log, Event ID 3079 — USN journal modifications
- System log, Event IDs 104/1102 — Log clearance events
- System log, Event ID 1074 — System shutdown
- Security log, Event ID 4616 — Time changes
- System log, Event ID 6005 — EventLog service start

Returns the most recent matching event with timestamp, or "No records found".

### 8. Prefetch Analysis
Scans `%SystemRoot%\Prefetch\*.pf` using `Get-ChildItem -Force` to include hidden files. Reports:
- Total count of prefetch files
- Count of hidden files (potential tampering indicator)
- Count of read-only files

### 9. Recycle Bin Forensics
Enumerates `\$Recycle.Bin` on the system drive. For each user SID subdirectory:
- Collects all `$I*` files (deletion metadata headers)
- Tracks the newest modification time across all items
- Reports total item count and latest change timestamp

### 10. Console History
Checks for `PSReadline\ConsoleHost_history.txt` in the roaming profile. Reports file size in KB and last write time. If the file doesn't exist, reports "Inoperable or Not Used" (in gray) — this is normal for systems where PSReadline history is disabled or never used.

---

## Audited Services

| Display Name | Service Name | Purpose |
|-------------|-------------|---------|
| SysMain | SysMain | System performance / Superfetch / SysMain monitoring |
| CDPUserSvc | CDPUserSvc_* | Connected Devices Platform (dynamic suffix) |
| PcaSvc | PcaSvc | Program Compatibility Assistant |
| DPS | DPS | Diagnostic Policy Service |
| EventLog | EventLog | Windows Event Log |
| Scheduler | Schedule | Task Scheduler |
| SearchIndexer | wsearch | Windows Search indexer |
| BAM | Bam | Background Activity Moderator |
| DusmSvc | Dusmsvc | Data Usage Service |
| AppInfo | Appinfo | Application Information |
| DcomLaunch | DcomLaunch | DCOM server process launcher |
| PlugPlay | PlugPlay | Plug and Play |
| DiagTrack | DiagTrack | Diagnostic Tracking / Telemetry |

---

## Registry Policies Checked

| Policy | Registry Path | Key | Expected | Risk if Modified |
|--------|--------------|-----|----------|-----------------|
| CMD Execution | `HKCU:\...\Windows\System` | `DisableCMD` | 0 (Available) | CMD blocked |
| PowerShell Logging | `HKLM:\...\PowerShell\ScriptBlockLogging` | `EnableScriptBlockLogging` | 1 (Enabled) | Script block logging disabled |
| Activity Feed | `HKLM:\...\Windows\System` | `EnableActivityFeed` | 1 (Enabled) | Timeline/tracking blocked |
| Prefetch | `HKLM:\...\PrefetchParameters` | `EnablePrefetcher` | 3 (All) | Prefetch altered or disabled |

---

## Event Log Queries

| Description | Log | Event ID | Forensic Relevance |
|------------|-----|----------|-------------------|
| USN Journal Clear | Application | 3079 | Indicates journal deletion (anti-forensic) |
| Log Clear | System | 104, 1102 | Indicates event log purging |
| System Shutdown | System | 1074 | Tracks unexpected or forced restarts |
| Time Change | Security | 4616 | Indicates system time manipulation |
| Service Start | System | 6005 | Confirms EventLog service initialized |

---

## Technical Details

- **Language:** PowerShell 5.1
- **Service Query:** `[System.ServiceProcess.ServiceController]::GetServices()` (.NET)
- **WMI:** `Get-CimInstance` for system, processor, memory, and disk info
- **Registry:** Direct `.NET` registry access via `[Microsoft.Win32.Registry]`
- **Event Logs:** `Get-WinEvent` with `FilterXPath` for precise event filtering
- **File System:** `[System.IO.Directory]::GetFiles()` and `Get-ChildItem -Force`
- **Encoding:** UTF8 with BOM
- **Admin Detection:** `WindowsPrincipal.IsInRole(Administrator)`
- **Script Size:** ~320 lines
- **Output:** Color-coded console with retro-style ASCII header

---

## Notes

- **Must be run as Administrator** — almost all sections require elevated access
- The script is read-only — it does not modify any registry settings, services, or files
- If a service has a dynamic name (like `CDPUserSvc_<random>`), the script auto-detects the real name using wildcard matching
- The BAM service status is inferred from its registry `Start` value (2 = auto-start, 3 = manual) since `ServiceController` may not report it accurately on some systems
- Prefetch and Recycle Bin data sizes depend on system usage — higher values are normal on long-running systems
- PSReadline history being "Inoperable or Not Used" is normal for systems where PowerShell history isn't configured
- Box-drawing characters in the admin warning banner require a console font that supports Unicode (Consolas, Lucida Console, or Cascadia Code)
