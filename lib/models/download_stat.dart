class DownloadStat {
  final int currentSpeed; // bytes/s
  final int averageSpeed; // bytes/s
  final int peakSpeed; // bytes/s
  final int activeCount;
  final int waitingCount;
  final int stoppedCount;
  final int completedCount;
  final int totalDownloadedBytes;
  final int totalRemainingBytes;
  final int activeConnections;

  const DownloadStat({
    this.currentSpeed = 0,
    this.averageSpeed = 0,
    this.peakSpeed = 0,
    this.activeCount = 0,
    this.waitingCount = 0,
    this.stoppedCount = 0,
    this.completedCount = 0,
    this.totalDownloadedBytes = 0,
    this.totalRemainingBytes = 0,
    this.activeConnections = 0,
  });

  DownloadStat copyWith({
    int? currentSpeed,
    int? averageSpeed,
    int? peakSpeed,
    int? activeCount,
    int? waitingCount,
    int? stoppedCount,
    int? completedCount,
    int? totalDownloadedBytes,
    int? totalRemainingBytes,
    int? activeConnections,
  }) {
    return DownloadStat(
      currentSpeed: currentSpeed ?? this.currentSpeed,
      averageSpeed: averageSpeed ?? this.averageSpeed,
      peakSpeed: peakSpeed ?? this.peakSpeed,
      activeCount: activeCount ?? this.activeCount,
      waitingCount: waitingCount ?? this.waitingCount,
      stoppedCount: stoppedCount ?? this.stoppedCount,
      completedCount: completedCount ?? this.completedCount,
      totalDownloadedBytes: totalDownloadedBytes ?? this.totalDownloadedBytes,
      totalRemainingBytes: totalRemainingBytes ?? this.totalRemainingBytes,
      activeConnections: activeConnections ?? this.activeConnections,
    );
  }
}

