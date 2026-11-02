# NETPULSE: PRODUCT REQUIREMENTS DOCUMENT (PRD) FOR FEATURE TESTING
**Product Name:** NetPulse (Windows Desktop & Browser Extension)  
**Document Type:** Feature Verification & QA Acceptance Test Specification  
**Document Version:** 1.0.0  
**Target Platform:** Windows 10 & Windows 11 (x64)  
**Target Release:** Production Release 1.0.0  
**Engines & Core Services:** Flutter Desktop (Dart 3.13), Python 3.12 (FastAPI), aria2c 1.37.0, SQLite (WAL mode), Chrome/Edge Manifest V3

---

## 1. Executive Summary & Purpose

The purpose of this Product Requirements Document (PRD) is to provide an exhaustive, reproducible, and verifiable testing specification for all features installed and integrated into **NetPulse**.

This document covers functional, security, networking, performance, UI/UX, and end-to-end integration test cases across all eight system pillars:
1. **Smart Website URL Analyzer**
2. **Browser Extension Integration (Chrome & Edge MV3)**
3. **High-Speed Multi-Connection HTTP/HTTPS Download Engine**
4. **Hardened BitTorrent & Magnet Link Swarm Engine**
5. **Download Queue Management & Automated Scheduler**
6. **Streaming Cryptographic File Integrity Verification**
7. **Desktop User Interface, Navigation & Telemetry**
8. **Single-Command Launch, Setup & Windows Packaging**

---

## 2. Test Environment & System Requirements

| Parameter | Minimum Requirement | Verified Test Target |
|---|---|---|
| **Operating System** | Windows 10 (Build 19041+) x64 | Windows 11 Pro 64-bit |
| **Python Runtime** | Python 3.10+ | Python 3.12.10 |
| **Backend Stack** | FastAPI 0.115+, Uvicorn, HTTPX, BeautifulSoup4, SQLAlchemy | Verified in `backend/requirements.txt` |
| **Flutter / Dart** | Flutter 3.47+, Dart 3.13+ | Flutter Desktop Windows x64 |
| **Download Engine** | aria2c 1.37.0 Windows x64 | `assets\bin\aria2c.exe` |
| **Storage Engine** | SQLite (WAL journal mode) | Local workspace `.netpulse_data/` & SQLite FFI |
| **Browsers Supported** | Chromium-based | Google Chrome 120+, Microsoft Edge 120+ |

---

## 3. Master Feature Inventory & Test Matrix

| ID | Feature Domain | Test Coverage Scope | Severity | Status |
|---|---|---|---|---|
| **TS-01** | Smart URL Analyzer | Link discovery, media scraping, ad-blocking, SSRF validation, header probing | Critical | Ready for QA |
| **TS-02** | Browser Integration | Extension popup, context menus, download interception, HTTP REST & Native bridge | Critical | Ready for QA |
| **TS-03** | Multi-Connection Engine | Segmented HTTP downloading, range requests, zero-allocation disk writes | Critical | Ready for QA |
| **TS-04** | BitTorrent Swarm Engine | .torrent files, magnets, metadata resolution, DHT routing table, seed metrics | Critical | Ready for QA |
| **TS-05** | Queue & Scheduler | Concurrency limits (1-10), priority queue, off-peak timed triggers | High | Ready for QA |
| **TS-06** | File Integrity & Security | Streaming SHA-256 / MD5 checksums, dangerous file warnings, path traversal | High | Ready for QA |
| **TS-07** | UI & Live Telemetry | 8 sidebar views, live 60s speed chart, dark/light theme, system tray | Medium | Ready for QA |
| **TS-08** | Packaging & Startup | `run_netpulse.ps1`, `setup.ps1`, Inno Setup installer, health check loop | High | Ready for QA |

---

## 4. Detailed Test Suites & Step-by-Step Test Cases

### TS-01: Smart Website URL Analyzer

#### TC-ANA-001: Webpage Media & File Scraping
- **Objective:** Verify that analyzing a legitimate webpage correctly identifies downloadable files.
- **Preconditions:** NetPulse backend is running on `127.0.0.1:8000`.
- **Test Steps:**
  1. Open NetPulse desktop app and navigate to **Smart Analyzer**.
  2. Input target URL: `https://releases.ubuntu.com/24.04/`.
  3. Click **Analyze Page**.
- **Expected Results:**
  - Progress indicator displays live steps: *"Connecting to server..."*, *"Filtering tracking networks..."*.
  - Discovered files list displays `ubuntu-24.04-desktop-amd64.iso` with correct file size (~6 GB) and extension badge `ISO`.
  - Detection confidence is marked as **High**.
  - Range support is detected and labeled as **Multi-Thread Accelerated**.

#### TC-ANA-002: Server-Side Request Forgery (SSRF) Defense
- **Objective:** Ensure the analyzer strictly rejects private subnets, loopback interfaces, and cloud metadata endpoints.
- **Preconditions:** Backend is running.
- **Test Steps:**
  1. Submit the following URLs sequentially:
     - `http://127.0.0.1:8000/api/settings` (Loopback)
     - `http://localhost:3000` (Localhost hostname)
     - `http://192.168.1.1/router.html` (RFC 1918 Private Subnet)
     - `http://10.0.0.1/admin` (RFC 1918 Private Subnet)
     - `http://169.254.169.254/latest/meta-data/` (AWS/Cloud Link-Local Metadata)
     - `file:///C:/Windows/System32/cmd.exe` (Invalid Scheme)
- **Expected Results:**
  - Every request is rejected immediately before making network calls.
  - The API returns HTTP 200 with `status: "error"` and message: *"Security check failed: Destination IP falls within prohibited internal/private network"*.
  - No internal network probe is attempted.

#### TC-ANA-003: Advertisement & Telemetry Filtering
- **Objective:** Verify that intrusive advertising and tracking URLs are filtered and displayed in the blocked accordion.
- **Test Steps:**
  1. Input a webpage containing ad-scripts and affiliate links (e.g. synthetic test or portal with ad banners).
  2. Observe the analyzer output.
- **Expected Results:**
  - Ad domains (`doubleclick.net`, `adnxs.com`, `googlesyndication.com`, etc.) are eliminated from the discovered files list.
  - Tracking query parameters (`utm_source`, `gclid`, `fbclid`) are stripped from legitimate URLs.
  - Filtered items appear under **"Blocked Advertisements & Trackers"** with specific reasons.

#### TC-ANA-004: Content-Disposition & Filename Sanitization
- **Objective:** Verify that filenames extracted from HTTP headers are sanitized against path traversal and Windows reserved DOS device names.
- **Test Steps:**
  1. Provide URLs returning headers:
     - `Content-Disposition: attachment; filename="../../evil.exe"`
     - `Content-Disposition: attachment; filename="CON.txt"`
     - `Content-Disposition: attachment; filename="NUL.iso"`
- **Expected Results:**
  - Filename `../../evil.exe` is sanitized to `evil.exe`.
  - Filename `CON.txt` is sanitized to `file_CON.txt`.
  - Filename `NUL.iso` is sanitized to `file_NUL.iso`.
  - File is saved safely to `%USERPROFILE%\Downloads` without Win32 handle collision.

---

### TS-02: Browser Extension Integration (Chrome & Edge)

#### TC-BRW-001: Unpacked Extension Installation
- **Objective:** Verify that the extension loads cleanly in Chrome and Edge developer modes.
- **Test Steps:**
  1. Open Chrome (`chrome://extensions`) and Edge (`edge://extensions`).
  2. Enable **Developer mode**.
  3. Click **Load unpacked** and select `browser_extension/chrome`.
- **Expected Results:**
  - Extension loads with ID and official NetPulse branding icon.
  - Manifest V3 service worker status shows **Active** with 0 errors.

#### TC-BRW-002: Popup Status & Connectivity
- **Objective:** Verify that the extension popup communicates with the NetPulse backend.
- **Test Steps:**
  1. Start the NetPulse backend (`127.0.0.1:8000`).
  2. Click the NetPulse browser extension toolbar icon.
- **Expected Results:**
  - Status indicator displays green dot with label **Connected**.
  - Footer displays: *"FastAPI Core v1.0.0 Connected"*.
  - Interception toggle switch is enabled by default.

#### TC-BRW-003: Context Menu "Download with NetPulse"
- **Objective:** Verify that right-clicking a downloadable link forwards it immediately to NetPulse.
- **Test Steps:**
  1. In Chrome/Edge, navigate to any site hosting a downloadable file (e.g., Python or Linux ISO).
  2. Right-click the download link and select **Download with NetPulse**.
- **Expected Results:**
  - Browser displays a native toast notification: *"Forwarded to NetPulse: <filename>"*.
  - NetPulse desktop application adds the download to the active downloads queue immediately.
  - aria2 initiates segmented download.

#### TC-BRW-004: Context Menu "Analyze page with NetPulse"
- **Objective:** Verify that right-clicking any webpage forwards the page URL for analysis.
- **Test Steps:**
  1. Right-click any article or repository page in Chrome/Edge.
  2. Select **Analyze page with NetPulse**.
- **Expected Results:**
  - Extension toast notification displays: *"NetPulse Smart Analyzer: Analyzing webpage..."*.
  - Upon completion, a notification displays the count of discovered files and filtered ads.

#### TC-BRW-005: Automatic Download Interception
- **Objective:** Verify user-initiated browser downloads matching configured extensions (.exe, .iso, .zip) are intercepted.
- **Test Steps:**
  1. Ensure **Automatic Interception** is enabled in the NetPulse popup.
  2. Click a direct `.zip` or `.iso` download link in the browser.
- **Expected Results:**
  - The default browser download is cancelled and erased from browser download history.
  - The transfer is handed over to NetPulse for accelerated multi-connection downloading.

---

### TS-03: High-Speed Multi-Connection Download Engine

#### TC-ENG-001: Multi-Segment Acceleration (HTTP Range)
- **Objective:** Verify that servers supporting byte ranges are downloaded with up to 16 concurrent segmented streams.
- **Test Steps:**
  1. Add a direct download from a high-bandwidth server (e.g. `https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso`).
  2. Set connections to `8` or `16`.
  3. Click **Start Download**.
- **Expected Results:**
  - `aria2.tellStatus` reports `split: "16"` and `connections: 16`.
  - File is written concurrently without corruption.
  - Throughput achieves line-rate fiber/broadband capacity.

#### TC-ENG-002: Windows File Truncation Failure Elimination (`errorCode=17`)
- **Objective:** Verify that Windows disk allocation never crashes with `AbstractDiskWriter.cc:496 errorCode=17`.
- **Test Steps:**
  1. Start a download exceeding 4 GB on an NTFS drive.
  2. Inspect aria2 debug log (`--log-level=debug`).
- **Expected Results:**
  - Log confirms `--file-allocation=none` is active.
  - No preallocation lock fails; download starts immediately at 0% and progresses smoothly.

#### TC-ENG-003: Pause, Resume, and Crash Recovery
- **Objective:** Verify partial chunk persistence across pauses and app restarts.
- **Test Steps:**
  1. Start a 1 GB download.
  2. Allow it to reach 30%.
  3. Click **Pause**. Verify speed drops to 0 and status becomes **Paused**.
  4. Force kill NetPulse or restart the computer.
  5. Relaunch NetPulse and click **Resume**.
- **Expected Results:**
  - aria2 reads the existing `.aria2` control file.
  - Transfer resumes from 30% without re-downloading previously completed chunks.

---

### TS-04: Hardened BitTorrent & Magnet Swarm Engine

#### TC-TOR-001: Legal `.torrent` File Execution
- **Objective:** Verify that `.torrent` files load and download with active swarm connections.
- **Test Steps:**
  1. Download the official legal Ubuntu 24.04 Desktop ISO `.torrent` file.
  2. Open NetPulse > click **+ Add Download** > select **Torrent File**.
  3. Choose the `.torrent` file.
- **Expected Results:**
  - Torrent metadata loads instantly (file list, total size ~6 GB).
  - Swarm metrics immediately show connected seeders (>10) and peers (>20).
  - Transfer rate ramps up to maximum peer capacity (>15 MB/s).

#### TC-TOR-002: Magnet Link Swarm Bootstrapping & Child GID Adoption
- **Objective:** Verify that magnet links resolve swarm metadata, retire the metadata GID, and migrate to payload payload GID.
- **Test Steps:**
  1. Add an official Ubuntu desktop magnet URI:  
     `magnet:?xt=urn:btih:65e10fd45e2213d2f9d6575128ff4e7dc27e36ad&dn=ubuntu-24.04-desktop-amd64.iso`
  2. Observe download card status.
- **Expected Results:**
  - Card displays: *"Fetching swarm metadata..."* with spinner.
  - aria2 resolves metadata via DHT/PEX within 10–25 seconds.
  - Upon metadata completion, `followedBy` emits the child payload GID.
  - NetPulse atomically adopts the child GID without creating duplicate items or marking the download complete prematurely at 0%.

#### TC-TOR-003: Corrupt DHT Routing Table Isolation
- **Objective:** Ensure corrupted or 0-byte DHT cache files never crash the aria2 engine.
- **Test Steps:**
  1. Create a 0-byte file at `.netpulse/dht/dht.dat`.
  2. Launch NetPulse.
- **Expected Results:**
  - NetPulse's `_prepareDhtCache()` detects the 0-byte file (<16 bytes) and safely deletes it before launching aria2c.
  - aria2 initializes cleanly without `[DHTRoutingTableDeserializer.cc:82] errorCode=1`.

---

### TS-05: Queue Management & Automated Scheduler

#### TC-QUE-001: Concurrency Threshold Enforcement
- **Objective:** Verify that active transfers do not exceed the user-defined concurrency limit.
- **Test Steps:**
  1. Navigate to **Download Queue**.
  2. Set **Max Simultaneous Downloads** to `2`.
  3. Add 5 distinct downloads.
- **Expected Results:**
  - Exactly 2 downloads enter the **Active** state.
  - The remaining 3 downloads remain in the **Queued / Waiting** state.
  - As soon as download #1 completes, download #3 begins downloading automatically.

#### TC-QUE-002: Automated Scheduler Execution
- **Objective:** Verify that scheduled downloads trigger automatically at the specified time.
- **Test Steps:**
  1. Add a download with **Schedule for later** set to 2 minutes from current clock time.
  2. Observe the download item card status (**Scheduled**).
- **Expected Results:**
  - Background scheduler checks every 30 seconds.
  - At the designated timestamp, the download transitions to **Active** and initiates transfer.

---

### TS-06: File Integrity & Security Verification

#### TC-SEC-001: Streaming SHA-256 Checksum Calculation
- **Objective:** Verify that large files are verified accurately without high RAM consumption.
- **Test Steps:**
  1. In NetPulse, open **File Verification** on a downloaded 4+ GB ISO file.
  2. Paste the publisher's official SHA-256 hash.
  3. Click **Verify Checksum**.
- **Expected Results:**
  - Progress bar reflects streaming disk reads (chunk by chunk).
  - Memory consumption of `netpulse.exe` remains stable (< 80 MB RAM).
  - Calculated hash matches official hash: displays green checkmark **"Integrity Verified"**.

#### TC-SEC-002: Executable Safety Warning Dialog
- **Objective:** Warn users before launching potentially dangerous binary executables.
- **Test Steps:**
  1. Complete a download of an executable (`.exe`, `.msi`, `.bat`, `.ps1`).
  2. Click **Open File**.
- **Expected Results:**
  - A prominent security modal appears: *"Security Confirmation: Executable File Detected"*.
  - User must explicitly click **Run Anyway** to launch.

---

### TS-07: Desktop User Interface, Navigation & Telemetry

#### TC-UI-001: Sidebar Navigation Complete Flow
- **Objective:** Verify that all 8 navigation items open their respective screens smoothly without layout overflow.
- **Test Steps:**
  1. Click each sidebar item sequentially:
     - 1. **Dashboard**
     - 2. **Smart Analyzer**
     - 3. **Downloads**
     - 4. **Download Queue**
     - 5. **Browser Integration**
     - 6. **Download History**
     - 7. **Settings**
     - 8. **About NetPulse**
- **Expected Results:**
  - Every view renders cleanly within 50ms.
  - Active page indicator highlights the selected sidebar row.
  - Zero Flutter RenderFlex overflows or layout errors.

#### TC-UI-002: Live Telemetry Speed Chart
- **Objective:** Verify that the 60-second throughput graph renders live download speeds accurately.
- **Test Steps:**
  1. Start an active download.
  2. Observe the speed chart on the **Dashboard** and **Network Monitor**.
- **Expected Results:**
  - Chart appends a new data point every second up to 60 samples.
  - Y-axis dynamically scales (KB/s, MB/s) according to current throughput.
  - Current speed, 60s average, and session peak metrics match wire transfer speeds.

#### TC-UI-003: System Tray Minimization
- **Objective:** Verify background operation when the window is minimized or closed.
- **Test Steps:**
  1. Start an active download.
  2. Click the window Close (X) button.
- **Expected Results:**
  - Window hides to the Windows System Tray notification area.
  - Download transfers continue at full speed in the background.
  - Double-clicking the NetPulse tray icon restores the window.

---

### TS-08: Single-Command Launch & Deployment Automation

#### TC-DEP-001: One-Command Setup Execution (`setup.ps1`)
- **Objective:** Verify automated environment configuration on a clean Windows machine.
- **Test Steps:**
  1. Open PowerShell and run:
     ```powershell
     .\setup.ps1
     ```
- **Expected Results:**
  - [1/6] Python 3.10+ detected; packages from `backend/requirements.txt` installed.
  - [2/6] `assets\bin\aria2c.exe` located and verified.
  - [3/6] Inbound Windows Firewall rule configured for aria2c.
  - [4/6] Flutter pub packages retrieved.
  - [5/6] Native messaging keys written to `HKCU:\Software\Google\Chrome` and `Edge`.
  - [6/6] Automated backend tests execute and report 100% pass.

#### TC-DEP-002: Single-Command Application Launch (`run_netpulse.ps1`)
- **Objective:** Verify that the entire desktop system launches with one command.
- **Test Steps:**
  1. Run:
     ```powershell
     .\run_netpulse.ps1
     ```
- **Expected Results:**
  - [1/5] Orphaned aria2c processes terminated.
  - [2/5] Runtime environment validated.
  - [3/5] FastAPI backend starts on `127.0.0.1:8000`.
  - [4/5] Health check confirms status `ok` within 2 seconds.
  - [5/5] Flutter desktop UI opens immediately.
  - Upon closing the terminal or pressing Ctrl+C, background backend and aria2c processes are cleanly stopped.

#### TC-DEP-003: Inno Setup Windows Installer (`installer/netpulse.iss`)
- **Objective:** Verify that the Inno Setup script compiles a standalone release installer.
- **Test Steps:**
  1. Compile `installer/netpulse.iss` using Inno Setup 6.
  2. Run the generated installer on a secondary test machine.
- **Expected Results:**
  - Installer copies `netpulse.exe`, `backend/`, `assets/bin/aria2c.exe`, and browser extensions.
  - Creates Desktop and Start Menu shortcuts.
  - Registers browser integration registry keys.
  - Application launches and downloads successfully on first run.

---

## 5. Automated Regression Test Execution Guide

To run the automated test suites from the command line:

### 1. Backend Security, Ad-Filter & API Tests:
```powershell
pytest backend/tests -v
```
**Expected Output:**
```text
backend/tests/test_analyzer.py::test_ssrf_blocks_private_ips PASSED      [ 12%]
backend/tests/test_analyzer.py::test_filename_sanitization PASSED        [ 25%]
backend/tests/test_analyzer.py::test_ad_filter_blocks_known_ad_domains PASSED [ 37%]
backend/tests/test_analyzer.py::test_ad_filter_allows_legitimate_domains PASSED [ 50%]
backend/tests/test_analyzer.py::test_ad_filter_strips_tracking_params PASSED [ 62%]
backend/tests/test_analyzer.py::test_analyzer_on_synthetic_html PASSED   [ 75%]
backend/tests/test_api.py::test_schema_validations PASSED                [ 87%]
backend/tests/test_api.py::test_database_crud PASSED                     [100%]
8 passed in < 1.5s
```

### 2. Frontend Flutter Unit & Integration Tests:
```powershell
flutter test
```

---

## 6. QA Acceptance Criteria & Sign-Off Checklist

A build is certified for production deployment only when:
- [x] **Zero High/Critical Defects:** All 8 test suites pass without crashes, unhandled exceptions, or socket leaks.
- [x] **SSRF Defense Verified:** 100% of tested private/loopback/cloud metadata URLs are blocked before network dispatch.
- [x] **Windows Truncation Error (`errorCode=17`) Eliminated:** `--file-allocation=none` verified across all task maps.
- [x] **BitTorrent Swarm Stability:** Magnet links consistently resolve metadata and adopt child payload GIDs within 30s.
- [x] **Single-Command Launch Reliability:** `.\run_netpulse.ps1` reliably starts the FastAPI backend, aria2c, and the desktop UI.
- [x] **Extension Integration:** Chrome and Edge extensions capture user-initiated downloads and trigger URL analysis without registry failures.

