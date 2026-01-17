# -------------------------------------------------
# Custom Cursor Installer - UwU scheme
# -------------------------------------------------
# 1) Copies cursor files from .\Cursor (script directory) to:
#    C:\Windows\Cursors\MyCustomCursors
# 2) Updates Registry to apply them
# 3) Forces a refresh so the cursors apply immediately
# -------------------------------------------------

[CmdletBinding()]
param(
    # Keep old behavior: open Mouse Control Panel by default
    [switch]$OpenControlPanel = $true
)

$ErrorActionPreference = "Stop"

# [0] Admin check (README says admin required, so fail fast)
# -------------------------------------------------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error "Run PowerShell as Administrator."
    exit 1
}

# [1] Copy cursor files
# -------------------------------------------------
$sourceFolder = Join-Path $PSScriptRoot "Cursor"
$targetFolder = "C:\Windows\Cursors\MyCustomCursors"

if (-not (Test-Path $sourceFolder)) {
    Write-Error "Source folder not found: $sourceFolder"
    exit 1
}

if (-Not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder | Out-Null
}

Write-Host "Copying cursors from $sourceFolder to $targetFolder..."
Copy-Item -Path (Join-Path $sourceFolder "*") -Destination $targetFolder -Force

# [2] Map cursors and set Registry values
# -------------------------------------------------
$cursorMappings = @{
    "Arrow"       = (Join-Path $targetFolder "1 Normal Select.ani")
    "Help"        = (Join-Path $targetFolder "2 Help Select.ani")
    "AppStarting" = (Join-Path $targetFolder "3 Working in Background.ani")
    "Wait"        = (Join-Path $targetFolder "4 Busy.ani")
    "Crosshair"   = (Join-Path $targetFolder "5 Precision Select.ani")
    "IBeam"       = (Join-Path $targetFolder "6 Text Select.ani")
    "NWPen"       = (Join-Path $targetFolder "7 Handwriting.ani")
    "No"          = (Join-Path $targetFolder "8 Unavailable.ani")
    "SizeNS"      = (Join-Path $targetFolder "9 Vertical Resize.ani")
    "SizeWE"      = (Join-Path $targetFolder "10 Horizontal Resize.ani")
    "SizeNWSE"    = (Join-Path $targetFolder "11 Diagonal Resize 1.ani")
    "SizeNESW"    = (Join-Path $targetFolder "12 Diagonal Resize 2.ani")
    "SizeAll"     = (Join-Path $targetFolder "13 Move.ani")
    "UpArrow"     = (Join-Path $targetFolder "14 Alternate Select.ani")
    "Hand"        = (Join-Path $targetFolder "15 Link Select.ani")
    "Pin"         = (Join-Path $targetFolder "16 pin.ani")
    "Person"      = (Join-Path $targetFolder "17 person.ani")
}

# Validate files exist BEFORE touching registry
$missing = foreach ($k in $cursorMappings.Keys) {
    if (-not (Test-Path $cursorMappings[$k])) { "$k -> $($cursorMappings[$k])" }
}
if ($missing) {
    Write-Error "Missing cursor files:`n$($missing -join "`n")"
    exit 1
}

Write-Host "Setting system cursor paths..."
foreach ($cursor in $cursorMappings.Keys) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name $cursor -Value $cursorMappings[$cursor]
}

# [3] Create and save the "UwU" scheme
# -------------------------------------------------
Write-Host "Creating the 'UwU' scheme..."
$schemePath = "HKCU:\Control Panel\Cursors\Schemes"
if (-Not (Test-Path $schemePath)) {
    New-Item -Path $schemePath -Force | Out-Null
}

# WYCZYŚĆ STARY WPIS (żeby Windows nie trzymał starego, zepsutego stringa)
Remove-ItemProperty -Path $schemePath -Name "UwU" -ErrorAction SilentlyContinue

# Windows expects a specific order of these 17 entries
$order = @(
    "Arrow","Help","AppStarting","Wait","Crosshair","IBeam","NWPen","No",
    "SizeNS","SizeWE","SizeNWSE","SizeNESW","SizeAll","UpArrow","Hand","Pin","Person"
)

# IMPORTANT: Do NOT quote paths in Schemes value. Windows may treat quotes as part of the path.
$schemeValue = ($order | ForEach-Object { $cursorMappings[$_] }) -join ","
Set-ItemProperty -Path $schemePath -Name "UwU" -Value $schemeValue

# Set active scheme to "UwU" (use reg.exe for default value reliability)
Write-Host "Activating the 'UwU' scheme..."
reg.exe add "HKCU\Control Panel\Cursors" /ve /d "UwU" /f | Out-Null

# [4] Re-sync with the UI (safer)
# -------------------------------------------------
Write-Host "Synchronizing cursor settings again..."
foreach ($cursor in $cursorMappings.Keys) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name $cursor -Value $cursorMappings[$cursor]
}

# [5] Refresh settings – multiple variants
# -------------------------------------------------
Write-Host "Refreshing cursor settings (rundll32)..."
Rundll32.exe user32.dll, UpdatePerUserSystemParameters

# Stronger refresh via P/Invoke SPI_SETCURSORS
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class NativeMethods {
    [DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);

    public static bool RefreshCursors() {
        // SPI_SETCURSORS = 0x57
        // SPIF_SENDWININICHANGE = 0x02
        return SystemParametersInfo(0x57, 0, null, 0x02);
    }
}
"@ | Out-Null

Write-Host "Refreshing cursor settings (SPI_SETCURSORS)..."
[NativeMethods]::RefreshCursors() | Out-Null

# Optional: open Mouse Control Panel
if ($OpenControlPanel) {
    Write-Host "Opening Control Panel (optional)..."
    Start-Process "rundll32.exe" -ArgumentList "shell32.dll,Control_RunDLL main.cpl @0,1"
}

# [6] Final message
# -------------------------------------------------
Write-Host "All done! The 'UwU' scheme is now active."
Write-Host "Note: Windows might still show '(None)' in Control Panel"
Write-Host "      even though it's using the 'UwU' scheme."
