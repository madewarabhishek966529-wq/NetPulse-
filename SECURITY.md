# NetPulse Security & Compliance Architecture

NetPulse is designed with a defense-in-depth security model to ensure that high-speed URL analysis and download interception never compromise user safety, system integrity, or network security.

---

## 1. Server-Side Request Forgery (SSRF) Defense

Because NetPulse analyzes user-provided webpage URLs and candidate download links, it includes strict, layered SSRF validation implemented in `backend/app/security/ssrf_validator.py`.

### 1.1 Prohibited IP Ranges & Subnets
The following address ranges are strictly blocked from analysis or inspection:
- `127.0.0.0/8` (IPv4 Loopback)
- `::1/128` (IPv6 Loopback)
- `10.0.0.0/8` (Private RFC 1918)
- `172.16.0.0/12` (Private RFC 1918)
- `192.168.0.0/16` (Private RFC 1918)
- `169.254.0.0/16` (Link-Local / Cloud Metadata APIs such as AWS `169.254.169.254`)
- `100.64.0.0/10` (Carrier-Grade NAT)
- `fc00::/7` (IPv6 Unique Local)
- `fe80::/10` (IPv6 Link-Local)
- `224.0.0.0/4` & `ff00::/8` (Multicast)

### 1.2 DNS Resolution & Rebinding Protection
- Hostnames are resolved to IPv4 and IPv6 addresses prior to connecting.
- All resolved addresses are checked against the blocked CIDR list.
- HTTP redirect responses (`301`, `302`, `307`, `308`) must re-validate target hostnames and resolved IPs before following.

### 1.3 Scheme & Protocol Enforcement
- Only `http://` and `https://` schemes are accepted.
- Unsupported schemes (`file://`, `ftp://`, `gopher://`, `data:`, `blob:`, `javascript:`) are rejected immediately.

---

## 2. Windows Filesystem & Path Traversal Protection

User-supplied URLs or `Content-Disposition` HTTP headers cannot be trusted to name local disk files safely. The `sanitize_filename()` routine enforces:

1. **Path Traversal Elimination:** All directory separators (`/`, `\`) and traversal tokens (`../`, `..\`) are stripped; only the terminal basename is retained.
2. **Forbidden Character Sanitization:** Windows invalid filename characters (`<`, `>`, `:`, `"`, `/`, `\`, `|`, `?`, `*`) are replaced with underscores (`_`).
3. **Trailing Characters:** Trailing spaces and dots (`.`), which Windows Explorer forbids or mishandles, are trimmed.
4. **DOS / Windows Device Name Shield:** Reserved DOS device names are prepended with `file_` to prevent Win32 kernel device handle conflicts:
   - `CON`, `PRN`, `AUX`, `NUL`
   - `COM1` through `COM9`
   - `LPT1` through `LPT9`
5. **Length Bounds:** Filenames are truncated to 240 characters to prevent path overflows against Windows `MAX_PATH` (260 characters).

---

## 3. Advertising & Tracking Shield

The Smart Website URL Analyzer isolates legitimate file links from advertising and telemetry scripts using `AdFilterService`:
- **Domain Blocklist:** Blocks known ad-serving domains (`doubleclick.net`, `googleadservices.com`, `googlesyndication.com`, `adnxs.com`, `criteo.com`, `taboola.com`, etc.).
- **URL Parameter Stripping:** Removes tracking query parameters (`utm_source`, `utm_medium`, `utm_campaign`, `gclid`, `fbclid`, `msclkid`, `zanpid`, `yclid`, `_ga`, `_gl`, `ref`, `aff_id`).
- **Path Heuristics:** Detects and excludes explicit advertisement redirection paths (`/ads/`, `/popunder/`, `/clicktag/`).
- **CDN Allowlist:** Preserves legitimate file hosts and software repositories (`github.com`, `releases.ubuntu.com`, `sourceforge.net`, `archive.org`, etc.).

---

## 4. Legal Compliance & Ethics

NetPulse strictly follows ethical and legal download guidelines:
- **No DRM or Paywall Circumvention:** NetPulse does not attempt to bypass digital rights management, content encryption, or paid subscriptions.
- **No Anti-Bot or CAPTCHA Defeat:** NetPulse respects `robots.txt` guidelines and does not defeat CAPTCHA verification systems.
- **Publicly Accessible Content Only:** Only freely accessible resources intended for public download are fetched.

