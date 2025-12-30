<p align="left">
  <img src="assets/banner-dark.png" width="65%" />
</p>

# Windows Auto Updater

A modern automation tool with a retro soul — keep your Windows system and apps updated automatically with a small, configurable PowerShell utility.

[![Latest Release](https://img.shields.io/github/v/release/thegeekyjay/windows-auto-updater?color=blue&style=flat-square)](https://github.com/thegeekyjay/windows-auto-updater/releases)
[![CI Status](https://img.shields.io/github/actions/workflow/status/thegeekyjay/windows-auto-updater/powershell-ci.yml?style=flat-square&label=CI)](https://github.com/thegeekyjay/windows-auto-updater/actions)
[![License](https://img.shields.io/github/license/thegeekyjay/windows-auto-updater?style=flat-square)](https://github.com/thegeekyjay/windows-auto-updater/blob/main/LICENSE)
[![Last Commit](https://img.shields.io/github/last-commit/thegeekyjay/windows-auto-updater?style=flat-square)](https://github.com/thegeekyjay/windows-auto-updater/commits/main)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue?style=flat-square)](https://github.com/PowerShell/PowerShell)

---

## Table of Contents

- [About](#about)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Scheduling (Task Scheduler)](#scheduling-task-scheduler)
- [Logging & Troubleshooting](#logging--troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## About

Windows Auto Updater automates common update tasks on Windows:

- Update winget packages
- Update Microsoft Store apps
- Install Windows Updates
- Log progress and errors
- Run unattended via Task Scheduler

It is built with modern PowerShell but ships with a playful retro-inspired branding — practical and fun.

---

## Features

- Fully automated winget package updates
- Automated Microsoft Store app updates
- Automated Windows Update installation (optional / configurable)
- Clean, timestamped logging
- Dry-run mode for testing
- Designed to run under Task Scheduler or as a one-off script
- Error handling and basic retry logic

---

## Prerequisites

- Windows 10 / Windows 11
- PowerShell 5.1+ (PowerShell Core also supported where applicable)
- winget (App Installer) for package management
- Optional: Windows Store & Microsoft Store CLI / module (for Store app updates)
- Administrative privileges are required for Windows Update and some package installations

---

## Installation

1. Download or clone the repository:

   ```powershell
   git clone https://github.com/thegeekyjay/windows-auto-updater.git
   cd windows-auto-updater
   ```

2. Inspect configuration (see Configuration section) and adjust as needed.

3. Run the script as Administrator:

   ```powershell
   # Example (replace with actual script name if different)
   Start-Process -FilePath powershell -Verb runAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File .\WindowsAutoUpdater.ps1'
   ```

Notes:
- You may prefer to use a CI/packaging workflow or a scheduled task rather than manual runs.
- If your environment restricts script execution, use `-ExecutionPolicy Bypass` or configure an appropriate execution policy.

---

## Usage

Basic invocation:

```powershell
# Run updates now (default behavior)
.\WindowsAutoUpdater.ps1

# Dry-run: show what would happen without making changes
.\WindowsAutoUpdater.ps1 -DryRun

# Verbose logging
.\WindowsAutoUpdater.ps1 -Verbose

# Specify custom config path
.\WindowsAutoUpdater.ps1 -ConfigPath ".\config\updater-config.json"
```

Available parameters (examples — adjust to actual script's parameter names):
- `-DryRun` — simulate actions without performing changes
- `-ConfigPath <path>` — path to configuration file
- `-LogPath <path>` — override the default log file location
- `-Force` — force reinstall/upgrade where supported

(If you expose other CLI parameters in your script, list them here for users.)

---

## Configuration

Provide a simple JSON (or PowerShell hash) config file to control behavior. Example JSON:

```json
{
  "UpdateWinget": true,
  "UpdateStoreApps": true,
  "InstallWindowsUpdates": false,
  "RebootIfRequired": false,
  "ExcludedPackages": [
    "some-package-id"
  ],
  "LogDirectory": "C:\\ProgramData\\WindowsAutoUpdater\\Logs"
}
```

Tips:
- Keep RebootIfRequired off when using interactive machines; enable for servers or dedicated endpoints.
- Use ExcludedPackages to skip known-bad upgrades or packages that require manual interaction.

---

## Scheduling (Task Scheduler)

To automate runs, create a scheduled task that runs as SYSTEM or an administrative user.

Example: register a scheduled task that runs daily at 3:00 AM (run with highest privileges):

```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `\"C:\path\to\WindowsAutoUpdater.ps1`\""
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "Windows Auto Updater" -Action $action -Trigger $trigger -Principal $principal
```

Alternatively, create the task via Task Scheduler GUI. Make sure the account you use has required privileges to install updates.

---

## Logging & Troubleshooting

- Logs are written to the configured LogDirectory (default: ProgramData path). Each run should create a timestamped log file.
- Look for error entries and stacktraces in the log to identify failing steps.
- Common issues:
  - winget not installed or out-of-date — install App Installer from Microsoft Store.
  - Permissions — run with an account that has administrative rights.
  - Store updates may require a signed-in Microsoft account or additional modules — see the Troubleshooting section below.

Troubleshooting steps:
1. Run with `-DryRun` and `-Verbose` to see planned actions.
2. Re-run failing commands manually in an elevated PowerShell prompt to capture additional context.
3. Share log excerpts when opening issues — include timestamps and full error messages.

---

## FAQ

Q: Will this reboot my machine?
A: Only if configured (`RebootIfRequired`) or if a particular update demands it. Default behavior is conservative.

Q: Can I exclude specific packages?
A: Yes — use `ExcludedPackages` in the config to skip items.

Q: Does this run on multiple machines?
A: Yes — you can deploy via management systems (SCCM, Intune) or as a scheduled task across endpoints.

---

## Contributing

Contributions are welcome! A suggested workflow:

1. Fork the repo
2. Create a feature branch
3. Open a PR with a clear description and tests (if applicable)
4. Follow existing coding style and include documentation updates for behavioral changes

Please open issues for bugs or feature requests and tag them appropriately.

---

## License

This project is licensed under the MIT License — see the [LICENSE](https://github.com/thegeekyjay/windows-auto-updater/blob/main/LICENSE) file for details.

---

## Acknowledgements

- Built with PowerShell
- Thanks to the winget and App Installer teams
- Retro-inspired artwork and badges by the project author

---

Changelog and release notes are available on the [releases page](https://github.com/thegeekyjay/windows-auto-updater/releases).
