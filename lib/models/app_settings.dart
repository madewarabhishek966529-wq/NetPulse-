class AppSettings {
  final int maxSimultaneousDownloads;
  final int maxConnectionsPerDownload;
  final int globalSpeedLimitBytes; // 0 = unlimited
  final int individualSpeedLimitBytes; // 0 = unlimited
  final String defaultDownloadFolder;
  final String defaultCategory;
  final int retryCount;
  final int timeoutSeconds;
  final bool minimizeToTray;
  final bool startWithWindows;
  final bool darkMode;
  final String accentColorHex;
  final bool compactMode;
  final bool browserInterceptionEnabled;
  final String interceptedExtensions; // comma separated: exe,zip,iso,mp4

  const AppSettings({
    this.maxSimultaneousDownloads = 3,
    this.maxConnectionsPerDownload = 8,
    this.globalSpeedLimitBytes = 0,
    this.individualSpeedLimitBytes = 0,
    this.defaultDownloadFolder = '',
    this.defaultCategory = 'Other',
    this.retryCount = 5,
    this.timeoutSeconds = 30,
    this.minimizeToTray = true,
    this.startWithWindows = false,
    this.darkMode = true,
    this.accentColorHex = '00E5FF',
    this.compactMode = false,
    this.browserInterceptionEnabled = true,
    this.interceptedExtensions = 'exe,msi,zip,rar,7z,iso,mp4,mkv,tar,gz',
  });

  AppSettings copyWith({
    int? maxSimultaneousDownloads,
    int? maxConnectionsPerDownload,
    int? globalSpeedLimitBytes,
    int? individualSpeedLimitBytes,
    String? defaultDownloadFolder,
    String? defaultCategory,
    int? retryCount,
    int? timeoutSeconds,
    bool? minimizeToTray,
    bool? startWithWindows,
    bool? darkMode,
    String? accentColorHex,
    bool? compactMode,
    bool? browserInterceptionEnabled,
    String? interceptedExtensions,
  }) {
    return AppSettings(
      maxSimultaneousDownloads:
          maxSimultaneousDownloads ?? this.maxSimultaneousDownloads,
      maxConnectionsPerDownload:
          maxConnectionsPerDownload ?? this.maxConnectionsPerDownload,
      globalSpeedLimitBytes:
          globalSpeedLimitBytes ?? this.globalSpeedLimitBytes,
      individualSpeedLimitBytes:
          individualSpeedLimitBytes ?? this.individualSpeedLimitBytes,
      defaultDownloadFolder:
          defaultDownloadFolder ?? this.defaultDownloadFolder,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      retryCount: retryCount ?? this.retryCount,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      startWithWindows: startWithWindows ?? this.startWithWindows,
      darkMode: darkMode ?? this.darkMode,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      compactMode: compactMode ?? this.compactMode,
      browserInterceptionEnabled:
          browserInterceptionEnabled ?? this.browserInterceptionEnabled,
      interceptedExtensions:
          interceptedExtensions ?? this.interceptedExtensions,
    );
  }

  Map<String, String> toSettingsMap() {
    return {
      'max_simultaneous_downloads': maxSimultaneousDownloads.toString(),
      'max_connections_per_download': maxConnectionsPerDownload.toString(),
      'global_speed_limit_bytes': globalSpeedLimitBytes.toString(),
      'individual_speed_limit_bytes': individualSpeedLimitBytes.toString(),
      'default_download_folder': defaultDownloadFolder,
      'default_category': defaultCategory,
      'retry_count': retryCount.toString(),
      'timeout_seconds': timeoutSeconds.toString(),
      'minimize_to_tray': minimizeToTray ? '1' : '0',
      'start_with_windows': startWithWindows ? '1' : '0',
      'dark_mode': darkMode ? '1' : '0',
      'accent_color_hex': accentColorHex,
      'compact_mode': compactMode ? '1' : '0',
      'browser_interception_enabled': browserInterceptionEnabled ? '1' : '0',
      'intercepted_extensions': interceptedExtensions,
    };
  }

  factory AppSettings.fromSettingsMap(Map<String, String> map) {
    return AppSettings(
      maxSimultaneousDownloads: int.tryParse(map['max_simultaneous_downloads'] ?? '') ?? 3,
      maxConnectionsPerDownload: int.tryParse(map['max_connections_per_download'] ?? '') ?? 8,
      globalSpeedLimitBytes: int.tryParse(map['global_speed_limit_bytes'] ?? '') ?? 0,
      individualSpeedLimitBytes: int.tryParse(map['individual_speed_limit_bytes'] ?? '') ?? 0,
      defaultDownloadFolder: map['default_download_folder'] ?? '',
      defaultCategory: map['default_category'] ?? 'Other',
      retryCount: int.tryParse(map['retry_count'] ?? '') ?? 5,
      timeoutSeconds: int.tryParse(map['timeout_seconds'] ?? '') ?? 30,
      minimizeToTray: (map['minimize_to_tray'] ?? '1') == '1',
      startWithWindows: (map['start_with_windows'] ?? '0') == '1',
      darkMode: (map['dark_mode'] ?? '1') == '1',
      accentColorHex: map['accent_color_hex'] ?? '00E5FF',
      compactMode: (map['compact_mode'] ?? '0') == '1',
      browserInterceptionEnabled: (map['browser_interception_enabled'] ?? '1') == '1',
      interceptedExtensions: map['intercepted_extensions'] ?? 'exe,msi,zip,rar,7z,iso,mp4,mkv,tar,gz',
    );
  }
}
