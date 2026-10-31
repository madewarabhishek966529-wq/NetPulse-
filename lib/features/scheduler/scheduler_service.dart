import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../models/download_item.dart';
import '../../repositories/download_repository.dart';

class SchedulerService {
  final DownloadRepository _repository;
  Timer? _scheduleTimer;

  SchedulerService(this._repository);

  void startScheduler() {
    _scheduleTimer?.cancel();
    _scheduleTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      checkScheduledTasks();
    });
    debugPrint('[Scheduler] Service started.');
  }

  void stopScheduler() {
    _scheduleTimer?.cancel();
    _scheduleTimer = null;
  }

  Future<void> checkScheduledTasks() async {
    try {
      final scheduledList = await _repository.dbService.getScheduledDownloads();
      final now = DateTime.now();

      for (final item in scheduledList) {
        // 1. Check Start Time
        if (item.scheduledStartTime != null && now.isAfter(item.scheduledStartTime!)) {
          if (item.status == DownloadStatus.paused || item.status == DownloadStatus.waiting) {
            debugPrint('[Scheduler] Starting scheduled task: ${item.fileName}');
            await _repository.resumeDownload(item.gid);
          }
        }

        // 2. Check End/Pause Time
        if (item.scheduledEndTime != null && now.isAfter(item.scheduledEndTime!)) {
          if (item.status == DownloadStatus.active) {
            debugPrint('[Scheduler] Pausing scheduled task by end-time: ${item.fileName}');
            await _repository.pauseDownload(item.gid);
          }
        }
      }

      // 3. Process Priority Queue
      await _processPriorityQueue();
    } catch (e) {
      debugPrint('[Scheduler] Error checking tasks: $e');
    }
  }

  Future<void> _processPriorityQueue() async {
    final settings = await _repository.dbService.loadSettings();
    final maxConcurrent = settings.maxSimultaneousDownloads;

    final activeItems = await _repository.dbService.getAllDownloads(status: DownloadStatus.active);
    if (activeItems.length < maxConcurrent) {
      final waitingItems = await _repository.dbService.getAllDownloads(status: DownloadStatus.waiting);
      if (waitingItems.isNotEmpty) {
        // Sort by priority: high -> normal -> low, then createdAt
        waitingItems.sort((a, b) {
          final pA = _priorityWeight(a.priority);
          final pB = _priorityWeight(b.priority);
          if (pA != pB) return pB.compareTo(pA);
          return a.createdAt.compareTo(b.createdAt);
        });

        final slotsToFill = maxConcurrent - activeItems.length;
        for (int i = 0; i < slotsToFill && i < waitingItems.length; i++) {
          final nextItem = waitingItems[i];
          debugPrint('[Scheduler] Queue advancing: ${nextItem.fileName} (Priority: ${nextItem.priority.name})');
          await _repository.resumeDownload(nextItem.gid);
        }
      }
    }
  }

  int _priorityWeight(DownloadPriority priority) {
    switch (priority) {
      case DownloadPriority.high:
        return 3;
      case DownloadPriority.normal:
        return 2;
      case DownloadPriority.low:
        return 1;
    }
  }
}
