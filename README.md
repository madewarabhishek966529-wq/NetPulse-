# NetPulse — Advanced High-Speed Download Manager
### *Download Smarter. Download Faster.*

<div align="center">

![NetPulse Logo](assets/icons/logo.png)

*Production-ready, intelligent desktop download accelerator and website resource analyzer for Windows 10 & Windows 11.*

[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011%20x64-00E5FF.svg?style=flat-square)](#)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-0066FF.svg?style=flat-square&logo=flutter)](#)
[![Backend](https://img.shields.io/badge/Backend-FastAPI%20Python%203.12-009688.svg?style=flat-square&logo=fastapi)](#)
[![Engine](https://img.shields.io/badge/Engine-aria2c%201.37.0-7C4DFF.svg?style=flat-square)](#)
[![Database](https://img.shields.io/badge/Database-SQLite%20WAL-00E676.svg?style=flat-square&logo=sqlite)](#)
[![License](https://img.shields.io/badge/License-BSD--3--Clause-blue.svg?style=flat-square)](#)

</div>

---

## 🚀 Overview

**NetPulse** is an enterprise-grade Windows download manager combining three core pillars:
1. **Smart Website URL Analyzer**: Intelligently inspects publicly accessible webpages, discovers legitimate downloadable files (videos, archives, executables, disk images, documents), and automatically shields users by filtering known advertising and tracking networks without breaking genuine downloads.
2. **High-Speed Acceleration Engine**: Powered by the hardened, C++ multi-connection `aria2c` engine over authenticated JSON-RPC with dynamic port binding, zero-allocation disk writes, and hardened BitTorrent/Magnet peer-discovery.
3. **Seamless Browser Integration**: Native Manifest V3 extensions for Google Chrome and Microsoft Edge with one-click context menus (*"Download with NetPulse"*, *"Analyze page with NetPulse"*) connecting directly to the local backend.

The entire NetPulse system launches seamlessly with a single command:
```powershell
.\run_netpulse.ps1
```

---

## ✨ Key Capabilities

- **Smart Website URL Analyzer**:
  - Scrapes publicly accessible webpage URLs to discover downloadable media and packages.
  - Multi-layer SSRF validation blocking loopback (`127.0.0.0/8`, `::1`), private RFC 1918 ranges, and link-local cloud metadata addresses.
  - Conservative ad-filter blocklist eliminating intrusive ad-network links and tracking parameters (`utm_*`, `gclid`, `fbclid`).
  - High-confidence content-disposition and range-support detection.

- **Intelligent Multi-Connection Acceleration**:
  - Splits supported files into up to 16 concurrent segmented streams.
  - Automatic fallback to single-connection streams when servers do not support range requests.
  - Eliminates Windows memory-mapped file truncation errors (`errorCode=17`) via zero-allocation disk writing.

- **Hardened BitTorrent & Magnet Swarm Engine**:
  - Full `.torrent` and magnet link P2P acceleration.
  - Dynamic public tracker auto-configuration and isolated DHT routing table cache preventing deserializer crashes.
  - Real-time peer metrics (active seeders, peer count, swarm health).
  - Atomic magnet metadata-to-payload child GID migration.

- **Queue Management & Scheduling**:
  - Configurable concurrency thresholds (e.g. 1 to 10 active tasks).
  - Priority-weighted queue processing (High > Normal > Low).
  - Off-peak download scheduling.

- **Chrome & Edge Browser Integration**:
  - Manifest V3 extension communicating directly via authenticated HTTP REST API with Native Messaging fallback.
  - Context menu shortcuts and configurable extension auto-interception.

- **Security & Integrity Verification**:
  - Multi-layer SSRF validation and path traversal sanitization.
  - Windows reserved DOS device name protection (`CON`, `PRN`, `AUX`, `NUL`, etc.).
  - Streaming SHA-256 and MD5 cryptographic checksum validator.
  - Strict compliance: never bypasses DRM, paywalls, CAPTCHAs, or copyright protections.

---

## 🛠️ Technology Stack

| Component | Technology | Role |
|---|---|---|
| **Desktop Frontend** | Flutter Desktop (Dart 3.13) | Material 3 futuristic desktop UI, telemetry, and state |
| **Core Backend** | Python 3.12 + FastAPI + Uvicorn | Smart URL Analyzer, SSRF validator, ad-filter, REST API |
| **Download Engine** | aria2c 1.37.0 (Official C++ Windows build) | High-speed segmented downloading and BitTorrent engine |
| **Storage** | SQLite (WAL mode) + SQLAlchemy | Thread-safe, crash-resilient metadata and history database |
| **Browser Extension** | Chrome & Edge Manifest V3 | Right-click context menus & automated interception |
| **Packaging** | Inno Setup 6 + PowerShell | Complete Windows 10/11 installer and launch scripts |

---

## ⚡ Quick Start

### 1. One-Command Setup
To verify and install all dependencies (Python backend, Flutter packages, firewall rules, and browser messaging):
```powershell
.\setup.ps1
```

### 2. One-Command Launch
To start the entire NetPulse system (FastAPI backend + aria2c engine + Flutter desktop UI):
```powershell
.\run_netpulse.ps1
```

---

## 📂 System Architecture

```
NetPulse/
├── assets/
│   ├── bin/aria2c.exe              # Bundled aria2c Windows x64 binary
│   └── icons/                      # App logos, tray icons, branding
├── backend/
│   ├── app/
│   │   ├── api/endpoints.py        # REST API routes (/api/analyze, /api/downloads, /api/browser)
│   │   ├── database/db.py          # SQLite database configuration & SQLAlchemy models
│   │   ├── models/schemas.py       # Pydantic request and response schemas
│   │   ├── security/ssrf_validator.py # SSRF protection & safe filename sanitization
│   │   ├── services/
│   │   │   ├── ad_filter_service.py   # Ad/tracker domain filter & query param stripper
│   │   │   ├── analyzer_service.py    # Smart Website URL Analyzer
│   │   │   └── aria2_service.py       # aria2 JSON-RPC client
│   │   ├── websocket/manager.py    # Real-time WebSocket connection manager
│   │   └── main.py                 # FastAPI application & lifespan manager
│   ├── tests/                      # Pytest suite (SSRF, ad-filter, analyzer, database CRUD)
│   └── requirements.txt            # Python dependencies
├── browser_extension/
│   ├── chrome/                     # Manifest V3 extension (background.js, popup.html/js)
│   └── native_host/                # Native messaging host scripts & registry installer
├── lib/
│   ├── core/                       # Constants, colors, theme, validators
│   ├── features/
│   │   ├── analyzer/               # Smart Analyzer view and provider
│   │   ├── queue/                  # Download Queue view
│   │   ├── dashboard/              # Speed chart, telemetry, active downloads
│   │   ├── downloads/              # Filterable downloads view & cards
│   │   ├── browser/                # Browser integration view
│   │   ├── history/                # History view
│   │   ├── network/                # Network telemetry view & provider
│   │   ├── settings/               # Application & engine settings
│   │   └── about/                  # About NetPulse view
│   ├── services/
│   │   ├── api/backend_api_client.dart # Dio client connecting Flutter to FastAPI
│   │   ├── aria2/                  # aria2 JSON-RPC client & engine manager
│   │   └── database/               # Local SQLite database service
│   └── main.dart                   # Desktop shell & navigation
├── run_netpulse.ps1                 # Single-command application launcher
├── setup.ps1                       # Automated environment configuration script
├── API_DOCUMENTATION.md            # Complete REST & WebSocket API specification
├── SECURITY.md                     # SSRF defense, ad-filter, and compliance documentation
└── ARCHITECTURE.md                 # In-depth architectural blueprint
```

---

## 🧪 Testing & Verification

Run the automated backend test suite:
```powershell
pytest backend/tests -v
```
All 8 backend tests verify:
- SSRF loopback, private RFC 1918, and link-local IP blocking.
- Safe filename sanitization (DOS reserved device names, path traversal).
- Ad and tracker blocklist filtering and parameter stripping.
- HTML candidate extraction and classification.
- Database CRUD and Pydantic schema serialization.

---

## 📜 License

Distributed under the BSD-3-Clause License. See [`installer/license.txt`](installer/license.txt) for details.  
aria2 is licensed under the GNU General Public License v2.
