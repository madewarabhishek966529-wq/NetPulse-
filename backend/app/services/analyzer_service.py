import asyncio
import re
from typing import List, Tuple, Optional
from urllib.parse import urljoin, urlparse

import httpx
from bs4 import BeautifulSoup

from app.security.ssrf_validator import validate_url_security, sanitize_filename
from app.services.ad_filter_service import AdFilterService
from app.models.schemas import DetectedFile, FilteredLink, AnalyzeResponse


# Downloadable file extensions categorized
SUPPORTED_EXTENSIONS = {
    # Video
    "mp4", "mkv", "avi", "mov", "webm", "flv", "wmv", "m4v",
    # Audio
    "mp3", "wav", "flac", "aac", "ogg", "m4a", "wma",
    # Archives & Disk Images
    "zip", "rar", "7z", "tar", "gz", "bz2", "xz", "iso", "img",
    # Documents
    "pdf", "docx", "xlsx", "pptx", "doc", "xls", "ppt", "epub", "csv",
    # Executables & Packages
    "exe", "msi", "apk", "dmg", "pkg", "deb", "rpm", "bin"
}

# Recognized MIME types that indicate downloadable binaries
DOWNLOAD_MIME_PREFIXES = (
    "video/",
    "audio/",
    "application/zip",
    "application/x-rar",
    "application/x-7z",
    "application/x-tar",
    "application/gzip",
    "application/pdf",
    "application/octet-stream",
    "application/x-msdownload",
    "application/vnd.android.package-archive",
    "application/x-iso9660-image",
)

USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36 NetPulse/1.0"


class SmartUrlAnalyzer:
    def __init__(self):
        self.ad_filter = AdFilterService()

    def extract_candidates(self, html_text: str, base_url: str) -> List[dict]:
        """
        Parses HTML and extracts downloadable candidate links, media, and meta tags.
        """
        soup = BeautifulSoup(html_text, "html.parser")
        candidates = []
        for a in soup.find_all("a", href=True):
            raw_href = a["href"].strip()
            if raw_href and not raw_href.startswith(("javascript:", "mailto:", "tel:", "#")):
                abs_url = urljoin(base_url, raw_href)
                if not self.ad_filter.is_ad_or_tracker(abs_url):
                    candidates.append({"url": abs_url, "hint": a.get("download") or a.get_text(strip=True)})

        for media_tag in soup.find_all(["video", "audio", "source"]):
            src = media_tag.get("src")
            if src:
                abs_url = urljoin(base_url, src.strip())
                if not self.ad_filter.is_ad_or_tracker(abs_url):
                    candidates.append({"url": abs_url, "hint": None})

        return candidates

    def _extract_candidates(self, html_text: str, base_url: str) -> List[dict]:
        return self.extract_candidates(html_text, base_url)

    async def analyze(self, page_url: str) -> AnalyzeResponse:
        return await self.analyze_webpage(page_url)

    async def analyze_webpage(self, page_url: str) -> AnalyzeResponse:
        """
        Fetches, inspects, and analyzes a publicly accessible webpage URL to discover
        downloadable files while filtering advertisements and protecting against SSRF.
        """
        # Step 1-3: Security and SSRF validation
        is_safe, error_msg = validate_url_security(page_url)
        if not is_safe:
            return AnalyzeResponse(
                original_url=page_url,
                status="error",
                error_message=f"Security check failed: {error_msg}"
            )

        discovered: List[DetectedFile] = []
        filtered: List[FilteredLink] = []
        candidate_urls: set = set()

        async with httpx.AsyncClient(
            headers={"User-Agent": USER_AGENT},
            follow_redirects=True,
            timeout=15.0,
            verify=True
        ) as client:
            try:
                # Step 4: Fetch page HTML
                response = await client.get(page_url)
                if response.status_code >= 400:
                    return AnalyzeResponse(
                        original_url=page_url,
                        status="error",
                        error_message=f"HTTP server returned status {response.status_code} ({response.reason_phrase})"
                    )

                content_type = response.headers.get("content-type", "").lower()

                # If the URL pasted is DIRECTLY a downloadable file itself
                if any(content_type.startswith(p) for p in DOWNLOAD_MIME_PREFIXES) or "attachment" in response.headers.get("content-disposition", "").lower():
                    direct_file = self._parse_direct_resource(page_url, response.headers)
                    return AnalyzeResponse(
                        original_url=page_url,
                        status="success",
                        discovered_files=[direct_file],
                        total_discovered=1,
                        total_filtered=0
                    )

                # Step 5: Parse HTML
                html_text = response.text
                soup = BeautifulSoup(html_text, "html.parser")

            except httpx.RequestError as e:
                return AnalyzeResponse(
                    original_url=page_url,
                    status="error",
                    error_message=f"Failed to fetch webpage: {str(e)}"
                )

            # Step 6: Extract links and media sources
            base_url = str(response.url)

            # 6a. Anchor tags (href and download attributes)
            for a in soup.find_all("a", href=True):
                raw_href = a["href"].strip()
                if raw_href and not raw_href.startswith(("javascript:", "mailto:", "tel:", "#")):
                    abs_url = urljoin(base_url, raw_href)
                    candidate_urls.add((abs_url, a.get("download") or a.get_text(strip=True)))

            # 6b. Video and audio elements
            for media_tag in soup.find_all(["video", "audio", "source"]):
                src = media_tag.get("src")
                if src:
                    abs_url = urljoin(base_url, src.strip())
                    candidate_urls.add((abs_url, None))

            # 6c. Open Graph media tags
            for meta in soup.find_all("meta", property=re.compile(r"^og:(video|audio)(:secure_url)?$")):
                content = meta.get("content")
                if content:
                    abs_url = urljoin(base_url, content.strip())
                    candidate_urls.add((abs_url, None))

        # Step 7-11: Inspect and filter candidate links
        semaphore = asyncio.Semaphore(8)  # Concurrency control

        async def inspect_candidate(url: str, anchor_hint: Optional[str]):
            # Check ad filter
            should_filter, filter_reason = self.ad_filter.is_filtered(url)
            if should_filter:
                parsed = urlparse(url)
                filtered.append(FilteredLink(url=url, hostname=parsed.hostname or "", reason=filter_reason or "Advertising filter"))
                return

            # Check SSRF on candidate
            is_valid, _ = validate_url_security(url)
            if not is_valid:
                return

            # Pre-filter by file extension if obvious
            parsed = urlparse(url)
            path_ext = parsed.path.split(".")[-1].lower() if "." in parsed.path else ""

            # Check HEAD headers
            async with semaphore:
                try:
                    async with httpx.AsyncClient(
                        headers={"User-Agent": USER_AGENT},
                        follow_redirects=True,
                        timeout=8.0,
                        verify=True
                    ) as check_client:
                        head_res = await check_client.head(url)
                        if head_res.status_code >= 400:
                            return

                        headers = head_res.headers
                        ct = headers.get("content-type", "").lower()
                        cd = headers.get("content-disposition", "")
                        cl = headers.get("content-length")
                        accept_ranges = headers.get("accept-ranges", "").lower() == "bytes"

                        is_downloadable = False
                        confidence = "Low"

                        # Heuristic 1: Explicit attachment header
                        if "attachment" in cd.lower():
                            is_downloadable = True
                            confidence = "High"

                        # Heuristic 2: Known binary MIME type
                        elif any(ct.startswith(prefix) for prefix in DOWNLOAD_MIME_PREFIXES):
                            is_downloadable = True
                            confidence = "High" if path_ext in SUPPORTED_EXTENSIONS else "Medium"

                        # Heuristic 3: Known file extension with non-HTML response
                        elif path_ext in SUPPORTED_EXTENSIONS and "text/html" not in ct:
                            is_downloadable = True
                            confidence = "High"

                        if is_downloadable:
                            filename = self._resolve_filename(url, cd, anchor_hint)
                            size = int(cl) if cl and cl.isdigit() else 0
                            ext = filename.split(".")[-1].lower() if "." in filename else path_ext

                            discovered.append(DetectedFile(
                                filename=filename,
                                file_extension=ext.upper(),
                                file_size=size,
                                content_type=ct.split(";")[0],
                                source_hostname=parsed.hostname or "",
                                source_url=url,
                                final_url=str(head_res.url),
                                detection_confidence=confidence,
                                is_direct_download=True,
                                range_supported=accept_ranges
                            ))

                except Exception:
                    # Ignore network errors on individual probing
                    pass

        # Inspect candidate list concurrently (capped to top 40 candidates)
        tasks = [inspect_candidate(u, hint) for u, hint in list(candidate_urls)[:40]]
        await asyncio.gather(*tasks)

        # Deduplicate discovered files by final_url
        seen_urls = set()
        unique_discovered = []
        for df in discovered:
            if df.final_url not in seen_urls:
                seen_urls.add(df.final_url)
                unique_discovered.append(df)

        return AnalyzeResponse(
            original_url=page_url,
            status="success" if unique_discovered else "partial",
            discovered_files=unique_discovered,
            filtered_links=filtered,
            total_discovered=len(unique_discovered),
            total_filtered=len(filtered),
            error_message="No direct downloadable files detected on this webpage." if not unique_discovered else None
        )

    def _parse_direct_resource(self, url: str, headers: httpx.Headers) -> DetectedFile:
        parsed = urlparse(url)
        cd = headers.get("content-disposition", "")
        ct = headers.get("content-type", "application/octet-stream").split(";")[0]
        cl = headers.get("content-length")
        accept_ranges = headers.get("accept-ranges", "").lower() == "bytes"

        filename = self._resolve_filename(url, cd, None)
        ext = filename.split(".")[-1].lower() if "." in filename else ""
        size = int(cl) if cl and cl.isdigit() else 0

        return DetectedFile(
            filename=filename,
            file_extension=ext.upper() if ext else "FILE",
            file_size=size,
            content_type=ct,
            source_hostname=parsed.hostname or "",
            source_url=url,
            final_url=url,
            detection_confidence="High",
            is_direct_download=True,
            range_supported=accept_ranges
        )

    def _resolve_filename(self, url: str, content_disposition: str, hint: Optional[str]) -> str:
        # 1. Try Content-Disposition filename* or filename
        if content_disposition:
            # UTF-8 encoded filename*
            fn_star_match = re.search(r"filename\*\s*=\s*(?:UTF-8''|utf-8'')([^;]+)", content_disposition, re.IGNORECASE)
            if fn_star_match:
                from urllib.parse import unquote
                return sanitize_filename(unquote(fn_star_match.group(1).strip('"\'')))

            # Standard filename
            fn_match = re.search(r'filename\s*=\s*"?([^";]+)"?', content_disposition, re.IGNORECASE)
            if fn_match:
                return sanitize_filename(fn_match.group(1).strip('"\''))

        # 2. Try URL path component
        parsed = urlparse(url)
        path = parsed.path.rstrip("/")
        if path:
            url_name = path.split("/")[-1]
            if "." in url_name and len(url_name.split(".")[-1]) <= 6:
                return sanitize_filename(url_name)

        # 3. Try anchor hint
        if hint and "." in hint:
            return sanitize_filename(hint)

        return sanitize_filename("downloaded_file")


analyzer_service = SmartUrlAnalyzer()

