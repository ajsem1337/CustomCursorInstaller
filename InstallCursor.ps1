#Requires -Version 5.1
<#
.SYNOPSIS
Installs and activates the bundled UwU cursor scheme for the current user.
.EXAMPLE
.\InstallCursor.ps1 -SkipControlPanel
#>
[CmdletBinding()]
param(
    # Preserve compatibility with callers using -OpenControlPanel:$false.
    [switch]$OpenControlPanel = $true,
    [switch]$SkipControlPanel
)

$ErrorActionPreference = 'Stop'

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This installer requires Windows.'
}

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    throw 'Run PowerShell as Administrator using the Windows account whose cursors you want to change.'
}

$sourceFolder = Join-Path $PSScriptRoot 'Cursor'
$targetFolder = Join-Path $env:SystemRoot 'Cursors\MyCustomCursors'
$cursorKey = 'HKCU:\Control Panel\Cursors'
$schemeKey = Join-Path $cursorKey 'Schemes'
$schemeName = 'UwU'

# Windows stores schemes as a comma-separated list in this exact order.
$cursorFiles = [ordered]@{
    Arrow       = '1 Normal Select.ani'
    Help        = '2 Help Select.ani'
    AppStarting = '3 Working in Background.ani'
    Wait        = '4 Busy.ani'
    Crosshair   = '5 Precision Select.ani'
    IBeam       = '6 Text Select.ani'
    NWPen       = '7 Handwriting.ani'
    No          = '8 Unavailable.ani'
    SizeNS      = '9 Vertical Resize.ani'
    SizeWE      = '10 Horizontal Resize.ani'
    SizeNWSE    = '11 Diagonal Resize 1.ani'
    SizeNESW    = '12 Diagonal Resize 2.ani'
    SizeAll     = '13 Move.ani'
    UpArrow     = '14 Alternate Select.ani'
    Hand        = '15 Link Select.ani'
    Pin         = '16 pin.ani'
    Person      = '17 person.ani'
}

if (-not (Test-Path -LiteralPath $sourceFolder -PathType Container)) {
    throw "Source folder not found: $sourceFolder"
}

# Validate the source before overwriting any installed files. Old destination
# files must not hide an incomplete download.
$missing = foreach ($fileName in $cursorFiles.Values) {
    $sourcePath = Join-Path $sourceFolder $fileName
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        $sourcePath
    }
}
if ($missing) {
    throw "Missing cursor files:`n$($missing -join "`n")"
}

# Compile before changing files or settings. Reuse the type on subsequent runs
# in the same PowerShell session.
if (-not ('CustomCursorInstaller.NativeMethods' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace CustomCursorInstaller {
    public static class NativeMethods {
        [DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", ExactSpelling = true, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SystemParametersInfo(
            uint action, uint parameter, IntPtr value, uint flags);

        public static void RefreshCursors() {
            // SPI_SETCURSORS requires uiParam = 0 and pvParam = NULL.
            if (!SystemParametersInfo(0x57, 0, IntPtr.Zero, 0x02)) {
                throw new Win32Exception(Marshal.GetLastWin32Error());
            }
        }
    }
}
'@
}

Write-Host "Copying cursors to $targetFolder..."
New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
$cursorMappings = [ordered]@{}
foreach ($cursor in $cursorFiles.Keys) {
    $sourcePath = Join-Path $sourceFolder $cursorFiles[$cursor]
    Copy-Item -LiteralPath $sourcePath -Destination $targetFolder -Force
    $cursorMappings[$cursor] = Join-Path $targetFolder $cursorFiles[$cursor]
}

Write-Host "Registering the '$schemeName' scheme..."
# Create keys only when absent; forcing an existing key can erase its values.
foreach ($key in @($cursorKey, $schemeKey)) {
    if (-not (Test-Path -LiteralPath $key)) {
        New-Item -Path $key -Force | Out-Null
    }
}

# Paths containing spaces must remain unquoted inside the scheme string.
$schemeValue = $cursorMappings.Values -join ','
New-ItemProperty -LiteralPath $schemeKey -Name $schemeName -Value $schemeValue -PropertyType String -Force | Out-Null

foreach ($cursor in $cursorMappings.Keys) {
    New-ItemProperty -LiteralPath $cursorKey -Name $cursor -Value $cursorMappings[$cursor] -PropertyType ExpandString -Force | Out-Null
}

# Set the default value and mark this as a user-defined scheme (1).
Set-Item -LiteralPath $cursorKey -Value $schemeName
New-ItemProperty -LiteralPath $cursorKey -Name 'Scheme Source' -Value 1 -PropertyType DWord -Force | Out-Null

Write-Host 'Refreshing cursor settings...'
try {
    [CustomCursorInstaller.NativeMethods]::RefreshCursors()
}
catch {
    throw "The '$schemeName' scheme was saved, but Windows could not refresh the cursors. Select it in Mouse Properties (main.cpl), or sign out and back in. Details: $($_.Exception.Message)"
}

Write-Host "All done! The '$schemeName' scheme is now active for the current user."

if ($OpenControlPanel -and -not $SkipControlPanel) {
    try {
        $rundll32 = Join-Path $env:SystemRoot 'System32\rundll32.exe'
        Start-Process -FilePath $rundll32 -ArgumentList 'shell32.dll,Control_RunDLL main.cpl @0,1'
    }
    catch {
        Write-Warning "The scheme is active, but Mouse Properties could not be opened. Run main.cpl to preview it. Details: $($_.Exception.Message)"
    }
}
