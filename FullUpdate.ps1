# --- Settings ---
$ErrorActionPreference = "Stop"

# --- Daily Skip Check ---
$StateDir = "C:\Scripts\State"
if (!(Test-Path $StateDir)) { New-Item -ItemType Directory -Path $StateDir | Out-Null }

$StateFile = "$StateDir\LastRun.txt"
$Today = (Get-Date).ToString("dd-MMM-yy")

if (Test-Path $StateFile) {
    $LastRun = Get-Content $StateFile -ErrorAction SilentlyContinue
    if ($LastRun -eq $Today) {
        Import-Module BurntToast
        New-BurntToastNotification -Text "Update Script", "Skipped — already ran today ($Today)."
        exit
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
store updates --apply
$Summary += "Store updates completed."


# --- Windows Updates ---
Write-Host "Running Windows Updates..."
$Summary += "Windows Update scan started."
Import-Module PSWindowsUpdate
Get-WindowsUpdate -Verbose
Install-WindowsUpdate -AcceptAll -AutoReboot
$Summary += "Windows Update installation completed."


# --- Summary Output ---
Write-Host "`n--- Update Summary ---"
$Summary | ForEach-Object { Write-Host $_ }


# --- End Logging ---
Stop-Transcript


# --- Completion Notification ---
Import-Module BurntToast
New-BurntToastNotification -Text "Update Script", "Updates completed successfully on $Today."
