# NetPulse — Advanced High-Speed Download Manager

<div align="center">

![NetPulse Logo](assets/icons/logo.png)

### **Download Faster. Stay Connected.**

*Next-generation, production-ready desktop download accelerator and manager for Windows 10 & Windows 11.*

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20x64-00E5FF.svg?style=flat-square)](#)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-0066FF.svg?style=flat-square&logo=flutter)](#)
[![Dart](https://img.shields.io/badge/Dart-3.13.4-00E5FF.svg?style=flat-square&logo=dart)](#)
[![Engine](https://img.shields.io/badge/Engine-aria2c%201.37.0-7C4DFF.svg?style=flat-square)](#)
[![Database](https://img.shields.io/badge/Database-SQLite%20FFI-00E676.svg?style=flat-square&logo=sqlite)](#)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg?style=flat-square)](#)

</div>

---

## 🚀 Overview

**NetPulse** is a high-performance alternative to traditional Windows download utilities. Engineered from the ground up for modern high-bandwidth fiber and 5G connections, NetPulse couples a sleek, glassmorphic Material 3 desktop user interface with the battle-tested, C++ multi-connection **aria2c** download engine over a localhost-isolated JSON-RPC 2.0 communication bus.

NetPulse calculates real download throughput directly from transferred wire bytes, segments files dynamically using HTTP Range requests, automatically resumes interrupted transfers across machine restarts, and seamlessly integrates with Google Chrome, Microsoft Edge, and Mozilla Firefox via Windows Native Messaging.

---

## ✨ Key Capabilities

- **Intelligent Multi-Connection Acceleration**:
  - Dynamically inspects server response headers (`Content-Disposition`, `Content-Length`, `Accept-Ranges`).
  - Automatically splits supported downloads into 2 to 16 concurrent segmented streams.
  - Automatically detects servers without range request support and falls back gracefully to stable single-connection transfers without failure.

- **BitTorrent & Magnet Link P2P Acceleration**:
  - Full support for `.torrent` files with native Windows File Dialog picker (`OpenFileDialog`).
  - Seamless handling of `magnet:?xt=urn:btih:...` links with automatic metadata discovery and payload transition.
  - Integrated Distributed Hash Table (DHT), Local Peer Discovery (LPD), and Peer Exchange (PEX).
  - Pre-configured with 10 high-speed public announce trackers for swift peer and seed discovery.
  - Real-time peer and seeder statistics monitoring (`peers` and `seeds` counts) on download cards.

- **Automated Download Recovery**:
  - Unfinished and in-progress downloads survive application restarts and sudden connection drops.
  - Control metadata and partial chunks are preserved and automatically reconciled on launch.
  - Configurable exponential retry counters and socket connection timeouts.

- **Real-Time Network Telemetry**:
  - Live 60-second throughput line chart powered by `fl_chart`.
  - Precise metrics for current speed, 60s moving average, session peak throughput, and total transferred bytes.
  - Granular bandwidth limits: dynamic global throttle and individual download caps.

- **Native Browser Integration**:
  - Native Messaging host registered with Windows Registry for Google Chrome, Microsoft Edge, and Mozilla Firefox.
  - Automatic interception of downloadable file types (.exe, .zip, .iso, .mp4, etc.).
  - Right-click context menu: *"Download with NetPulse"*.
  - Offline fallback: queued download requests are preserved in LocalAppData and ingested the moment NetPulse launches.

- **Download Scheduler & Priority Queue**:
  - Schedule heavy downloads for off-peak hours (e.g. night downloads at 02:00 AM).
  - Priority-weighted queue processing (High > Normal > Low).
  - Configurable simultaneous transfer thresholds.

- **Security & Integrity Verification**:
  - Built-in streaming SHA-256 and MD5 checksum validator.
  - Live verification progress without loading multi-gigabyte files into RAM.
  - One-click checksum match comparison against publisher hashes.
  - Protective warnings before executing dangerous executable extensions (`.exe`, `.bat`, `.cmd`, `.msi`, `.ps1`).

- **Windows System Tray & Background Operation**:
  - Minimize to system tray on window close.
  - Active transfers continue uninterrupted in the background.

---

## 🛠️ Technology Stack

| Layer | Technology |
|---|---|
| **Frontend Framework** | Flutter Desktop (Windows x64) |
| **Language** | Dart 3.13.4 |
| **Design Language** | Custom Material 3 Futuristic Dark & Light Theme (`#090D16`, `#00E5FF`, `#7C4DFF`) |
| **Engine** | aria2c (v1.37.0) with JSON-RPC 2.0 |
| **Database** | SQLite via `sqflite_common_ffi` |
| **Network Client** | Dio 5.x for URL inspection & headers negotiation |
| **Telemetry & Visuals** | `fl_chart` |
| **Hashing & Security** | `crypto` (SHA-256, MD5) |
| **Browser Bridge** | Native Messaging Host + Manifest V3 Chrome/Edge & Firefox extensions |
| **Packaging** | Inno Setup 6 (`NetPulse-Setup.exe`) |

---

## ⚡ Quick Start

### Option A: Install from Windows Setup Executable
Download and run the installer generated in `dist/`:
```powershell
.\dist\NetPulse-Setup.exe
```

### Option B: Run in Development with One Command
From the project root:
```bash
flutter run -d windows
```
The application will automatically:
1. Locate or extract the bundled `aria2c.exe` background engine.
2. Initialize SQLite persistence (`netpulse.db`).
3. Bind a localhost-only JSON-RPC server with an auto-generated cryptographic token.
4. Reconcile any interrupted or pending downloads.
5. Display the futuristic dashboard with live telemetry.

---

## 📂 Project Architecture

```
NetPulse/
├── assets/
│   ├── bin/aria2c.exe              # Bundled aria2c Windows x64 binary
│   └── icons/                      # App logos, tray icons, splash branding
├── browser_extension/
│   ├── chrome/                     # Chrome & Edge extension (Manifest V3)
│   ├── firefox/                    # Firefox extension (Manifest V2/V3)
│   └── native_host/                # Native messaging host script, manifest, & registry installer
├── dist/
│   └── NetPulse-Setup.exe          # Compiled Windows installer
├── installer/
│   ├── netpulse.iss                # Inno Setup 6 script
│   └── license.txt                 # EULA license
├── lib/
│   ├── core/                       # Constants, categories, errors, formatters, validators, theme
│   ├── features/
│   │   ├── dashboard/              # Stat cards, real-time speed chart, active transfers
│   │   ├── downloads/              # Filterable downloads view, item cards, bulk actions
│   │   ├── add_download/           # Add URL dialog, Dio URL inspector, Range detector
│   │   ├── network/                # Network monitor view & provider
│   │   ├── scheduler/              # Scheduler view & automated priority queue
│   │   ├── browser/                # Browser integration view & 1-click registry setup
│   │   ├── history/                # History view with CSV export
│   │   └── settings/               # General, download, engine, and theme settings
│   ├── services/
│   │   ├── aria2/                  # Aria2Client (JSON-RPC), Aria2EngineManager, Aria2Models
│   │   ├── database/               # SQLite FFI database service
│   │   ├── browser_bridge/         # NativeHostManager & incoming queue file watcher
│   │   ├── file_verification/      # Streaming SHA-256 / MD5 checksum service
│   │   ├── notifications/          # In-app and desktop notifications
│   │   └── system_tray/            # System tray integration
│   ├── models/                     # DownloadItem, DownloadStat, AppSettings, DownloadSegment
│   ├── repositories/               # DownloadRepository coordinating engine & SQLite
│   └── main.dart                   # Application entry point & title bar shell
└── test/
    ├── unit/                       # Unit tests for formatters, validators, categories, DB, checksums
    ├── integration/                # Live aria2 engine JSON-RPC integration test
    └── widget_test.dart            # Flutter widget tests
```

---

## 🧪 Testing

Execute the comprehensive automated test suite:
```bash
flutter test
```
All unit, integration, and widget tests run directly against real application logic and verify:
- Cryptographic hash calculation (SHA-256 and MD5) against known digests.
- Path traversal sanitization and dangerous executable checks.
- SQLite database persistence and model serialization.
- Live aria2 process startup, version detection, `addUri`, `tellStatus`, `pause`, `unpause`, and graceful shutdown.

---

## 📜 License

Distributed under the BSD-3-Clause License. See [`installer/license.txt`](installer/license.txt) for details.
Aria2 is licensed under the GNU General Public License v2.
