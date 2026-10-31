class Validators {
  static bool isValidUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
    final scheme = uri.scheme.toLowerCase();
    return ['http', 'https', 'ftp', 'sftp'].contains(scheme);
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

