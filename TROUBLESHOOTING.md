# NetPulse Troubleshooting Guide
**Platform:** Windows 10 & Windows 11 (x64)

---

## 🔧 1. Download Engine (aria2c) Issues

### Symptom: `AbstractDiskWriter.cc:496 errorCode=17 File truncation failed`
- **Root Cause:** Occurs on Windows NTFS/FAT32 volumes when memory-mapped file handles hold disk blocks while aria2 attempts preallocation.
- **Resolution:** NetPulse sets `--file-allocation=none` across both global configuration and per-download task option maps. Verify that custom options in Settings do not re-enable preallocation.

### Symptom: `Failed to load DHT routing table` or `errorCode=1`
- **Root Cause:** A 0-byte or corrupted `dht.dat` / `dht6.dat` file in the working directory caused the aria2 binary deserializer to abort.
- **Resolution:** NetPulse isolates DHT caches in `.netpulse/dht/` and automatically purges corrupted files smaller than 16 bytes before launching the engine.

### Symptom: Inbound BitTorrent Peer Connections Blocked (Zero Seeds / 0% Speed)
- **Root Cause:** Windows Firewall blocking inbound peer swarm packets on TCP/UDP ports 6881–6999.
- **Resolution:** Run `setup.ps1` or execute the following PowerShell command as Administrator:
  ```powershell
  netsh advfirewall firewall add rule name="NetPulse Torrent Engine" dir=in action=allow program="<Path_To_NetPulse>\assets\bin\aria2c.exe" enable=yes
  ```

---

## 🚀 2. FastAPI Backend & Smart URL Analyzer

### Symptom: Backend health check times out during launch (`run_netpulse.ps1`)
- **Possible Causes & Solutions:**
  1. **Port 8000 Conflict:** Another service (e.g. dev web server) is occupying port 8000.
     - Check: `netstat -ano | findstr 8000`
     - Terminate the conflicting PID or adjust port in `backend/app/main.py`.
  2. **Missing Python Modules:**
     - Run: `pip install -r backend/requirements.txt`
  3. **Self-Test Verification:**
     - Run: `pytest backend/tests -v`

### Symptom: `Security check failed: Destination IP falls within prohibited network`
- **Explanation:** This is an intentional security safeguard. NetPulse's SSRF validator blocks attempts to analyze internal network endpoints (`127.0.0.1`, `localhost`, `192.168.x.x`, `10.x.x.x`, `169.254.169.254`). Only publicly accessible internet URLs may be analyzed.

---

## 🌐 3. Browser Extension Integration

### Symptom: Extension popup displays "Offline" or "Disconnected"
- **Resolution:**
  1. Verify the NetPulse FastAPI backend is running on `http://127.0.0.1:8000/api/health`.
  2. If using Native Messaging fallback, ensure the Windows Registry key is present:
     ```powershell
     reg query "HKCU\Software\Google\Chrome\NativeMessagingHosts\com.netpulse.downloader"
     ```
  3. To re-register Native Messaging, run `.\setup.ps1`.

---

## 💻 4. Process Cleanup & Reset

To completely stop all NetPulse background daemons and reset locks:
```powershell
Stop-Process -Name "aria2c" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "python" -Force -ErrorAction SilentlyContinue
```
Then restart cleanly with:
```powershell
.\run_netpulse.ps1
```
