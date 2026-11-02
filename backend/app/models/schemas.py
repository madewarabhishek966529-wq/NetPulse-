from typing import List, Optional, Dict
from pydantic import BaseModel, Field


class AnalyzeRequest(BaseModel):
    url: str = Field(..., description="The publicly accessible webpage URL to analyze.")


class DetectedFile(BaseModel):
    filename: str
    file_extension: str
    file_size: int = 0
    content_type: str = "application/octet-stream"
    source_hostname: str
    source_url: str
    final_url: str
    detection_confidence: str = "High"  # High, Medium, Low
    is_direct_download: bool = True
    range_supported: bool = False


class FilteredLink(BaseModel):
    url: str
    hostname: str
    reason: str


class AnalyzeResponse(BaseModel):
    original_url: str
    status: str = "success"  # success, partial, error
    discovered_files: List[DetectedFile] = []
    filtered_links: List[FilteredLink] = []
    total_discovered: int = 0
    total_filtered: int = 0
    error_message: Optional[str] = None


class DownloadCreateRequest(BaseModel):
    url: str
    filename: Optional[str] = None
    destination: Optional[str] = None
    connections: int = 8
    headers: Optional[Dict[str, str]] = None
    is_torrent: bool = False


class DownloadItemResponse(BaseModel):
    id: int
    gid: str
    url: str
    filename: str
    file_size: int = 0
    downloaded_size: int = 0
    speed: int = 0
    status: str = "waiting"
    destination: str
    progress: float = 0.0
    eta_seconds: Optional[int] = None
    created_at: Optional[str] = None
    completed_at: Optional[str] = None


class BrowserLinkRequest(BaseModel):
    url: str
    filename: Optional[str] = None
    referrer: Optional[str] = None
    source: str = "chrome"


class SettingItem(BaseModel):
    key: str
    value: str


class SettingsResponse(BaseModel):
    settings: Dict[str, str]


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
    aria2_connected: bool = False
    aria2_version: Optional[str] = None

