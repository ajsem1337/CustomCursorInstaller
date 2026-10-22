#Requires -Version 5.1
<#
.SYNOPSIS
Checks package integrity, then installs UwU in a disposable Windows environment.
.PARAMETER ValidateOnly
Checks syntax and bundled files without changing Windows settings.
#>
[CmdletBinding()]
param([switch]$ValidateOnly)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$installer = Join-Path $projectRoot 'InstallCursor.ps1'

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($installer, [ref]$tokens, [ref]$parseErrors)
Assert-True ($parseErrors.Count -eq 0) "Installer syntax errors: $parseErrors"

# This order is the Windows scheme format, independent of the installer map.
$roles = @(
    'Arrow', 'Help', 'AppStarting', 'Wait', 'Crosshair', 'IBeam', 'NWPen', 'No',
    'SizeNS', 'SizeWE', 'SizeNWSE', 'SizeNESW', 'SizeAll', 'UpArrow', 'Hand', 'Pin', 'Person'
)
$sourceFolder = Join-Path $projectRoot 'Cursor'
$files = @(Get-ChildItem -LiteralPath $sourceFolder -Filter '*.ani' -File | Sort-Object { [int]($_.Name.Split(' ')[0]) })
Assert-True ($files.Count -eq $roles.Count) 'The package must contain 17 animated cursors.'
for ($i = 0; $i -lt $files.Count; $i++) {
    Assert-True ($files[$i].Name.StartsWith("$($i + 1) ")) 'Cursor numbering must run from 1 to 17.'
    $bytes = [IO.File]::ReadAllBytes($files[$i].FullName)
    Assert-True ($bytes.Length -ge 12) "Truncated cursor: $($files[$i].Name)"
    Assert-True ([Text.Encoding]::ASCII.GetString($bytes, 0, 4) -eq 'RIFF') "Invalid RIFF header: $($files[$i].Name)"
    Assert-True ([Text.Encoding]::ASCII.GetString($bytes, 8, 4) -eq 'ACON') "Invalid ANI header: $($files[$i].Name)"
    Assert-True (([long][BitConverter]::ToUInt32($bytes, 4) + 8) -eq $bytes.Length) "Invalid RIFF length: $($files[$i].Name)"
}

if ($ValidateOnly) {
    # Compile the actual interop declaration without calling Windows APIs.
    $nativeSource = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $node.Value.Contains('namespace CustomCursorInstaller')
    }, $true)
    Assert-True ($null -ne $nativeSource) 'The native interop declaration is missing.'
    if (-not ('CustomCursorInstaller.NativeMethods' -as [type])) {
        Add-Type -TypeDefinition $nativeSource.Value
    }
    Write-Host 'PASS: PowerShell syntax, native interop compilation, and 17 ANI headers.'
    return
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'Integration tests require an elevated, disposable Windows environment. Use -ValidateOnly for package checks.'
}

# Run from a path containing spaces and wildcard characters to exercise literal paths.
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ("Cursor installer [test] " + [guid]::NewGuid())
New-Item -ItemType Directory -Path $testRoot | Out-Null
try {
    Copy-Item -LiteralPath $installer -Destination $testRoot
    Copy-Item -LiteralPath $sourceFolder -Destination $testRoot -Recurse
    $testInstaller = Join-Path $testRoot 'InstallCursor.ps1'
    $targetFolder = Join-Path $env:SystemRoot 'Cursors\MyCustomCursors'
    $cursorKey = 'HKCU:\Control Panel\Cursors'
    $schemeKey = Join-Path $cursorKey 'Schemes'

    & $testInstaller -SkipControlPanel
    # A second invocation must reuse the native type without a compilation error.
    & $testInstaller -OpenControlPanel:$false

    $active = Get-Item -LiteralPath $cursorKey
    $saved = Get-Item -LiteralPath $schemeKey
    Assert-True ($active.GetValue('') -eq 'UwU') 'UwU is not the active scheme.'
    Assert-True ($active.GetValue('Scheme Source') -eq 1) 'The scheme must be user-defined.'
    Assert-True ($active.GetValueKind('Scheme Source') -eq [Microsoft.Win32.RegistryValueKind]::DWord) 'Scheme Source must be a DWORD.'
    Assert-True ($saved.GetValueKind('UwU') -eq [Microsoft.Win32.RegistryValueKind]::String) 'The saved scheme must be a string.'
    $paths = $saved.GetValue('UwU').Split(',')
    Assert-True ($paths.Count -eq 17) 'The scheme must contain 17 paths.'
    for ($i = 0; $i -lt $roles.Count; $i++) {
        $expected = Join-Path $targetFolder $files[$i].Name
        Assert-True ($paths[$i] -eq $expected) "Incorrect scheme order at $($roles[$i])."
        Assert-True ($active.GetValue($roles[$i]) -eq $expected) "Incorrect active path for $($roles[$i])."
        $sourceHash = (Get-FileHash -LiteralPath $files[$i].FullName).Hash
        Assert-True ((Get-FileHash -LiteralPath $expected).Hash -eq $sourceHash) "Copy mismatch: $expected"
    }

    # A missing source must fail even when a previous destination copy exists.
    # Change another source to prove validation happens before any copy occurs.
    $testSource = Join-Path $testRoot 'Cursor'
    Remove-Item -LiteralPath (Join-Path $testSource $files[-1].Name)
    [IO.File]::WriteAllText((Join-Path $testSource $files[0].Name), 'must not be copied')
    $failed = $false
    try {
        & $testInstaller -SkipControlPanel
    }
    catch {
        Assert-True ($_.Exception.Message -like 'Missing cursor files:*') "Unexpected error: $_"
        $failed = $true
    }
    Assert-True $failed 'An incomplete source package was accepted.'
    Assert-True ((Get-FileHash -LiteralPath (Join-Path $targetFolder $files[0].Name)).Hash -eq (Get-FileHash -LiteralPath $files[0].FullName).Hash) 'Source validation overwrote an installed file.'
    Assert-True ((Get-Item -LiteralPath $schemeKey).GetValue('UwU') -eq ($paths -join ',')) 'Source validation changed the saved scheme.'
    Write-Host 'PASS: repeated installation, registry values, scheme order, copied files, literal paths, and incomplete-source rejection.'
}
finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
