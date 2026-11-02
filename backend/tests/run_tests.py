import os
import sys
import asyncio

# Setup paths and environment
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
os.environ["TESTING"] = "1"

from app.security.ssrf_validator import ssrf_validator, SSRFSecurityError, validate_url_security, sanitize_filename
from app.services.ad_filter_service import ad_filter_service
from app.services.analyzer_service import analyzer_service
from app.database.db import SessionLocal, init_db
from app.main import root
from app.api.endpoints import check_health, get_browser_integration_status, get_settings, update_settings, analyze_webpage
from app.models.schemas import AnalyzeRequest


def run_analyzer_tests():
    print("--- Running Analyzer & Security Tests ---")
    
    # 1. SSRF blocks private IPs
    for url in ["http://127.0.0.1/test", "http://localhost/admin", "http://192.168.1.1/test"]:
        valid, err = validate_url_security(url)
        assert not valid, f"Expected {url} to be blocked by SSRF, but got valid"
    print("PASS: SSRF private IP blocking")

    # 2. Filename sanitization
    assert sanitize_filename("../../malicious.exe") == "malicious.exe"
    assert sanitize_filename("CON.txt") == "file_CON.txt"
    assert sanitize_filename("NUL") == "file_NUL"
    assert sanitize_filename("normal_download.iso") == "normal_download.iso"
    print("PASS: Filename sanitization")

    # 3. Ad filter blocklist
    for ad_url in [
        "https://googleads.g.doubleclick.net/pagead/id",
        "https://pagead2.googlesyndication.com/ads.js",
        "https://ib.adnxs.com/getuid"
    ]:
        assert ad_filter_service.is_ad_or_tracker(ad_url) is True
    print("PASS: Ad filter blocklist")

    # 4. Ad filter allowlist
    for legit_url in [
        "https://github.com/torvalds/linux/archive/refs/tags/v6.1.tar.gz",
        "https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso"
    ]:
        assert ad_filter_service.is_ad_or_tracker(legit_url) is False
    print("PASS: Ad filter allowlist")

    # 5. Ad filter param stripping
    dirty = "https://example.com/file.zip?utm_source=twitter&keep=val"
    cleaned = ad_filter_service.strip_tracking_params(dirty)
    assert "utm_source" not in cleaned
    assert "keep=val" in cleaned
    print("PASS: Tracking param stripping")

    # 6. HTML extraction
    html_sample = """
    <html>
      <body>
        <a href="https://example.com/files/app.zip" download>Download App</a>
        <a href="https://googleads.g.doubleclick.net/ad">Ad</a>
      </body>
    </html>
    """
    candidates = analyzer_service.extract_candidates(html_sample, "https://example.com/test")
    urls = [c["url"] for c in candidates]
    assert "https://example.com/files/app.zip" in urls
    assert "https://googleads.g.doubleclick.net/ad" not in urls
    print("PASS: HTML candidate extraction and ad filtering")


async def run_api_tests():
    print("\n--- Running API Endpoints Tests ---")
    init_db()

    # 1. Root
    r = await root()
    assert r["app"] == "NetPulse Download Manager"
    assert r["status"] == "online"
    print("PASS: GET /")

    # 2. Health
    h = await check_health()
    assert h.status == "ok"
    assert h.version == "1.0.0"
    print("PASS: GET /api/health")

    # 3. Settings
    db = SessionLocal()
    try:
        s = await get_settings(db)
        assert "max_concurrent_downloads" in s.settings
        print("PASS: GET /api/settings")

        up = await update_settings({"test_prop": "test_val"}, db)
        assert up["status"] == "updated"
        s2 = await get_settings(db)
        assert s2.settings.get("test_prop") == "test_val"
        print("PASS: PUT /api/settings")

        # 4. Browser status
        bs = await get_browser_integration_status(db)
        assert bs["is_ready"] is True
        print("PASS: GET /api/browser/status")

        # 5. Analyze endpoint SSRF protection
        req = AnalyzeRequest(url="http://127.0.0.1:8000/private")
        an_res = await analyze_webpage(req, db)
        assert an_res.status == "error"
        assert "security check failed" in an_res.error_message.lower()
        print("PASS: POST /api/analyze (SSRF defense verified)")

    finally:
        db.close()


if __name__ == "__main__":
    run_analyzer_tests()
    asyncio.run(run_api_tests())
    print("\n=== ALL BACKEND TESTS PASSED SUCCESSFULLY! ===")

