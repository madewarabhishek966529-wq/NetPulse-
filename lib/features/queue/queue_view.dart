import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/download_item.dart';
import '../../repositories/download_repository.dart';
import '../downloads/download_provider.dart';

class QueueView extends StatefulWidget {
  const QueueView({super.key});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  int _maxConcurrent = 3;

  String _formatSize(int bytes) {
    if (bytes <= 0) return 'Size pending';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final queuedItems = downloadProvider.queuedDownloads;
    final activeItems = downloadProvider.activeDownloads;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.amberWarning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.amberWarning.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    color: AppColors.amberWarning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Download Queue Manager',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.amberWarning.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.amberWarning.withOpacity(0.4)),
                            ),
                            child: Text(
                              '${queuedItems.length} Waiting',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.amberWarning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Control bandwidth allocation, concurrency limits, and scheduled task priorities.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Controls Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded, size: 18, color: AppColors.electricBlue),
                  const SizedBox(width: 8),
                  const Text(
                    'Max Simultaneous Downloads:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: _maxConcurrent,
                    dropdownColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    underline: const SizedBox(),
                    items: [1, 2, 3, 5, 8, 10].map((val) {
                      return DropdownMenuItem<int>(
                        value: val,
                        child: Text('$val tasks', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _maxConcurrent = val);
                      }
                    },
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('Start Next in Queue'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emeraldGreen,
                      side: BorderSide(color: AppColors.emeraldGreen.withOpacity(0.5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: queuedItems.isEmpty
                        ? null
                        : () {
                            final first = queuedItems.first;
                            context.read<DownloadRepository>().resumeDownload(first.id);
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Queue List
            Expanded(
              child: queuedItems.isEmpty
                  ? _buildEmptyQueue(isDark, activeItems.length)
                  : ListView.builder(
                      itemCount: queuedItems.length,
                      itemBuilder: (context, index) {
                        final item = queuedItems[index];
                        return _buildQueueCard(item, index, queuedItems.length, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueue(bool isDark, int activeCount) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.done_all_rounded,
            size: 56,
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.2),
          ),
          const SizedBox(height: 14),
          const Text(
            'Queue Is Empty',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            activeCount > 0
                ? '$activeCount downloads are currently active at maximum speed.'
                : 'All tasks completed. New additions will begin immediately.',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueCard(DownloadItem item, int index, int total, bool isDark) {
    final repo = context.read<DownloadRepository>();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          // Queue order index
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.amberWarning.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#${index + 1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.amberWarning),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // File Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatSize(item.totalBytes),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryDark),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Target: ${item.savePath}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Actions
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded, color: AppColors.emeraldGreen, size: 20),
            tooltip: 'Start Now',
            onPressed: () => repo.resumeDownload(item.id),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.coralRed, size: 18),
            tooltip: 'Cancel & Remove',
            onPressed: () => repo.cancelDownload(item.id),
          ),
        ],
      ),
    );
  }
}

