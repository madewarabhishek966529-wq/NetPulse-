import pytest
from app.security.ssrf_validator import ssrf_validator, SSRFSecurityError
from app.services.ad_filter_service import ad_filter_service
from app.services.analyzer_service import analyzer_service


def test_ssrf_blocks_private_ips():
    dangerous_urls = [
        "http://127.0.0.1/test",
        "http://localhost/admin",
        "http://192.168.1.50/firmware.bin",
        "http://10.0.0.5/backup.zip",
        "http://169.254.169.254/latest/meta-data/",
        "file:///C:/Windows/win.ini",
        "ftp://example.com/file.zip",
    ]
    for url in dangerous_urls:
        with pytest.raises(SSRFSecurityError):
            ssrf_validator.validate_url(url)


def test_filename_sanitization():
    assert ssrf_validator.sanitize_filename("../../dangerous.exe") == "dangerous.exe"
    assert ssrf_validator.sanitize_filename("CON.txt") == "file_CON.txt"
    assert ssrf_validator.sanitize_filename("NUL") == "file_NUL"
    assert ssrf_validator.sanitize_filename("valid_file_name_1.0.zip") == "valid_file_name_1.0.zip"


def test_ad_filter_blocks_known_ad_domains():
    ad_urls = [
        "https://googleads.g.doubleclick.net/pagead/id",
        "https://pagead2.googlesyndication.com/ads.js",
        "https://ib.adnxs.com/getuid",
        "https://track.adroll.com/pixel",
    ]
    for url in ad_urls:
        assert ad_filter_service.is_ad_or_tracker(url) is True


def test_ad_filter_allows_legitimate_domains():
    legit_urls = [
        "https://github.com/torvalds/linux/archive/refs/tags/v6.1.tar.gz",
        "https://releases.ubuntu.com/24.04/ubuntu-24.04-desktop-amd64.iso",
        "https://media.w3.org/2010/05/sintel/trailer.mp4",
    ]
    for url in legit_urls:
        assert ad_filter_service.is_ad_or_tracker(url) is False


def test_ad_filter_strips_tracking_params():
    dirty_url = "https://example.com/download.zip?utm_source=twitter&utm_medium=social&gclid=12345&keep=this"
    cleaned = ad_filter_service.strip_tracking_params(dirty_url)
    assert "utm_source" not in cleaned
    assert "gclid" not in cleaned
    assert "keep=this" in cleaned


def test_analyzer_on_synthetic_html():
    html_sample = """
    <!DOCTYPE html>
    <html>
      <head><title>Test Download Portal</title></head>
      <body>
        <h1>Downloads</h1>
        <a href="https://example.com/releases/app-v1.0.0.exe" download>Download Desktop App (.exe)</a>
        <a href="https://example.com/videos/tutorial.mp4">Watch Tutorial (.mp4)</a>
        <a href="https://googleads.g.doubleclick.net/ad_link">Sponsored Ad Link</a>
      </body>
    </html>
    """
    candidates = analyzer_service._extract_candidates(html_sample, "https://example.com/downloads")
    
    # Should extract legitimate links and filter ad link
    found_urls = [c["url"] for c in candidates]
    assert "https://example.com/releases/app-v1.0.0.exe" in found_urls
    assert "https://example.com/videos/tutorial.mp4" in found_urls
    assert "https://googleads.g.doubleclick.net/ad_link" not in found_urls
