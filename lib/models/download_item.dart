enum DownloadStatus {
  active,
  waiting,
  paused,
  completed,
  error,
  removed;

  static DownloadStatus fromString(String? val) {
    if (val == null) return DownloadStatus.waiting;
    switch (val.toLowerCase()) {
      case 'active':
        return DownloadStatus.active;
      case 'waiting':
        return DownloadStatus.waiting;
      case 'paused':
        return DownloadStatus.paused;
      case 'completed':
      case 'complete':
        return DownloadStatus.completed;
      case 'error':
      case 'failed':
        return DownloadStatus.error;
      case 'removed':
        return DownloadStatus.removed;
      default:
        return DownloadStatus.waiting;
    }
  }

  String get displayName {
    switch (this) {
      case DownloadStatus.active:
        return 'Downloading';
      case DownloadStatus.waiting:
        return 'Queued';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.error:
        return 'Failed';
      case DownloadStatus.removed:
        return 'Removed';
    }
  }
}

enum DownloadPriority {
  low,
  normal,
  high;

  static DownloadPriority fromString(String? val) {
    if (val == null) return DownloadPriority.normal;
    switch (val.toLowerCase()) {
      case 'high':
        return DownloadPriority.high;
      case 'low':
        return DownloadPriority.low;
      default:
        return DownloadPriority.normal;
    }
  }
}

class DownloadItem {
  final int? id;
  final String gid;
  final String url;
  final String fileName;
  final String filePath;
  final int fileSize;
  final int downloadedSize;
  final int downloadSpeed;
  final DownloadStatus status;
  final String categoryId;
  final DateTime createdAt;
  final DateTime? completedAt;
  final int connections;
  final String? errorMessage;
  final String? checksum;
  final DownloadPriority priority;
  final bool isScheduled;
  final DateTime? scheduledStartTime;
  final DateTime? scheduledEndTime;

  DownloadItem({
    this.id,
    required this.gid,
    required this.url,
    required this.fileName,
    required this.filePath,
    this.fileSize = 0,
    this.downloadedSize = 0,
    this.downloadSpeed = 0,
    this.status = DownloadStatus.waiting,
    this.categoryId = 'Other',
    DateTime? createdAt,
    this.completedAt,
    this.connections = 1,
    this.errorMessage,
    this.checksum,
    this.priority = DownloadPriority.normal,
    this.isScheduled = false,
    this.scheduledStartTime,
    this.scheduledEndTime,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progress {
    if (fileSize <= 0) return 0.0;
    return (downloadedSize / fileSize).clamp(0.0, 1.0);
  }

  int get remainingBytes => (fileSize - downloadedSize).clamp(0, fileSize);

  bool get isFinished =>
      status == DownloadStatus.completed ||
      status == DownloadStatus.error ||
      status == DownloadStatus.removed;

  DownloadItem copyWith({
    int? id,
    String? gid,
    String? url,
    String? fileName,
    String? filePath,
    int? fileSize,
    int? downloadedSize,
    int? downloadSpeed,
    DownloadStatus? status,
    String? categoryId,
    DateTime? createdAt,
    DateTime? completedAt,
    int? connections,
    String? errorMessage,
    String? checksum,
    DownloadPriority? priority,
    bool? isScheduled,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      gid: gid ?? this.gid,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      downloadedSize: downloadedSize ?? this.downloadedSize,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      connections: connections ?? this.connections,
      errorMessage: errorMessage ?? this.errorMessage,
      checksum: checksum ?? this.checksum,
      priority: priority ?? this.priority,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledStartTime: scheduledStartTime ?? this.scheduledStartTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gid': gid,
      'url': url,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'downloaded_size': downloadedSize,
      'download_speed': downloadSpeed,
      'status': status.name,
      'category_id': categoryId,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'connections': connections,
      'error_message': errorMessage,
      'checksum': checksum,
      'priority': priority.name,
      'is_scheduled': isScheduled ? 1 : 0,
      'scheduled_start_time': scheduledStartTime?.toIso8601String(),
      'scheduled_end_time': scheduledEndTime?.toIso8601String(),
    };
  }

  factory DownloadItem.fromMap(Map<String, dynamic> map) {
    return DownloadItem(
      id: map['id'] as int?,
      gid: map['gid'] as String? ?? '',
      url: map['url'] as String? ?? '',
      fileName: map['file_name'] as String? ?? '',
      filePath: map['file_path'] as String? ?? '',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      downloadedSize: (map['downloaded_size'] as num?)?.toInt() ?? 0,
      downloadSpeed: (map['download_speed'] as num?)?.toInt() ?? 0,
      status: DownloadStatus.fromString(map['status'] as String?),
      categoryId: map['category_id'] as String? ?? 'Other',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: map['completed_at'] != null
          ? DateTime.tryParse(map['completed_at'] as String)
          : null,
      connections: (map['connections'] as num?)?.toInt() ?? 1,
      errorMessage: map['error_message'] as String?,
      checksum: map['checksum'] as String?,
      priority: DownloadPriority.fromString(map['priority'] as String?),
      isScheduled: (map['is_scheduled'] as int? ?? 0) == 1,
      scheduledStartTime: map['scheduled_start_time'] != null
          ? DateTime.tryParse(map['scheduled_start_time'] as String)
          : null,
      scheduledEndTime: map['scheduled_end_time'] != null
          ? DateTime.tryParse(map['scheduled_end_time'] as String)
          : null,
    );
  }
}
