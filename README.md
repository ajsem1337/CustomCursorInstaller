# Custom Cursor Installer

A PowerShell script to automate the installation of custom cursors on Windows.

## Features

- Installs custom cursors and applies them automatically.
- Refreshes the cursor scheme without requiring a restart or logout.
- Minimizes unnecessary error pop-ups.
- Includes two new animated cursors: `person.ani` and `pin.ani`.
- Provides a seamless experience when applying the `UwU` cursor scheme.

## Requirements

- PowerShell execution policy must allow running scripts (`ExecutionPolicy Bypass` recommended).
- Windows 10/11.
- PowerShell running as Administrator.

## Installation

1. **Download the files:**

   - Option 1: Download the ZIP from the [Releases](https://github.com/ajsem1337/CustomCursorInstaller/releases).
   - Option 2: Clone the repository using:

     ```bash
     git clone https://github.com/ajsem1337/CustomCursorInstaller.git
     ```

2. **Run the script:**
   Open PowerShell as Administrator, navigate to the folder where the script is located, and run:

   ```powershell
   cd path\to\CustomCursorInstaller
   powershell -ExecutionPolicy Bypass -File .\InstallCursor.ps1
   ```

3. **Automatic scheme application**

The script applies the `UwU` cursor scheme automatically.

No additional user interaction is required.  
The Mouse settings window is opened for preview only.

Do NOT click **OK** or **Apply** — the scheme is already active and clicking these buttons may trigger a Windows prompt to overwrite the current scheme.

## Notes

- **Cursor scheme now refreshes automatically**
  The script forces Windows to apply the new scheme without requiring a logout or reboot.

- **Proper scheme registration**
  The script registers the cursor scheme correctly in the Windows registry, so it appears normally in Mouse settings without showing `None`.

- **Less intrusive error messages**
  The script minimizes unnecessary pop-ups, providing a smoother installation experience.

- **New cursors added**
  The `person.ani` and `pin.ani` cursors were missing in the original pack and have been created and included in this update.

- **Contributions welcome**
  If you have ideas for improving the script, feel free to submit a pull request!

## Files

- `InstallCursor.ps1` – The script that installs the custom cursors.
- `Cursor/` – The folder containing `.ani` cursor files.
