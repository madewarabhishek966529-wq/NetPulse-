import re
from typing import Tuple, Optional
from urllib.parse import urlparse, urlunparse, parse_qs, urlencode


# Conservative list of known advertising and tracking domains
KNOWN_AD_DOMAINS = {
    "doubleclick.net",
    "googleadservices.com",
    "googlesyndication.com",
    "adnxs.com",
    "adsrvr.org",
    "advertising.com",
    "popads.net",
    "popcash.net",
    "propellerads.com",
    "exoclick.com",
    "adcash.com",
    "criteo.com",
    "outbrain.com",
    "taboola.com",
    "adroll.com",
    "mgid.com",
    "revcontent.com",
    "scorecardresearch.com",
    "quantserve.com",
    "moatads.com",
    "hotjar.com",
    "clarity.ms",
    "facebook.net",
    "connect.facebook.net",
    "analytics.twitter.com",
    "statcounter.com",
    "gemini.yahoo.com",
    "analytics.google.com",
    "clickmeter.com",
    "trafficjunky.net",
    "juicyads.com",
    "ero-advertising.com",
    "yllix.com",
    "adsterra.com",
}

# Tracking query parameters to strip during normalization
TRACKING_PARAMS = {
    "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
    "gclid", "fbclid", "msclkid", "dclid", "zanpid", "yclid", "_ga", "_gl",
    "ref", "affiliate", "aff_id", "click_id"
}

# File host allowlist - trusted file distribution domains
FILE_HOST_ALLOWLIST = {
    "github.com",
    "objects.githubusercontent.com",
    "releases.ubuntu.com",
    "cdimage.debian.org",
    "archive.org",
    "sourceforge.net",
    "apache.org",
    "python.org",
    "mozilla.org",
    "kernel.org",
    "videolan.org",
    "google.com",
    "storage.googleapis.com",
    "microsoft.com",
}


class AdFilterService:
    def __init__(self):
        self.blocklist = set(KNOWN_AD_DOMAINS)
        self.allowlist = set(FILE_HOST_ALLOWLIST)

    def is_filtered(self, url: str) -> Tuple[bool, Optional[str]]:
        """
        Conservative check on whether a URL is an advertisement, tracking beacon,
        or malformed URL.
        Returns (should_filter, reason).
        """
        if not url:
            return True, "Empty URL"

        try:
            parsed = urlparse(url)
        except Exception:
            return True, "Malformed URL syntax"

        hostname = (parsed.hostname or "").lower()
        if not hostname:
            return True, "Missing hostname"

        # Check explicit allowlist
        for allowed in self.allowlist:
            if hostname == allowed or hostname.endswith(f".{allowed}"):
                return False, None

        # Check domain against known ad networks
        for ad_domain in self.blocklist:
            if hostname == ad_domain or hostname.endswith(f".{ad_domain}"):
                return True, f"Known advertising/tracking network ({ad_domain})"

        # Path heuristics for explicit ad paths
        path = parsed.path.lower()
        if re.search(r'/(ads?|popunder|clicktag|advertisement|sponsor)/', path):
            return True, "Advertisement path pattern detected"

        # Tracking pixel / beacon checks (1x1 images, analytics collect)
        if "/collect" in path and ("google-analytics" in hostname or "analytics" in hostname):
            return True, "Analytics collection beacon"

        return False, None

    def normalize_url(self, url: str) -> str:
        """
        Strips tracking query parameters and standardizes the URL format.
        """
        try:
            parsed = urlparse(url)
            qs = parse_qs(parsed.query, keep_blank_values=False)
            filtered_qs = {k: v for k, v in qs.items() if k.lower() not in TRACKING_PARAMS}
            clean_query = urlencode(filtered_qs, doseq=True)

            return urlunparse((
                parsed.scheme.lower(),
                parsed.netloc.lower(),
                parsed.path,
                parsed.params,
                clean_query,
                ""  # Strip fragment
            ))
        except Exception:
            return url

    def is_ad_or_tracker(self, url: str) -> bool:
        is_ad, _ = self.is_filtered(url)
        return is_ad

    def strip_tracking_params(self, url: str) -> str:
        return self.normalize_url(url)


ad_filter_service = AdFilterService()

