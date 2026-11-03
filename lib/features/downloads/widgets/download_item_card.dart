import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import '../../../core/constants/category_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/download_item.dart';
import '../../file_verification/checksum_dialog.dart';
import '../download_provider.dart';

class DownloadItemCard extends StatelessWidget {
  final DownloadItem item;

  const DownloadItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.read<DownloadProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final catColor = CategoryConstants.getCategoryColor(item.categoryId);
    final catIcon = CategoryConstants.getCategoryIcon(item.categoryId);
    final progress = item.progress;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Category Icon Box
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.isTorrent ? AppColors.cyberCyan.withOpacity(0.15) : catColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: item.isTorrent ? AppColors.cyberCyan.withOpacity(0.4) : catColor.withOpacity(0.25),
                  ),
                ),
                child: Icon(
                  item.isTorrent ? Icons.hub_rounded : catIcon,
                  color: item.isTorrent ? AppColors.cyberCyan : catColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Filename and URL
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.isTorrent) ...[
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.cyberCyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.cyberCyan.withOpacity(0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 11, color: AppColors.cyberCyan),
                                SizedBox(width: 2),
                                Text(
                                  'TORRENT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.cyberCyan,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
                            item.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Status and Connection Count
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBg : AppColors.lightBg,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.isTorrent ? Icons.group_work_rounded : Icons.cable_rounded,
                          size: 12,
                          color: item.isTorrent ? AppColors.cyberCyan : AppColors.electricBlue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.isTorrent
                              ? '${item.connections} peers (${item.seeders} seeds)'
                              : '${item.connections} conn',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusChip(item.status),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.status == DownloadStatus.completed ? 1.0 : progress,
              minHeight: 6,
              backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
              valueColor: AlwaysStoppedAnimation<Color>(
                item.status == DownloadStatus.error
                    ? AppColors.coralRed
                    : (item.status == DownloadStatus.completed
                        ? AppColors.emeraldGreen
                        : AppColors.electricBlue),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Progress statistics row & action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stats
              Row(
                children: [
                  Text(
                    Formatters.formatPercent(progress),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.isTorrent && item.fileSize <= 0
                        ? 'Fetching swarm metadata...'
                        : '${Formatters.formatBytes(item.downloadedSize)} / ${item.fileSize > 0 ? Formatters.formatBytes(item.fileSize) : "--"}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (item.status == DownloadStatus.active) ...[
                    Row(
                      children: [
                        const Icon(Icons.speed_rounded, size: 13, color: AppColors.electricBlue),
                        const SizedBox(width: 3),
                        Text(
                          Formatters.formatSpeed(item.downloadSpeed),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.electricBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 13, color: AppColors.textMutedDark),
                        const SizedBox(width: 3),
                        Text(
                          'ETA: ${Formatters.formatEta(item.remainingBytes, item.downloadSpeed)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Action Buttons
              Row(
                children: [
                  // Pause / Resume
                  if (item.status == DownloadStatus.active)
                    IconButton(
                      icon: const Icon(Icons.pause_rounded, size: 18),
                      tooltip: 'Pause',
                      onPressed: () => downloadProvider.pause(item.gid),
                      splashRadius: 16,
                      color: AppColors.amberWarning,
                    )
                  else if (item.status == DownloadStatus.paused || item.status == DownloadStatus.waiting)
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      tooltip: 'Resume',
                      onPressed: () => downloadProvider.resume(item.gid),
                      splashRadius: 16,
                      color: AppColors.emeraldGreen,
                    ),

                  // Restart
                  if (item.status == DownloadStatus.completed || item.status == DownloadStatus.error)
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'Restart Download',
                      onPressed: () => downloadProvider.restart(item.id!),
                      splashRadius: 16,
                    ),

                  // Open Folder
                  IconButton(
                    icon: const Icon(Icons.folder_open_rounded, size: 18),
                    tooltip: 'Open in Explorer',
                    onPressed: () => _openInExplorer(item.filePath),
                    splashRadius: 16,
                  ),

                  // Checksum Verification Tool
                  IconButton(
                    icon: const Icon(Icons.verified_outlined, size: 18),
                    tooltip: 'Verify Checksum (SHA-256)',
                    onPressed: () => _showChecksumDialog(context, item),
                    splashRadius: 16,
                  ),

                  // Copy URL
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'Copy URL',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: item.url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL copied to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    splashRadius: 16,
                  ),

                  // Delete / Cancel
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    tooltip: 'Delete',
                    color: AppColors.coralRed,
                    onPressed: () => _confirmDelete(context, downloadProvider, item),
                    splashRadius: 16,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(DownloadStatus status) {
    Color color;
    switch (status) {
      case DownloadStatus.active:
        color = AppColors.electricBlue;
        break;
      case DownloadStatus.waiting:
        color = AppColors.amberWarning;
        break;
      case DownloadStatus.paused:
        color = AppColors.textMutedDark;
        break;
      case DownloadStatus.completed:
        color = AppColors.emeraldGreen;
        break;
      case DownloadStatus.error:
        color = AppColors.coralRed;
        break;
      case DownloadStatus.removed:
        color = AppColors.textMutedDark;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _openInExplorer(String filePath) {
    try {
      final dir = p.dirname(filePath);
      if (Platform.isWindows) {
        Process.run('explorer.exe', ['/select,', filePath]);
      } else {
        Process.run('open', [dir]);
      }
    } catch (_) {}
  }

  void _showChecksumDialog(BuildContext context, DownloadItem item) {
    showDialog(
      context: context,
      builder: (ctx) => ChecksumDialog(filePath: item.filePath, expectedChecksum: item.checksum),
    );
  }

  void _confirmDelete(BuildContext context, DownloadProvider provider, DownloadItem item) {
    bool deleteLocalFile = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Delete Download'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to remove "${item.fileName}"?'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: deleteLocalFile,
                      onChanged: (val) => setState(() => deleteLocalFile = val ?? false),
                    ),
                    const Text('Also delete downloaded file from disk'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.coralRed),
                onPressed: () {
                  Navigator.pop(ctx);
                  provider.cancel(item.gid, deleteFile: deleteLocalFile);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}

