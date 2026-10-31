# NetPulse Installation Guide

This document provides step-by-step instructions for installing and deploying **NetPulse** on Windows 10 and Windows 11 (x64).

---

## 💻 System Requirements

- **Operating System**: Windows 10 (Build 19041 or higher) or Windows 11 x64
- **Processor**: Intel Core i3 / AMD Ryzen 3 or higher
- **Memory**: Minimum 2 GB RAM (4 GB recommended for gigabit transfers)
- **Disk Space**: 150 MB for application files + adequate storage for downloaded files
- **Network**: Broadband or cellular internet connection

---

## 📦 Method 1: Windows Installer (Recommended)

1. Navigate to the `dist/` directory or download the latest release:
   ```
   dist/NetPulse-Setup.exe
   ```
2. Double-click `NetPulse-Setup.exe` to run the setup wizard.
3. Review and accept the End User License Agreement (EULA).
4. Choose an installation destination (defaults to `%LocalAppData%\Programs\NetPulse` or `C:\Program Files\NetPulse`).
5. Select additional setup tasks:
   - [x] Create a Desktop shortcut
   - [x] Register browser integration (Google Chrome, Microsoft Edge, Mozilla Firefox)
6. Click **Install**.
7. Once installation finishes, check **Launch NetPulse** and click **Finish**.

---

## 🌐 Method 2: Browser Extension Setup

NetPulse includes extensions for Google Chrome, Microsoft Edge, and Mozilla Firefox.

### Step 1: Register Native Messaging Host
To allow browsers to communicate with NetPulse, the Native Messaging Host must be registered in the Windows Registry:

- **Via NetPulse GUI**:
  1. Open NetPulse.
  2. Click **Browser Integration** in the left sidebar.
  3. Click **1-Click Register Native Messaging Host**.
  4. Both Chrome, Edge, and Firefox will show as **Registered**.

- **Via Script**:
  Run `browser_extension\native_host\register_host.bat` as the current user.

### Step 2: Install Extension in Google Chrome
1. Open Google Chrome.
2. In the address bar, type `chrome://extensions` and press Enter.
3. In the top-right corner, toggle **Developer mode** to ON.
4. Click the **Load unpacked** button in the top-left toolbar.
5. In the folder browser, select:
   ```
   <NetPulse_Directory>\browser_extension\chrome
   ```
6. The **NetPulse Download Manager Integration** icon will appear in your browser toolbar.

### Step 3: Install Extension in Microsoft Edge
1. Open Microsoft Edge.
2. Navigate to `edge://extensions`.
3. In the left sidebar, toggle **Developer mode** to ON.
4. Click **Load unpacked** and select:
   ```
   <NetPulse_Directory>\browser_extension\chrome
   ```
5. Click **Add extension**.

### Step 4: Install Extension in Mozilla Firefox
1. Open Firefox.
2. Navigate to `about:debugging#/runtime/this-firefox`.
3. Click **Load Temporary Add-on...**
4. Select `browser_extension\firefox\manifest.json`.

---

## 🛠️ Method 3: Build & Run from Source

For developers modifying or inspecting the codebase:

### Prerequisites:
1. **Flutter SDK**: Version 3.24+ (Dart 3.5+) installed and added to `PATH`.
2. **Visual Studio 2022**: With the "Desktop development with C++" workload installed:
   ```powershell
   winget install Microsoft.VisualStudio.2022.BuildTools --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
   ```
3. **Inno Setup 6** (for building installer packages):
   ```powershell
   winget install JRSoftware.InnoSetup
   ```

### Execution:
1. Clone the repository and navigate to the project directory:
   ```powershell
   cd "Netpulse"
   ```
2. Fetch dependencies:
   ```powershell
   flutter pub get
   ```
3. Run the application:
   ```powershell
   flutter run -d windows
   ```
4. Build release executable:
   ```powershell
   flutter build windows --release
   ```
5. Compile installer:
   ```powershell
   & "C:\Users\<User>\AppData\Local\Programs\Inno Setup 6\ISCC.exe" installer\netpulse.iss
   ```

---

## 🗑️ Uninstallation

- Go to **Windows Settings > Apps > Installed apps**.
- Find **NetPulse** and click **Uninstall**.
- The uninstaller will remove all application binaries, shortcuts, and native messaging registry entries.

