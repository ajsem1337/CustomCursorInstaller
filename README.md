# Custom Cursor Installer

A PowerShell script to automate the installation of custom cursors on Windows.

## Features

- Copies cursor files to the appropriate system folder.
- Creates and saves a new cursor scheme in the Windows registry.
- Sets the new cursor scheme as active.
- Forces system settings to refresh.

## Requirements

- Windows 10/11.
- PowerShell running as Administrator.

## Installation

1. **Clone the repository:**

   Download the repository using:

   ```bash
   git clone https://github.com/ajsem1337/CustomCursorInstaller.git
   ```

2. **Run the script:**

   Open PowerShell as Administrator, navigate to the folder where the script is located, and run:

   ```bash
   cd path\to\CustomCursorSetup
   .\InstallCursor.ps1
   ```

3. **Apply the scheme:**

   After running the script, you may notice that in the mouse settings (Settings > Mouse > Additional mouse settings > Pointers), the scheme is displayed as None. To apply the scheme correctly:
   Select the UwU scheme from the dropdown list and click OK.
   Alternatively, log out and log back in to allow the system to load the new scheme automatically.

Notes

    "Replace Scheme" dialog: If you see a prompt asking whether to overwrite the existing scheme, click Yes.
    Scheme listed as None: After running the script, the scheme might appear as None in the settings, but the cursors are applied correctly. To make it active, select UwU manually from the dropdown.
    Feedback welcome: If you know a way to fully solve the None issue, feel free to share your idea!

Files

    InstallCursor.ps1 – The script that installs the custom cursors.
    Cursor/ – The folder containing .cur and .ani cursor files.
