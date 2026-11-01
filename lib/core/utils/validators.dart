class Validators {
  static bool isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmed = url.trim();
    if (isMagnetLink(trimmed)) return true;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
    final scheme = uri.scheme.toLowerCase();
    return ['http', 'https', 'ftp', 'sftp'].contains(scheme);
  }

  static bool isMagnetLink(String? url) {
    if (url == null) return false;
    final trimmed = url.trim().toLowerCase();
    return trimmed.startsWith('magnet:?xt=') || trimmed.startsWith('magnet:?');
  }

  static bool isTorrentFile(String? path) {
    if (path == null) return false;
    return path.trim().toLowerCase().endsWith('.torrent');
  }

  static bool isValidSha256(String? hash) {
    if (hash == null) return false;
    final clean = hash.trim().toLowerCase();
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(clean);
  }

  static bool isValidMd5(String? hash) {
    if (hash == null) return false;
    final clean = hash.trim().toLowerCase();
    return RegExp(r'^[a-f0-9]{32}$').hasMatch(clean);
  }
}
