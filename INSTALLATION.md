# NetPulse Installation & Deployment Guide
**Target Platform:** Windows 10 & Windows 11 (x64)

---

## 💻 System Requirements

- **Operating System:** Windows 10 (Build 19041+) or Windows 11 x64
- **Processor:** Intel Core i3 / AMD Ryzen 3 or higher
- **Memory:** Minimum 2 GB RAM (4 GB recommended for gigabit transfers)
- **Runtime Dependencies:**
  - Python 3.10+ (for Smart URL Analyzer backend)
  - Flutter SDK 3.47+ (for development builds)
  - `assets/bin/aria2c.exe` (bundled Windows x64 binary)

---

## ⚡ Method 1: Single-Command Automated Setup (Recommended)

NetPulse includes an automated setup script that configures Python dependencies, Flutter packages, Windows Firewall rules, and browser native messaging in one step:

```powershell
.\setup.ps1
```

Once setup completes, launch the entire application with:
```powershell
.\run_netpulse.ps1
```

---

## 📦 Method 2: Windows Installer (.exe)

1. Run the Inno Setup executable:
   ```
   dist\NetPulse-Setup.exe
   ```
2. Accept the EULA and choose installation destination (defaults to `%ProgramFiles%\NetPulse`).
3. Select additional tasks:
   - [x] Create a Desktop shortcut
   - [x] Register browser integration (Chrome, Edge)
4. Click **Install**.
5. Once complete, check **Launch NetPulse** and click **Finish**.

---

## 🌐 Method 3: Browser Extension Installation

NetPulse includes Manifest V3 extensions for Google Chrome and Microsoft Edge.

### Step 1: Install Extension in Google Chrome
1. Open Google Chrome.
2. In the address bar, type `chrome://extensions` and press Enter.
3. In the top-right corner, toggle **Developer mode** to ON.
4. Click the **Load unpacked** button in the top-left toolbar.
5. In the folder browser, select:
   ```
   <NetPulse_Directory>\browser_extension\chrome
   ```
6. The **NetPulse Download Manager Integration** icon will appear in your browser toolbar.

### Step 2: Install Extension in Microsoft Edge
1. Open Microsoft Edge.
2. In the address bar, type `edge://extensions` and press Enter.
3. In the left navigation menu, enable **Developer mode**.
4. Click the **Load unpacked** button.
5. Select the `<NetPulse_Directory>\browser_extension\chrome` directory.

### Step 3: Verify Integration
- Click the NetPulse icon in your browser toolbar. The status badge will show **Connected** (`127.0.0.1:8000`).
- Right-click any downloadable link or media to test **"Download with NetPulse"**.
- Right-click anywhere on a webpage to test **"Analyze page with NetPulse"**.

---

## 🛠️ Verification & Testing

To verify all components are fully operational:

1. **Test Backend & Analyzer:**
   ```powershell
   pytest backend/tests -v
   ```
2. **Test Download Engine:**
   ```powershell
   .\assets\bin\aria2c.exe --version
   ```
3. **Launch NetPulse:**
   ```powershell
   .\run_netpulse.ps1
   ```
