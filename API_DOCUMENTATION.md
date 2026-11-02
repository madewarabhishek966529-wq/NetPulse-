# NetPulse Core API Documentation
**Version:** 1.0.0  
**Host:** `http://127.0.0.1:8000`  
**WebSocket:** `ws://127.0.0.1:8000/ws/downloads`

---

## 1. Overview
The NetPulse backend runs locally as a high-performance FastAPI service coordinating the Smart Website URL Analyzer, the authenticated aria2 JSON-RPC download engine, SQLite database persistence, and browser extensions (Chrome and Edge).

---

## 2. REST Endpoints

### 2.1 System Health
`GET /api/health`
Returns the operational status of the NetPulse backend and the connected aria2 engine.

**Response:**
```json
{
  "status": "ok",
  "version": "1.0.0",
  "aria2_connected": true,
  "aria2_version": "1.37.0"
}
```

---

### 2.2 Smart Website URL Analyzer
`POST /api/analyze`
Analyzes any publicly accessible webpage URL, extracting direct downloadable files while filtering known advertising and tracking destinations. Protected by multi-layer SSRF validation.

**Request Body:**
```json
{
  "url": "https://releases.ubuntu.com/24.04/"
}
```

**Response (Success):**
```json
{
  "original_url": "https://releases.ubuntu.com/24.04/",
  "status": "success",
  "discovered_files": [
    {
      "filename": "ubuntu-24.04-desktop-amd64.iso",
      "file_extension": "ISO",
      "file_size": 6120329216,
      "content_type": "application/x-iso9660-image",
      "source_hostname": "releases.ubuntu.com",
      "source_url": "https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso",
      "final_url": "https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso",
      "detection_confidence": "High",
      "is_direct_download": true,
      "range_supported": true
    }
  ],
  "filtered_links": [
    {
      "url": "https://googleads.g.doubleclick.net/pagead/id",
      "hostname": "googleads.g.doubleclick.net",
      "reason": "Known advertising/tracking network (doubleclick.net)"
    }
  ],
  "total_discovered": 1,
  "total_filtered": 1,
  "error_message": null
}
```

**Response (SSRF Rejection):**
```json
{
  "original_url": "http://127.0.0.1:8000/admin",
  "status": "error",
  "discovered_files": [],
  "filtered_links": [],
  "total_discovered": 0,
  "total_filtered": 0,
  "error_message": "Security check failed: Destination IP 127.0.0.1 falls within prohibited internal/private network (127.0.0.0/8)."
}
```

---

### 2.3 Download Management
`POST /api/downloads`
Submits a download task directly to aria2.

**Request Body:**
```json
{
  "url": "https://example.com/software.zip",
  "filename": "software.zip",
  "destination": "C:\\Users\\User\\Downloads",
  "connections": 8,
  "is_torrent": false
}
```

`GET /api/downloads`
Lists all active, waiting, and completed downloads with real-time speed and progress statistics.

`GET /api/downloads/{gid}`
Fetches status details for a specific download task.

`POST /api/downloads/{gid}/pause`
Pauses an active download.

`POST /api/downloads/{gid}/resume`
Resumes a paused download.

`POST /api/downloads/{gid}/cancel`
Cancels and removes a download from engine and history.

`POST /api/downloads/{gid}/retry`
Re-submits a failed download task.

---

### 2.4 Browser Extension Integration
`POST /api/browser/link`
Direct HTTP endpoint for Chrome and Edge extensions when user clicks "Download with NetPulse" or download interception triggers.

**Request Body:**
```json
{
  "url": "https://example.com/setup.exe",
  "filename": "setup.exe",
  "referrer": "https://example.com/download-page",
  "source": "chrome"
}
```

`POST /api/browser/analyze`
Triggers page analysis directly from browser context menu.

`GET /api/browser/status`
Returns browser integration status and count of intercepted links.

---

### 2.5 Settings & Configuration
`GET /api/settings`
Returns key-value application settings.

`PUT /api/settings`
Updates key-value settings.

---

## 3. WebSocket Real-Time Stream
`WS /ws/downloads`
Provides a live broadcast channel pushing real-time download ticks and engine events every second.

**Sample Message:**
```json
{
  "event": "download_tick",
  "downloads": [
    {
      "gid": "2089b05e0a3d5014",
      "downloaded_bytes": 104857600,
      "total_bytes": 1048576000,
      "speed_bps": 25165824,
      "progress": 0.1,
      "status": "active"
    }
  ]
}
```

