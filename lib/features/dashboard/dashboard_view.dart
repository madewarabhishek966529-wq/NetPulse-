import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../downloads/download_provider.dart';
import '../downloads/widgets/download_item_card.dart';
import 'widgets/speed_chart.dart';
import 'widgets/stat_card.dart';

class DashboardView extends StatelessWidget {
  final VoidCallback onAddDownload;

  const DashboardView({super.key, required this.onAddDownload});

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final stat = downloadProvider.currentStat;
    final activeDownloads = downloadProvider.activeDownloads;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Metric Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : (constraints.maxWidth > 600 ? 2 : 1);

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.1,
                  children: [
                    StatCard(
                      title: 'Current Speed',
                      value: Formatters.formatSpeed(stat.currentSpeed),
                      subtitle: '${stat.activeConnections} active connections',
                      icon: Icons.speed_rounded,
                      accentColor: AppColors.electricBlue,
                    ),
                    StatCard(
                      title: 'Peak Throughput',
                      value: Formatters.formatSpeed(stat.peakSpeed),
                      subtitle: 'Avg: ${Formatters.formatSpeed(stat.averageSpeed)}',
                      icon: Icons.trending_up_rounded,
                      accentColor: AppColors.neonPurple,
                    ),
                    StatCard(
                      title: 'Active / Queued',
                      value: '${stat.activeCount} / ${stat.waitingCount}',
                      subtitle: '${stat.completedCount} completed',
                      icon: Icons.download_rounded,
                      accentColor: AppColors.amberWarning,
                    ),
                    StatCard(
                      title: 'Data Transferred',
                      value: Formatters.formatBytes(stat.totalDownloadedBytes),
                      subtitle: 'Remaining: ${Formatters.formatBytes(stat.totalRemainingBytes)}',
                      icon: Icons.data_usage_rounded,
                      accentColor: AppColors.emeraldGreen,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 18),

            // Middle Section: Live Speed Chart
            const SpeedChart(height: 190),

            const SizedBox(height: 22),

            // Active Downloads Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.downloading_rounded, size: 20, color: AppColors.electricBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Active Transfers (${activeDownloads.length})',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                if (activeDownloads.isNotEmpty)
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => downloadProvider.pauseAll(),
                        icon: const Icon(Icons.pause_rounded, size: 16),
                        label: const Text('Pause All'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => downloadProvider.resumeAll(),
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Resume All'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 12),

            if (activeDownloads.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard.withOpacity(0.5) : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_download_outlined,
                      size: 48,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No active downloads',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add URL" or capture downloads from your browser.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: onAddDownload,
                      icon: const Icon(Icons.add_link_rounded, size: 16),
                      label: const Text('Add Download URL'),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeDownloads.length,
                itemBuilder: (context, index) {
                  return DownloadItemCard(item: activeDownloads[index]);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

