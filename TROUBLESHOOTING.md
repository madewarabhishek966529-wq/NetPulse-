# NetPulse Troubleshooting Guide

This guide covers common issues, root causes, and resolutions when running or developing **NetPulse**.

---

## 🔧 1. Aria2 Engine Issues

### Symptom: `Aria2 process failed to respond to JSON-RPC after 15 attempts`
**Possible Causes & Solutions:**
1. **Port Conflict**: Another application (or an orphaned aria2c process) is using port 6800.
   - NetPulse automatically attempts to find an available port in the range 6800–6850.
   - To terminate orphaned aria2 processes manually:
     ```powershell
     Stop-Process -Name "aria2c" -Force -ErrorAction SilentlyContinue
     ```
2. **Antivirus or Firewall Block**:
   - Ensure your firewall allows localhost loopback communication on `127.0.0.1`. NetPulse does not communicate outside localhost for engine RPC.
3. **Missing `aria2c.exe`**:
   - Verify that `assets\bin\aria2c.exe` exists in your project.
   - Run `assets\bin\aria2c.exe -v` to ensure the executable has execute permissions and runs.

---

## 🛠️ 2. Flutter Windows Compilation Issues

### Symptom: `Unable to find suitable Visual Studio toolchain. Please run flutter doctor for more details.`
**Cause:**
Flutter Windows desktop compilation requires the Microsoft C++ build tools.

**Solution:**
Install Visual Studio 2022 Build Tools with Desktop C++ workload:
```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```
Then restart your terminal and run `flutter doctor`.

---

## 🌐 3. Browser Extension Troubleshooting

### Symptom: Extension popup displays "Offline" or "Disconnected"
**Cause:**
The browser cannot find the Native Messaging Host manifest or Python runtime.

**Solution:**
1. Verify registration in the Windows Registry:
   ```powershell
   reg query "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.netpulse.downloader"
   ```
2. If the key is missing or points to the wrong directory:
   - Run `browser_extension\native_host\register_host.bat`
   - Or open NetPulse > **Browser Integration** > click **1-Click Register Native Messaging Host**.
3. Verify Python is installed and accessible in `PATH`:
   ```powershell
   python --version
   ```

### Symptom: Downloads are not intercepted automatically
**Solution:**
1. Click the NetPulse extension icon in your browser toolbar.
2. Ensure **Automatic Interception** toggle is enabled.
3. Check that the file extension is listed under **Intercepted File Extensions** (e.g. `exe, zip, rar, iso, mp4`).

---

## 💾 4. Download Failures & Recovery

### Symptom: Download shows "Failed" with HTTP 403 (Forbidden)
**Cause:**
The server requires authentication, a temporary token that expired, or dynamic session cookies.

**Solution:**
1. In the Add Download dialog, expand **Advanced Options**.
2. Provide your **HTTP Username** and **HTTP Password** if required.
3. If downloading from a website with session cookies, use the right-click **Download with NetPulse** context menu from the browser extension so cookies are passed automatically.

### Symptom: Resuming download fails with "HTTP 416 (Range Not Satisfiable)"
**Cause:**
The remote server modified the file since the download started, or the server does not support partial byte requests.

**Solution:**
Click the **Restart** button on the download card to re-fetch the file from byte 0.

---

## 🖥️ 5. Windows Defender SmartScreen Notice

### Symptom: "Windows protected your PC" prompt on `NetPulse-Setup.exe`
**Cause:**
Windows Defender SmartScreen flags newly generated executable files until they establish reputation or are digitally signed with an EV Code Signing certificate.

**Solution:**
Click **More info** and select **Run anyway**. NetPulse is completely open-source, contains zero adware, and bundles verified binaries.

