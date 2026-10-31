import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/download_item.dart';
import '../downloads/download_provider.dart';
import '../downloads/widgets/download_item_card.dart';

class SchedulerView extends StatelessWidget {
  const SchedulerView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloadProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheduledItems = provider.scheduledDownloads;
    final queuedItems = provider.queuedDownloads;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 24, color: AppColors.neonPurple),
                const SizedBox(width: 10),
                Text(
                  'Download Scheduler & Priority Queue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Scheduler Info Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neonPurple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.neonPurple.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_mode_rounded, color: AppColors.neonPurple, size: 28),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automated Schedule Engine Active',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.neonPurple),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Downloads with configured start times will automatically trigger and download sequentially according to their priority level.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Timed Scheduled Downloads
            Text(
              'Scheduled Tasks (${scheduledItems.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            if (scheduledItems.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Center(
                  child: Text(
                    'No timed downloads scheduled. Enable "Schedule" in the Add Download dialog.',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: scheduledItems.length,
                itemBuilder: (context, index) {
                  final item = scheduledItems[index];
                  return DownloadItemCard(item: item);
                },
              ),
            ],

            const SizedBox(height: 24),

            // Sequential Waiting Queue
            Text(
              'Sequential Priority Queue (${queuedItems.length})',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            if (queuedItems.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Center(
                  child: Text(
                    'Queue is empty. New downloads start immediately or queue automatically.',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ),
              ),
            ] else ...[
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: queuedItems.length,
                itemBuilder: (context, index) {
                  return DownloadItemCard(item: queuedItems[index]);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

