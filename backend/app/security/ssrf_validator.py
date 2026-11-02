import ipaddress
import re
import socket
from urllib.parse import urlparse
from typing import Tuple


BLOCKED_IP_NETWORKS = [
    ipaddress.ip_network("0.0.0.0/8"),
    ipaddress.ip_network("10.0.0.0/8"),
    ipaddress.ip_network("127.0.0.0/8"),
    ipaddress.ip_network("169.254.0.0/16"),
    ipaddress.ip_network("172.16.0.0/12"),
    ipaddress.ip_network("192.168.0.0/16"),
    ipaddress.ip_network("100.64.0.0/10"),
    ipaddress.ip_network("192.0.0.0/24"),
    ipaddress.ip_network("192.0.2.0/24"),
    ipaddress.ip_network("198.51.100.0/24"),
    ipaddress.ip_network("203.0.113.0/24"),
    ipaddress.ip_network("224.0.0.0/4"),
    ipaddress.ip_network("240.0.0.0/4"),
    ipaddress.ip_network("255.255.255.255/32"),
    # IPv6
    ipaddress.ip_network("::1/128"),
    ipaddress.ip_network("::/128"),
    ipaddress.ip_network("fc00::/7"),
    ipaddress.ip_network("fe80::/10"),
    ipaddress.ip_network("ff00::/8"),
]

WINDOWS_RESERVED_NAMES = {
    "CON", "PRN", "AUX", "NUL",
    "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
    "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
}


class SSRFValidationError(ValueError):
    """Raised when an untrusted URL fails security validation."""
    pass


SSRFSecurityError = SSRFValidationError


class SSRFValidator:
    def validate_url(self, url: str) -> None:
        valid, err = validate_url_security(url)
        if not valid:
            raise SSRFValidationError(err)

    def sanitize_filename(self, filename: str, fallback: str = "download") -> str:
        return sanitize_filename(filename, fallback)


ssrf_validator = SSRFValidator()



def validate_url_security(url: str) -> Tuple[bool, str]:
    """
    Validates URL scheme, hostname, and resolves IP against SSRF blocklists.
    Returns (is_valid, error_message).
    """
    if not url or not isinstance(url, str):
        return False, "URL cannot be empty."

    url = url.strip()
    if len(url) > 4096:
        return False, "URL exceeds maximum permitted length (4096 characters)."

    try:
        parsed = urlparse(url)
    except Exception as e:
        return False, f"Failed to parse URL: {e}"

    # 1. Scheme check: only http and https allowed
    if parsed.scheme.lower() not in ("http", "https"):
        return False, f"Unsupported URL scheme '{parsed.scheme}'. Only HTTP and HTTPS are permitted."

    hostname = parsed.hostname
    if not hostname:
        return False, "URL lacks a valid hostname."

    hostname = hostname.lower().strip(".")

    # 2. Rejection of localhost variants and reserved domains
    if hostname in ("localhost", "local", "invalid", "test", "example"):
        return False, f"Access to '{hostname}' is prohibited."

    # 3. Direct IP address validation
    try:
        ip = ipaddress.ip_address(hostname)
        for net in BLOCKED_IP_NETWORKS:
            if ip in net:
                return False, f"Destination IP {ip} falls within prohibited internal/private network ({net})."
        return True, ""
    except ValueError:
        # Hostname is not a raw IP address; resolve DNS
        pass

    # 4. DNS resolution and SSRF check
    try:
        # Resolve all A and AAAA records
        addr_info = socket.getaddrinfo(hostname, None, socket.AF_UNSPEC, socket.SOCK_STREAM)
        if not addr_info:
            return False, f"Hostname '{hostname}' could not be resolved."

        for item in addr_info:
            ip_str = item[4][0]
            ip = ipaddress.ip_address(ip_str)
            for net in BLOCKED_IP_NETWORKS:
                if ip in net:
                    return False, f"Resolved IP {ip} for host '{hostname}' is in prohibited internal range ({net})."

    except socket.gaierror as e:
        return False, f"DNS resolution failed for '{hostname}': {e}"
    except Exception as e:
        return False, f"Error validating destination '{hostname}': {e}"

    return True, ""


def sanitize_filename(filename: str, fallback: str = "download") -> str:
    """
    Sanitizes user-provided or header-extracted filenames:
    - Strips path traversal sequences (../, ..\\)
    - Replaces invalid Windows filename characters (< > : " / \\ | ? *)
    - Strips non-printable ASCII / control characters
    - Protects against Windows DOS reserved device names (CON, NUL, AUX, etc.)
    - Truncates to 240 chars to respect MAX_PATH.
    """
    if not filename:
        return fallback

    # Strip directory components
    filename = filename.replace("\\", "/").split("/")[-1].strip()

    # Strip control characters and zero-width characters
    filename = re.sub(r'[\x00-\x1f\x7f-\x9f]', '', filename)

    # Replace forbidden Windows characters: < > : " / \ | ? *
    filename = re.sub(r'[<>:"/\\|?*]', '_', filename)

    # Strip trailing periods and spaces (Windows disallowed)
    filename = filename.rstrip('. ')

    if not filename:
        filename = fallback

    # Check for reserved DOS names (CON.txt, PRN.pdf, etc.)
    base_name = filename.split('.')[0].upper()
    if base_name in WINDOWS_RESERVED_NAMES:
        filename = f"file_{filename}"

    # Truncate length while preserving extension if possible
    if len(filename) > 240:
        parts = filename.rsplit('.', 1)
        if len(parts) == 2 and len(parts[1]) < 10:
            filename = f"{parts[0][:230]}.{parts[1]}"
        else:
            filename = filename[:240]

    return filename
