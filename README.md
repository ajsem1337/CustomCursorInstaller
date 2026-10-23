# Custom Cursor Installer

![Made with AI](https://img.shields.io/badge/Made%20with-AI-76ddcf)

A PowerShell installer for the bundled **UwU** animated cursor scheme on Windows.

## Features

- Installs all 17 animated cursors, including Location Select (`pin`) and Person Select (`person`).
- Registers the `UwU` scheme for the current Windows user.
- Reloads cursors immediately, without a restart or sign-out when the refresh succeeds.
- Checks that every required source file exists before copying files or changing the registry.
- Opens Mouse Properties for preview by default; supports running without that window.

## Requirements

- Windows 10 or 11.
- Windows PowerShell 5.1 or PowerShell 7 on Windows.
- Administrator access to copy files into the Windows cursors folder.

Run as Administrator **with the account whose cursors you want to change**. The script writes to `HKEY_CURRENT_USER`; entering another administrator's credentials changes that administrator's settings.

## Installation

1. Download and extract the complete project from [Releases](https://github.com/ajsem1337/CustomCursorInstaller/releases), or clone it:

   ```bash
   git clone https://github.com/ajsem1337/CustomCursorInstaller.git
   ```

2. Keep `InstallCursor.ps1` and the `Cursor/` folder together. Open PowerShell as Administrator and run:

   ```powershell
   cd "C:\path\to\CustomCursorInstaller"
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\InstallCursor.ps1
   ```

   `Bypass` applies to this process. It does not change your saved execution policy.

3. The script installs and activates `UwU`, then opens Mouse Properties on the Pointers tab. Close the window after previewing; no further action is required to activate the scheme.

To install without opening Mouse Properties:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\InstallCursor.ps1 -SkipControlPanel
```

From an existing elevated PowerShell session, `-OpenControlPanel:$false` is also supported:

```powershell
.\InstallCursor.ps1 -OpenControlPanel:$false
```

## What the installer changes

- Copies the 17 bundled files into `%SystemRoot%\Cursors\MyCustomCursors` (usually `C:\Windows\Cursors\MyCustomCursors`). Re-running it overwrites those installed files.
- Saves the scheme in `HKCU\Control Panel\Cursors\Schemes` under `UwU` and replaces an existing scheme of that name.
- Updates the current user's cursor paths, active scheme name, and `Scheme Source` registry value.
- Calls the Windows [`SPI_SETCURSORS` API](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-systemparametersinfow) to reload the cursors and reports a failure if Windows rejects the refresh.

The installer does not back up your previous cursor settings. Save any custom scheme you want to keep in Mouse Properties before running it. Files are installed in a shared Windows folder, while the scheme is selected only for the account running the script.

## Restore or remove

1. Run `main.cpl`, open **Pointers**, select **Windows Default (system scheme)** or your previous scheme, and click **Apply**.
2. To remove the saved scheme, select `UwU` in the same list and click **Delete**, then select the scheme you want to keep.
3. Once no account uses these cursor files, you can delete `%SystemRoot%\Cursors\MyCustomCursors` as Administrator.

## Troubleshooting

- **Missing cursor files:** extract the full download and keep the original filenames in `Cursor/`. The script checks the source even if an older installation exists.
- **Access denied:** run PowerShell as Administrator and check permissions on the destination folder.
- **Scheme saved but refresh failed:** select `UwU` in `main.cpl` and click **Apply**, or sign out and back in.
- **Mouse Properties did not open:** run `main.cpl` manually. A preview-window failure does not undo a successful installation.
- **Another theme changes the cursors:** reselect `UwU` in Mouse Properties.

## Development

The Windows workflow runs the installer twice in the same session using Windows PowerShell 5.1 and PowerShell 7, checks the saved scheme and copied files, and tests an incomplete source folder against an existing installation. Run the same checks locally in an elevated Windows PowerShell session:

```powershell
.\tests\Test-InstallCursor.ps1
```

These are integration tests: they install and activate `UwU` for the account running them. Use a disposable Windows environment for testing.

To check PowerShell syntax, compile the native interop code, and validate the bundled ANI headers without installing anything (also works on Linux with PowerShell 7):

```powershell
.\tests\Test-InstallCursor.ps1 -ValidateOnly
```

## Files

- `InstallCursor.ps1` — installer.
- `Cursor/` — the 17 bundled `.ani` files.
- `tests/Test-InstallCursor.ps1` — Windows integration checks.
- `.github/workflows/windows.yml` — automated Windows checks.

Contributions and bug reports are welcome. Licensed under [MIT](LICENSE).

## AI assistance

**Made with AI.** This project was developed with AI assistance, including code, documentation, and testing.
