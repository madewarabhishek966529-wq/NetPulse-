# NetPulse System Architecture Document
**Version:** 1.0.0  
**Target Platform:** Windows 10 & Windows 11 (x64)

---

## 1. High-Level Architecture Overview

NetPulse is built upon a coordinated multi-process architecture engineered for high throughput, memory safety, and responsive UI performance:

```
+-------------------------------------------------------------+
|                 Flutter Desktop Application                 |
|             (Dart 3.13 / Material 3 / Windows x64)          |
|                                                             |
|  - Dashboard View            - Smart Analyzer View          |
|  - Downloads View            - Queue Manager View           |
|  - Network Telemetry         - Settings & History           |
+------------------------------+------------------------------+
                               |
                               | REST API (HTTP) / WebSocket
                               v
+-------------------------------------------------------------+
|                     FastAPI Backend                         |
|                 (Python 3.12 on 127.0.0.1:8000)             |
|                                                             |
|  +-----------------------+     +-------------------------+  |
|  | Smart URL Analyzer    |     | SSRF Security Validator |  |
|  +-----------------------+     +-------------------------+  |
|  | Ad & Tracker Filter   |     | SQLite (WAL Mode) DB    |  |
|  +-----------------------+     +-------------------------+  |
|  | Download Coordinator |     | WebSocket Broadcaster   |  |
|  +-----------------------+     +-------------------------+  |
+------------------------------+------------------------------+
                               |
                               | Authenticated JSON-RPC 2.0
                               v
+-------------------------------------------------------------+
|                    aria2 Download Engine                    |
|             (Official C++ Windows x64 Binary v1.37.0)       |
|                                                             |
|  - Multi-Segment Chunking     - BitTorrent Swarm Engine     |
|  - Zero-Allocation Writing    - DHT / PEX / LPD Discovery   |
+------------------------------+------------------------------+
                               |
                               | Disk I/O & Network
                               v
+-------------------------------------------------------------+
|               Windows File System & Peer Swarm              |
+-------------------------------------------------------------+
```

---

## 2. Component Breakdown

### 2.1 Flutter Desktop Application
- **Role:** Primary user interface, visual telemetry, and task interaction.
- **State Management:** Riverpod / Provider for clean reactivity and low rebuild costs.
- **Communication:** Connects to the local FastAPI backend via `BackendApiClient` (Dio HTTP client) and subscribes to `/ws/downloads` for real-time progress updates.
- **Fail-Safe Operation:** Features local SQLite fallback (`sqflite_common_ffi`) so downloads and UI functionality remain available even if backend services are initializing.

### 2.2 FastAPI Backend Core (`127.0.0.1:8000`)
- **Role:** Coordinates URL analysis, advertisement filtering, security validation, and task queuing.
- **Smart Website URL Analyzer:** Uses `HTTPX` (async) and `BeautifulSoup4` with `lxml` to parse webpage markup, extract candidate downloadable files from anchors, media tags, and Open Graph metadata, inspects headers with concurrent HEAD/GET range requests, and computes confidence scores.
- **Ad & Tracker Shield:** Conservative domain blocklist eliminating intrusive advertising destinations and tracking parameters (`utm_*`, `gclid`, `fbclid`).
- **SSRF Defense:** Prevents requests to internal RFC 1918 subnets, loopback addresses, link-local metadata services, and Windows reserved DOS device names.
- **Database Engine:** SQLAlchemy ORM with SQLite in Write-Ahead Logging (WAL) mode for fast, non-blocking concurrent reads and writes.

### 2.3 aria2c Download Engine (`v1.37.0`)
- **Role:** High-speed wire data transfer, connection pooling, and BitTorrent P2P swarming.
- **Dynamic Port & Secret:** Configures a secure 32-character hex token and dynamic port binding (6800–6850).
- **Windows Disk Optimization:** Strictly sets `--file-allocation=none` to eliminate Windows memory-mapped file truncation failures (`errorCode=17`).
- **BitTorrent Hardening:** Isolated `.netpulse/dht/` directory preventing corrupt 0-byte deserializer crashes, dynamic public announce trackers, and child GID adoption for magnet links.

### 2.4 Browser Extension (Chrome & Edge)
- **Role:** Seamless one-click capture of downloads from web browsing sessions.
- **Architecture:** Chrome Manifest V3 service worker sending downloads and analysis requests directly to `http://127.0.0.1:8000/api/browser/link` with automatic fallback to Windows Native Messaging (`com.netpulse.downloader`).

---

## 3. Data Flow Workflows

### 3.1 Smart URL Analysis Workflow
1. User pastes a webpage URL in the NetPulse Smart Analyzer screen (or selects "Analyze page with NetPulse" in Chrome/Edge).
2. `BackendApiClient` dispatches `POST /api/analyze`.
3. `ssrf_validator.py` resolves DNS and verifies the target IP does not resolve to loopback, private RFC 1918, or cloud metadata addresses.
4. `analyzer_service.py` fetches the HTML document using an async HTTPX client with realistic browser headers.
5. `bs4` parses all candidate anchors, audio/video elements, and metadata tags.
6. `ad_filter_service.py` checks domains against the ad blocklist and strips tracking parameters.
7. Discovered download candidates are probed using concurrent HEAD requests (semaphore-controlled) to check `Content-Type`, `Content-Length`, `Content-Disposition`, and `Accept-Ranges`.
8. NetPulse UI renders discovered file cards with format badges, file size, hostname, and an immediate "Download" action button.

### 3.2 High-Speed Download Workflow
1. User clicks "Download" on a discovered resource or adds a direct URL/torrent/magnet link.
2. The download request is submitted to `aria2c` via `aria2.addUri` or `aria2.addTorrent`.
3. aria2 opens up to 16 concurrent segmented HTTP connections or connects to the BitTorrent DHT swarm.
4. Background polling loop queries active GIDs and broadcasts live transfer statistics (download speed, completed bytes, total size, ETA) over WebSocket `/ws/downloads`.
5. Flutter updates real-time speed charts and download item cards.
6. Upon transfer completion, metadata is finalized in SQLite and desktop notifications are displayed.

---

## 4. Single-Command Lifecycle Management
The entire system lifecycle is managed by `run_netpulse.ps1`:
1. Cleanly terminates any orphaned `aria2c` processes.
2. Verifies Python 3.10+ and packages.
3. Launches FastAPI backend in the background.
4. Polls `/api/health` until online.
5. Launches the Flutter Windows desktop UI.
6. Catches termination signals and gracefully halts the backend and aria2c daemon.
