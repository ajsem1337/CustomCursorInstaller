# -------------------------------------------------
# This script sets the "UwU" cursor scheme by:
# 1) Copying cursor files from the "Cursor" folder
#    (in the same directory as the script) to
#    "C:\Windows\Cursors\MyCustomCursors"
# 2) Updating the Registry to apply them
# 3) Forcing a refresh so the cursors apply immediately
# -------------------------------------------------


# [1] Copy cursor files
# -------------------------------------------------
$sourceFolder = "$(Get-Location)\Cursor"
$targetFolder = "C:\Windows\Cursors\MyCustomCursors"

if (-Not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder | Out-Null
}

Write-Host "Copying cursors to $targetFolder..."
Copy-Item -Path "$sourceFolder\*" -Destination $targetFolder -Recurse -Force


# [2] Map cursors and set Registry values
# -------------------------------------------------
$cursorMappings = @{
    "Arrow"       = "$targetFolder\1 Normal Select.ani"
    "Help"        = "$targetFolder\2 Help Select.ani"
    "AppStarting" = "$targetFolder\3 Working in Background.ani"
    "Wait"        = "$targetFolder\4 Busy.ani"
    "Crosshair"   = "$targetFolder\5 Precision Select.ani"
    "IBeam"       = "$targetFolder\6 Text Select.ani"
    "NWPen"       = "$targetFolder\7 Handwriting.ani"
    "No"          = "$targetFolder\8 Unavailable.ani"
    "SizeNS"      = "$targetFolder\9 Vertical Resize.ani"
    "SizeWE"      = "$targetFolder\10 Horizontal Resize.ani"
    "SizeNWSE"    = "$targetFolder\11 Diagonal Resize 1.ani"
    "SizeNESW"    = "$targetFolder\12 Diagonal Resize 2.ani"
    "SizeAll"     = "$targetFolder\13 Move.ani"
    "Hand"        = "$targetFolder\15 Link Select.ani"
    "UpArrow"     = "$targetFolder\14 Alternate Select.ani"
    "Pin"         = "$targetFolder\16 pin.ani"
    "Person"      = "$targetFolder\17 person.ani"
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

# Windows expects a specific order of these 17 entries
$schemeValue = (
    $cursorMappings["Arrow"] + "," +
    $cursorMappings["Help"] + "," +
    $cursorMappings["AppStarting"] + "," +
    $cursorMappings["Wait"] + "," +
    $cursorMappings["Crosshair"] + "," +
    $cursorMappings["IBeam"] + "," +
    $cursorMappings["NWPen"] + "," +
    $cursorMappings["No"] + "," +
    $cursorMappings["SizeNS"] + "," +
    $cursorMappings["SizeWE"] + "," +
    $cursorMappings["SizeNWSE"] + "," +
    $cursorMappings["SizeNESW"] + "," +
    $cursorMappings["SizeAll"] + "," +
    $cursorMappings["UpArrow"] + "," +
    $cursorMappings["Hand"] + "," +
    $cursorMappings["Pin"] + "," +
    $cursorMappings["Person"]
)

Set-ItemProperty -Path $schemePath -Name "UwU" -Value $schemeValue

# Set the active scheme to "UwU"
Write-Host "Activating the 'UwU' scheme..."
Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "(Default)" -Value "UwU"


# [4] Re-sync with the UI (sometimes not necessary, but safer)
# -------------------------------------------------
Write-Host "Synchronizing cursor settings again..."
foreach ($cursor in $cursorMappings.Keys) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name $cursor -Value $cursorMappings[$cursor]
}


# [5] Refresh settings – multiple variants
# -------------------------------------------------
Write-Host "Refreshing cursor settings (rundll32)..."
Rundll32.exe user32.dll, UpdatePerUserSystemParameters

# --- [Optional 1 - But here we keep it active] Stronger refresh via P/Invoke SPI_SETCURSORS ---
# This forces a more thorough system update on some machines
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class NativeMethods {
    [DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
    public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, string pvParam, uint fWinIni);

    public static bool RefreshCursors() {
        // SPI_SETCURSORS = 0x57
        // SPIF_SENDWININICHANGE = 0x02 (sends a system-wide notification)
        return SystemParametersInfo(0x57, 0, null, 0x02);
    }
}
"@

Write-Host "Refreshing cursor settings (SPI_SETCURSORS)..."
[NativeMethods]::RefreshCursors()


# --- [Optional 2] Opening the Mouse Control Panel window ---
# Sometimes just opening the mouse control panel helps Windows 
# notice the new scheme (instead of showing None).
Write-Host "Opening Control Panel (optional)..."
Start-Process "rundll32.exe" -ArgumentList "shell32.dll,Control_RunDLL main.cpl @0,1"

# --- [Optional 3] A short pause and another rundll32, if needed ---
# Start-Sleep -Seconds 3
# Rundll32.exe user32.dll, UpdatePerUserSystemParameters


# [6] Final message
# -------------------------------------------------
Write-Host "All done! The 'UwU' scheme is now active."
Write-Host "Note: Windows might still show '(None)' in Control Panel"
Write-Host "      even though it's using the 'UwU' scheme."
