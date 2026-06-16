# 📟 Service Checker

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%7C%207.x-blue?logo=powershell&style=flat-square)](https://microsoft.com/powershell)
[![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey?style=flat-square)](https://www.microsoft.com/windows)
[![Privileges](https://img.shields.io/badge/Privileges-Administrator-red?style=flat-square)](#)

A lightweight, zero-dependency PowerShell diagnostic engine designed for system administrators, power users, and security auditors. Featuring a high-contrast, minimalist retro terminal layout, it bypasses heavy telemetry suites to provide immediate, raw visibility into core Windows environments, registry policies, and forensic artifacts.

---

## ⚡ Core Audits

* 📊 **Hardware Pulse:** Real-time collection of multi-core CPU load and physical RAM consumption metrics.
* ⚙️ **Live Service Matrix:** Dynamic checking of telemetry, tracking, and compatibility infrastructure states.
* 🛑 **Registry Policy Integrity:** Scans for active system restrictions, script block logging status, and environment overrides.
* 🪵 **Event Log Pipeline:** Real-time tracing of high-priority Event IDs (cleared logs, clock tampering, system initializations).
* 📁 **Prefetch Analytics:** Scans `C:\Windows\Prefetch` for hidden object attributes, count anomalies, and locked operational hashes.
* 🗑️ **Storage Forensic Counters:** Recursively enumerates secure user folders inside `$Recycle.Bin` to calculate exact file overhead and true metadata mutation times.

---

## 🖥️ Monitored Subsystems

The script evaluates the security and operational posture of these key Windows components:

| Service / Subsystem | Description | Target State |
| :--- | :--- | :--- |
| `SysMain` / `wsearch` | Performance Monitoring & Indexing Visibility | Operational |
| `DPS` / `PcaSvc` | Diagnostic Policy & Program Compatibility | Operational |
| `BAM` | Background Activity Moderator Driver | Active / Automatic |
| `DiagTrack` | Connected User Experiences & Telemetry | User Defined |
| `PSReadline` | Persistent Console Host Command History Ledger | Audited |

---

## 🚀 Quick Start (One-Line Execution)

### Prerequisites
* Windows 10 / 11 or Windows Server
* PowerShell 5.1+
* **Run as Administrator** is strictly required to access kernel drivers, secure event channels, and protected system folders.

### Execution
Open an elevated PowerShell console and paste the following command to download and execute the latest version directly from the repository in memory:

```powershell```
powershell -ExecutionPolicy Bypass -Command "Invoke-Expression (Invoke-RestMethod '[https://raw.githubusercontent.com/NiccBlahh/ServiceChecker/refs/heads/main/ServiceChecker.ps1](https://raw.githubusercontent.com/NiccBlahh/ServiceChecker/refs/heads/main/ServiceChecker.ps1)')"


@praiselily , forge the code from that Service Checker

