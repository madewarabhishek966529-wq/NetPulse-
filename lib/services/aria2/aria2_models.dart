class Aria2FileInfo {
  final int index;
  final String path;
  final int length;
  final int completedLength;
  final bool selected;

  Aria2FileInfo({
    required this.index,
    required this.path,
    required this.length,
    required this.completedLength,
    required this.selected,
  });

  factory Aria2FileInfo.fromMap(Map<String, dynamic> map) {
    return Aria2FileInfo(
      index: int.tryParse(map['index']?.toString() ?? '1') ?? 1,
      path: map['path']?.toString() ?? '',
      length: int.tryParse(map['length']?.toString() ?? '0') ?? 0,
      completedLength:
          int.tryParse(map['completedLength']?.toString() ?? '0') ?? 0,
      selected: map['selected']?.toString() == 'true',
    );
  }
}

class Aria2Status {
  final String gid;
  final String status; // active, waiting, paused, error, complete, removed
  final int totalLength;
  final int completedLength;
  final int downloadSpeed;
  final int uploadSpeed;
  final int connections;
  final String? errorCode;
  final String? errorMessage;
  final List<Aria2FileInfo> files;
  final int pieceLength;
  final int numPieces;
  final String? bitfield;

  Aria2Status({
    required this.gid,
    required this.status,
    required this.totalLength,
    required this.completedLength,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.connections,
    this.errorCode,
    this.errorMessage,
    required this.files,
    this.pieceLength = 0,
    this.numPieces = 0,
    this.bitfield,
  });

  String get filePath => files.isNotEmpty ? files.first.path : '';

  factory Aria2Status.fromMap(Map<String, dynamic> map) {
    final rawFiles = map['files'] as List<dynamic>? ?? [];
    final filesList = rawFiles
        .map((f) => Aria2FileInfo.fromMap(f as Map<String, dynamic>))
        .toList();

    return Aria2Status(
      gid: map['gid']?.toString() ?? '',
      status: map['status']?.toString() ?? 'waiting',
      totalLength: int.tryParse(map['totalLength']?.toString() ?? '0') ?? 0,
      completedLength:
          int.tryParse(map['completedLength']?.toString() ?? '0') ?? 0,
      downloadSpeed:
          int.tryParse(map['downloadSpeed']?.toString() ?? '0') ?? 0,
      uploadSpeed: int.tryParse(map['uploadSpeed']?.toString() ?? '0') ?? 0,
      connections: int.tryParse(map['connections']?.toString() ?? '1') ?? 1,
      errorCode: map['errorCode']?.toString(),
      errorMessage: map['errorMessage']?.toString(),
      files: filesList,
      pieceLength: int.tryParse(map['pieceLength']?.toString() ?? '0') ?? 0,
      numPieces: int.tryParse(map['numPieces']?.toString() ?? '0') ?? 0,
      bitfield: map['bitfield']?.toString(),
    );
  }
}

class Aria2GlobalStat {
  final int downloadSpeed;
  final int uploadSpeed;
  final int numActive;
  final int numWaiting;
  final int numStopped;
  final int numStoppedTotal;

  Aria2GlobalStat({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.numActive,
    required this.numWaiting,
    required this.numStopped,
    required this.numStoppedTotal,
  });

  factory Aria2GlobalStat.fromMap(Map<String, dynamic> map) {
    return Aria2GlobalStat(
      downloadSpeed: int.tryParse(map['downloadSpeed']?.toString() ?? '0') ?? 0,
      uploadSpeed: int.tryParse(map['uploadSpeed']?.toString() ?? '0') ?? 0,
      numActive: int.tryParse(map['numActive']?.toString() ?? '0') ?? 0,
      numWaiting: int.tryParse(map['numWaiting']?.toString() ?? '0') ?? 0,
      numStopped: int.tryParse(map['numStopped']?.toString() ?? '0') ?? 0,
      numStoppedTotal:
          int.tryParse(map['numStoppedTotal']?.toString() ?? '0') ?? 0,
    );
  }
}

