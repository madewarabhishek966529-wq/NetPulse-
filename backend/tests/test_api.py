import pytest
from app.models.schemas import (
    AnalyzeRequest,
    AnalyzeResponse,
    DetectedFile,
    FilteredLink,
    DownloadCreateRequest,
    DownloadItemResponse,
    BrowserLinkRequest,
    SettingsResponse,
    HealthResponse,
)
from app.database.db import (
    SessionLocal,
    init_db,
    DownloadRecord,
    DownloadHistoryRecord,
    SettingRecord,
    BrowserEventRecord,
    AnalyzerHistoryRecord,
)


def test_schema_validations():
    # AnalyzeRequest
    req = AnalyzeRequest(url="https://example.com/download.iso")
    assert req.url == "https://example.com/download.iso"

    # DetectedFile
    df = DetectedFile(
        filename="ubuntu.iso",
        file_extension="ISO",
        file_size=1024000,
        content_type="application/x-iso9660-image",
        source_hostname="ubuntu.com",
        source_url="https://ubuntu.com/download",
        final_url="https://releases.ubuntu.com/ubuntu.iso",
        detection_confidence="High",
        is_direct_download=True,
        range_supported=True,
    )
    assert df.filename == "ubuntu.iso"
    assert df.file_size == 1024000
    assert df.range_supported is True

    # HealthResponse
    hr = HealthResponse(status="ok", version="1.0.0", aria2_connected=True, aria2_version="1.37.0")
    assert hr.status == "ok"
    assert hr.aria2_version == "1.37.0"


def test_database_crud():
    init_db()
    db = SessionLocal()
    try:
        # Settings CRUD
        s = SettingRecord(key="test_speed_limit", value="1000000")
        db.add(s)
        db.commit()

        queried_s = db.query(SettingRecord).filter(SettingRecord.key == "test_speed_limit").first()
        assert queried_s is not None
        assert queried_s.value == "1000000"

        # DownloadRecord CRUD
        dl = DownloadRecord(
            gid="test_gid_12345",
            url="https://example.com/test.zip",
            filename="test.zip",
            file_size=50000,
            status="active",
            destination="C:/Downloads",
        )
        db.add(dl)
        db.commit()

        queried_dl = db.query(DownloadRecord).filter(DownloadRecord.gid == "test_gid_12345").first()
        assert queried_dl is not None
        assert queried_dl.filename == "test.zip"
        assert queried_dl.status == "active"

        # BrowserEventRecord
        be = BrowserEventRecord(
            source="chrome",
            url="https://example.com/intercepted.exe",
            status="received",
        )
        db.add(be)
        db.commit()

        queried_be = db.query(BrowserEventRecord).filter(BrowserEventRecord.url == "https://example.com/intercepted.exe").first()
        assert queried_be is not None
        assert queried_be.source == "chrome"

    finally:
        db.close()
