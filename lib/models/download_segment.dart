class DownloadSegment {
  final int? id;
  final int downloadId;
  final int segmentIndex;
  final String segmentStatus;
  final int downloadedBytes;
  final int totalBytes;

  DownloadSegment({
    this.id,
    required this.downloadId,
    required this.segmentIndex,
    this.segmentStatus = 'downloading',
    this.downloadedBytes = 0,
    this.totalBytes = 0,
  });

  double get progress => totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'download_id': downloadId,
      'segment_index': segmentIndex,
      'segment_status': segmentStatus,
      'downloaded_bytes': downloadedBytes,
    };
  }

  factory DownloadSegment.fromMap(Map<String, dynamic> map) {
    return DownloadSegment(
      id: map['id'] as int?,
      downloadId: map['download_id'] as int? ?? 0,
      segmentIndex: map['segment_index'] as int? ?? 0,
      segmentStatus: map['segment_status'] as String? ?? 'downloading',
      downloadedBytes: (map['downloaded_bytes'] as num?)?.toInt() ?? 0,
      totalBytes: (map['total_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}

