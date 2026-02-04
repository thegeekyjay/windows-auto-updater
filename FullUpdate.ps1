# --- Parameters ---
param (
    [switch]$Force
)

# --- Settings ---
$ErrorActionPreference = "Stop"
$StartTime = Get-Date

# --- Daily Skip Check ---
$StateDir = "C:\Scripts\State"
if (!(Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir | Out-Null }

$StateFile = "$StateDir\LastRun.txt"
$Today = (Get-Date).ToString("dd-MMM-yy")

if (Test-Path $StateFile) {
    $LastRun = Get-Content $StateFile -ErrorAction SilentlyContinue
    
    # Check if we should skip: Only skip if it ran today AND -Force was NOT used
    if ($LastRun -eq $Today -and -not $Force) {
        Import-Module BurntToast
        New-BurntToastNotification -Text "Update Script", "Skipped — already ran today ($Today)"
        exit
    }
    elseif ($Force) {
        Write-Host "Force flag detected. Bypassing daily skip check." -ForegroundColor Cyan
    }
}

# Update last run date
$Today | Out-File $StateFile -Force


# --- Logging Setup ---
$LogDir = "C:\Scripts\Logs"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir | Out-Null }

# Delete logs older than 30 days
Get-ChildItem $LogDir -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Force

$Date = Get-Date -Format "dd-MMM-yy"
$LogFile = "$LogDir\UpdateLog-$Date.txt"

Start-Transcript -Path $LogFile -Append


# --- Begin Update Process ---
Write-Host "Starting update process on $Today"
$Summary = @()


# --- Winget Updates ---
Write-Host "Running winget updates..."
$Summary += "Winget updates started."
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements --include-unknown
$Summary += "Winget updates completed."


# --- Microsoft Store Updates ---
Write-Host "Running Microsoft Store updates..."
$Summary += "Store updates started."
# Note: Ensure 'store' is a valid alias/executable on your system (e.g., from WinGet or a specific module)
store updates --apply
$Summary += "Store updates completed."


# --- Windows Updates ---
Write-Host "Running Windows Updates..."
$Summary += "Windows Update scan started."
Import-Module PSWindowsUpdate
Get-WindowsUpdate -AcceptAll -Download | Out-Null
Install-WindowsUpdate -AcceptAll -AutoReboot | Out-Null
$Summary += "Windows Update installation completed."


# --- Summary Output ---
Write-Host "`n--- Update Summary ---"
$Summary | ForEach-Object { Write-Host $_ }


# --- Check Restore Point ---
Write-Host "`nChecking for restore point created during updates..."
$RestorePoints = Get-ComputerRestorePoint | Where-Object { $_.CreationTime -gt $StartTime }
if ($RestorePoints) {
    Write-Host "Restore point found: $($RestorePoints[0].Description) created at $($RestorePoints[0].CreationTime)"
} else {
    Write-Host "No restore point created during the update process."
}


# --- End Logging ---
Stop-Transcript


# --- Completion Notification ---
Import-Module BurntToast
New-BurntToastNotification -Text "Update Script", "Updates completed successfully on $Today"