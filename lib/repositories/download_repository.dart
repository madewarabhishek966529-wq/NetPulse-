import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/app_constants.dart';
import '../../core/constants/torrent_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/validators.dart';
import '../../models/download_item.dart';
import '../../models/download_stat.dart';
import '../services/aria2/aria2_client.dart';
import '../services/aria2/aria2_engine_manager.dart';
import '../services/database/database_service.dart';

class DownloadRepository {
  final Aria2EngineManager _engineManager;
  final DatabaseService _dbService;

  Aria2Client? _client;
  Timer? _pollTimer;
  bool _isPolling = false;

  final _statController = StreamController<DownloadStat>.broadcast();
  Stream<DownloadStat> get statStream => _statController.stream;

  final _downloadsController = StreamController<List<DownloadItem>>.broadcast();
  Stream<List<DownloadItem>> get downloadsStream => _downloadsController.stream;

  // Local in-memory cache of active downloads to prevent excessive SQLite reads
  final Map<String, DownloadItem> _activeDownloadsCache = {};
  DownloadStat _lastStat = const DownloadStat();
  int _peakSpeed = 0;
  final List<int> _recentSpeeds = [];

  DownloadRepository({
    Aria2EngineManager? engineManager,
    DatabaseService? dbService,
  })  : _engineManager = engineManager ?? Aria2EngineManager(),
        _dbService = dbService ?? DatabaseService();

  Aria2EngineManager get engineManager => _engineManager;
  DatabaseService get dbService => _dbService;
  Aria2Client? get client => _client;
  DownloadStat get currentStat => _lastStat;

  /// Initialize engine, database, and reconcile unfinished downloads
  Future<void> initialize() async {
    DatabaseService.ensureInitialized();
    await _dbService.database;

    // Start aria2 background engine
    _client = await _engineManager.startEngine();

    // Reconcile unfinished downloads
    await _reconcileUnfinishedDownloads();

    // Start real-time polling
    startPolling();
  }

  /// Reconcile downloads that were interrupted or unfinished when NetPulse closed
  Future<void> _reconcileUnfinishedDownloads() async {
    if (_client == null) return;

    try {
      final unfinished = await _dbService.getUnfinishedDownloads();
      debugPrint('[Reconcile] Found ${unfinished.length} unfinished downloads to restore.');

      for (final item in unfinished) {
        try {
          final targetDir = p.dirname(item.filePath);
          final fileName = p.basename(item.filePath);

          final options = <String, dynamic>{
            'dir': targetDir,
            'out': fileName,
            'continue': 'true',
            'split': item.connections.toString(),
            'max-connection-per-server': item.connections.toString(),
          };

          // Re-add to aria2 engine
          final newGid = await _client!.addUri([item.url], options: options);

          // Update SQLite with the new GID
          final updatedItem = item.copyWith(
            gid: newGid,
            status: DownloadStatus.waiting,
          );
          await _dbService.updateDownload(updatedItem);
          _activeDownloadsCache[newGid] = updatedItem;

          debugPrint('[Reconcile] Restored "${item.fileName}" with new GID: $newGid');
        } catch (e) {
          debugPrint('[Reconcile] Failed to restore download ${item.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('[Reconcile] Error during reconciliation: $e');
    }
  }

  /// Start a new download
  Future<DownloadItem> addDownload({
    required String url,
    required String fileName,
    required String targetDirectory,
    int connections = 8,
    String category = 'Other',
    Map<String, String>? headers,
    String? username,
    String? password,
    String? expectedChecksum,
    DownloadPriority priority = DownloadPriority.normal,
    bool isScheduled = false,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    bool startPaused = false,
  }) async {
    if (_client == null) {
      throw Aria2Exception('Download engine is not running');
    }

    final isMagnet = Validators.isMagnetLink(url);
    final sanitizedName = fileName.trim().isNotEmpty
        ? fileName.trim()
        : (isMagnet ? 'Magnet Torrent' : 'download_${DateTime.now().millisecondsSinceEpoch}');
    final fullPath = p.join(targetDirectory, sanitizedName);

    final ariaOptions = <String, dynamic>{
      'dir': targetDirectory,
      'continue': 'true',
      'allow-overwrite': 'true',
      'auto-file-renaming': 'false',
    };

    if (isMagnet) {
      ariaOptions['bt-tracker'] = TorrentConstants.trackerArgString;
      ariaOptions['bt-enable-lpd'] = 'true';
      ariaOptions['enable-peer-exchange'] = 'true';
      ariaOptions['seed-ratio'] = '0.0';
    } else {
      ariaOptions['out'] = sanitizedName;
      ariaOptions['split'] = connections.clamp(1, 32).toString();
      ariaOptions['max-connection-per-server'] = connections.clamp(1, 16).toString();
      ariaOptions['min-split-size'] = '5M';
    }

    if (startPaused) {
      ariaOptions['pause'] = 'true';
    }

    if (headers != null && headers.isNotEmpty) {
      final headerList = headers.entries.map((e) => '${e.key}: ${e.value}').toList();
      ariaOptions['header'] = headerList;
    }

    if (username != null && username.isNotEmpty) {
      ariaOptions['http-user'] = username;
      if (password != null) {
        ariaOptions['http-passwd'] = password;
      }
    }

    // Call aria2 addUri
    final gid = await _client!.addUri([url], options: ariaOptions);

    final downloadItem = DownloadItem(
      gid: gid,
      url: url,
      fileName: sanitizedName,
      filePath: fullPath,
      fileSize: 0,
      downloadedSize: 0,
      downloadSpeed: 0,
      status: startPaused ? DownloadStatus.paused : DownloadStatus.active,
      categoryId: isMagnet ? 'Other' : category,
      connections: connections,
      checksum: expectedChecksum,
      priority: priority,
      isScheduled: isScheduled,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      isTorrent: isMagnet,
    );

    final id = await _dbService.insertDownload(downloadItem);
    final savedItem = downloadItem.copyWith(id: id);
    _activeDownloadsCache[gid] = savedItem;

    // Trigger immediate UI refresh
    await _pollEngine();

    return savedItem;
  }

  /// Add a BitTorrent download from a .torrent file
  Future<DownloadItem> addTorrentDownload({
    required Uint8List torrentBytes,
    required String fileName,
    required String targetDirectory,
    String category = 'Other',
    DownloadPriority priority = DownloadPriority.normal,
    bool isScheduled = false,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    bool startPaused = false,
  }) async {
    if (_client == null) {
      throw Aria2Exception('Download engine is not running');
    }

    final sanitizedName = fileName.replaceAll(RegExp(r'\.torrent$', caseSensitive: false), '').trim();
    final fullPath = p.join(targetDirectory, sanitizedName);

    final ariaOptions = <String, dynamic>{
      'dir': targetDirectory,
      'continue': 'true',
      'allow-overwrite': 'true',
      'bt-tracker': TorrentConstants.trackerArgString,
      'bt-enable-lpd': 'true',
      'enable-peer-exchange': 'true',
      'seed-ratio': '0.0',
    };

    if (startPaused) {
      ariaOptions['pause'] = 'true';
    }

    final base64Content = base64Encode(torrentBytes);
    final gid = await _client!.addTorrent(base64Content, options: ariaOptions);

    final downloadItem = DownloadItem(
      gid: gid,
      url: 'torrent://$sanitizedName',
      fileName: sanitizedName,
      filePath: fullPath,
      fileSize: 0,
      downloadedSize: 0,
      downloadSpeed: 0,
      status: startPaused ? DownloadStatus.paused : DownloadStatus.active,
      categoryId: category,
      connections: 1,
      priority: priority,
      isScheduled: isScheduled,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      isTorrent: true,
    );

    final id = await _dbService.insertDownload(downloadItem);
    final savedItem = downloadItem.copyWith(id: id);
    _activeDownloadsCache[gid] = savedItem;

    await _pollEngine();
    return savedItem;
  }

  /// Pause download
  Future<void> pauseDownload(String gid) async {
    if (_client == null) return;
    try {
      await _client!.pause(gid);
    } catch (_) {
      try {
        await _client!.forcePause(gid);
      } catch (_) {}
    }

    final item = await _dbService.getDownloadByGid(gid);
    if (item != null) {
      final updated = item.copyWith(
        status: DownloadStatus.paused,
        downloadSpeed: 0,
      );
      await _dbService.updateDownload(updated);
      _activeDownloadsCache[gid] = updated;
      await _dbService.logHistory(item.id, 'paused');
    }
    await _pollEngine();
  }

  /// Resume download
  Future<void> resumeDownload(String gid) async {
    if (_client == null) return;
    try {
      await _client!.unpause(gid);
    } catch (e) {
      debugPrint('[Resume] unpause error: $e');
    }

    final item = await _dbService.getDownloadByGid(gid);
    if (item != null) {
      final updated = item.copyWith(
        status: DownloadStatus.active,
      );
      await _dbService.updateDownload(updated);
      _activeDownloadsCache[gid] = updated;
      await _dbService.logHistory(item.id, 'resumed');
    }
    await _pollEngine();
  }

  /// Cancel/Remove download
  Future<void> cancelDownload(String gid, {bool deleteFile = false}) async {
    if (_client == null) return;
    try {
      await _client!.remove(gid);
    } catch (_) {
      try {
        await _client!.forceRemove(gid);
      } catch (_) {}
    }

    final item = await _dbService.getDownloadByGid(gid);
    if (item != null) {
      if (deleteFile) {
        try {
          final file = File(item.filePath);
          if (file.existsSync()) file.deleteSync();
          final ariaControlFile = File('${item.filePath}.aria2');
          if (ariaControlFile.existsSync()) ariaControlFile.deleteSync();
        } catch (_) {}
        if (item.id != null) {
          await _dbService.deleteDownload(item.id!);
        }
      } else {
        final updated = item.copyWith(
          status: DownloadStatus.removed,
          downloadSpeed: 0,
        );
        await _dbService.updateDownload(updated);
      }
      _activeDownloadsCache.remove(gid);
      await _dbService.logHistory(item.id, 'cancelled');
    }
    await _pollEngine();
  }

  /// Restart download
  Future<void> restartDownload(int downloadId) async {
    final item = await _dbService.getDownloadById(downloadId);
    if (item == null || _client == null) return;

    try {
      await _client!.remove(item.gid);
    } catch (_) {}

    final targetDir = p.dirname(item.filePath);
    final fileName = p.basename(item.filePath);

    final options = <String, dynamic>{
      'dir': targetDir,
      'out': fileName,
      'split': item.connections.toString(),
      'max-connection-per-server': item.connections.toString(),
      'continue': 'true',
      'allow-overwrite': 'true',
    };

    final newGid = await _client!.addUri([item.url], options: options);
    final updated = item.copyWith(
      gid: newGid,
      status: DownloadStatus.active,
      downloadSpeed: 0,
      errorMessage: null,
    );
    await _dbService.updateDownload(updated);
    _activeDownloadsCache[newGid] = updated;
    await _dbService.logHistory(item.id, 'restarted');
    await _pollEngine();
  }

  /// Pause all downloads
  Future<void> pauseAll() async {
    if (_client == null) return;
    try {
      await _client!.pauseAll();
    } catch (_) {}
    await _pollEngine();
  }

  /// Resume all downloads
  Future<void> resumeAll() async {
    if (_client == null) return;
    try {
      await _client!.unpauseAll();
    } catch (_) {}
    await _pollEngine();
  }

  /// Configure global speed limit in bytes/sec (0 = unlimited)
  Future<void> setGlobalSpeedLimit(int bytesPerSec) async {
    if (_client == null) return;
    await _client!.changeGlobalOption({
      'max-overall-download-limit': bytesPerSec <= 0 ? '0' : bytesPerSec.toString(),
    });
  }

  /// Configure individual download speed limit in bytes/sec
  Future<void> setDownloadSpeedLimit(String gid, int bytesPerSec) async {
    if (_client == null) return;
    await _client!.changeOption(gid, {
      'max-download-limit': bytesPerSec <= 0 ? '0' : bytesPerSec.toString(),
    });
  }

  /// Set maximum concurrent downloads in aria2
  Future<void> setMaxConcurrentDownloads(int count) async {
    if (_client == null) return;
    await _client!.changeGlobalOption({
      'max-concurrent-downloads': count.clamp(1, 10).toString(),
    });
  }

  /// Start polling loop
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(AppConstants.progressPollingInterval, (_) {
      _pollEngine();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  int _syncDbCounter = 0;

  /// Poll engine status and synchronize state
  Future<void> _pollEngine() async {
    if (_client == null || _isPolling) return;
    _isPolling = true;

    try {
      // 1. Get global stats
      final globalStat = await _client!.getGlobalStat();

      // Track peak speed
      if (globalStat.downloadSpeed > _peakSpeed) {
        _peakSpeed = globalStat.downloadSpeed;
      }

      // Track average speed
      _recentSpeeds.add(globalStat.downloadSpeed);
      if (_recentSpeeds.length > 60) _recentSpeeds.removeAt(0);
      final avgSpeed = _recentSpeeds.isNotEmpty
          ? (_recentSpeeds.reduce((a, b) => a + b) ~/ _recentSpeeds.length)
          : 0;

      // 2. Fetch active and waiting tasks
      final activeList = await _client!.tellActive();
      final waitingList = await _client!.tellWaiting(0, 100);
      final stoppedList = await _client!.tellStopped(0, 50);

      final allEngineTasks = [...activeList, ...waitingList, ...stoppedList];

      int totalConnections = 0;
      int totalRemaining = 0;
      int totalDownloaded = 0;

      _syncDbCounter++;
      final shouldPersistToDb = (_syncDbCounter % 3 == 0); // Throttle SQLite writes to every ~2.2s

      for (final ariaTask in allEngineTasks) {
        totalConnections += ariaTask.connections;
        final remaining = (ariaTask.totalLength - ariaTask.completedLength).clamp(0, ariaTask.totalLength);
        totalRemaining += remaining;
        totalDownloaded += ariaTask.completedLength;

        // Map status
        DownloadStatus status;
        switch (ariaTask.status) {
          case 'active':
            status = DownloadStatus.active;
            break;
          case 'waiting':
            status = DownloadStatus.waiting;
            break;
          case 'paused':
            status = DownloadStatus.paused;
            break;
          case 'complete':
            status = DownloadStatus.completed;
            break;
          case 'error':
            status = DownloadStatus.error;
            break;
          default:
            status = DownloadStatus.waiting;
        }

        // Handle magnet metadata transition to payload download task
        if (ariaTask.followedBy.isNotEmpty) {
          final childGid = ariaTask.followedBy.first;
          if (!_activeDownloadsCache.containsKey(childGid)) {
            var parentItem = _activeDownloadsCache[ariaTask.gid] ?? await _dbService.getDownloadByGid(ariaTask.gid);
            if (parentItem != null) {
              final transitioned = parentItem.copyWith(gid: childGid);
              await _dbService.updateDownload(transitioned);
              _activeDownloadsCache[childGid] = transitioned;
            }
          }
        }

        // Get or load item
        var item = _activeDownloadsCache[ariaTask.gid];
        item ??= await _dbService.getDownloadByGid(ariaTask.gid);

        if (item != null) {
          final resolvedName = (ariaTask.torrentName != null && ariaTask.torrentName!.isNotEmpty)
              ? ariaTask.torrentName!
              : item.fileName;

          final updated = item.copyWith(
            fileName: resolvedName,
            fileSize: ariaTask.totalLength > 0 ? ariaTask.totalLength : item.fileSize,
            downloadedSize: ariaTask.completedLength,
            downloadSpeed: ariaTask.downloadSpeed,
            status: status,
            connections: ariaTask.connections,
            isTorrent: item.isTorrent || ariaTask.isTorrent,
            seeders: ariaTask.numSeeders,
            completedAt: status == DownloadStatus.completed
                ? (item.completedAt ?? DateTime.now())
                : null,
            errorMessage: ariaTask.errorMessage,
          );

          _activeDownloadsCache[ariaTask.gid] = updated;

          if (shouldPersistToDb || status == DownloadStatus.completed || status == DownloadStatus.error) {
            await _dbService.updateDownloadByGid(updated);
            if (status == DownloadStatus.completed && item.status != DownloadStatus.completed) {
              await _dbService.logHistory(item.id, 'completed');
            }
          }
        }
      }

      // Count completed
      final completedDownloads = await _dbService.getAllDownloads(status: DownloadStatus.completed);

      _lastStat = DownloadStat(
        currentSpeed: globalStat.downloadSpeed,
        averageSpeed: avgSpeed,
        peakSpeed: _peakSpeed,
        activeCount: globalStat.numActive,
        waitingCount: globalStat.numWaiting,
        stoppedCount: globalStat.numStopped,
        completedCount: completedDownloads.length,
        totalDownloadedBytes: totalDownloaded,
        totalRemainingBytes: totalRemaining,
        activeConnections: totalConnections,
      );

      _statController.add(_lastStat);

      // Emit updated downloads list to listeners
      final allItems = await _dbService.getAllDownloads();
      _downloadsController.add(allItems);
    } catch (e) {
      debugPrint('[Aria2Repo] Poll error: $e');
    } finally {
      _isPolling = false;
    }
  }

  Future<void> dispose() async {
    stopPolling();
    await _statController.close();
    await _downloadsController.close();
    await _engineManager.stopEngine();
    await _dbService.close();
  }
}

