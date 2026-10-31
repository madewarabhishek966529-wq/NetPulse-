import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/category_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../models/download_item.dart';
import '../downloads/download_provider.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloadProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final all = provider.allDownloads;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 24, color: AppColors.electricBlue),
                    const SizedBox(width: 10),
                    Text(
                      'Download History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final csv = await provider.repository.dbService.exportHistoryCsv();
                        final path = '${Platform.environment['USERPROFILE']}\\Downloads\\netpulse_history.csv';
                        await File(path).writeAsString(csv);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Exported history to $path'), backgroundColor: AppColors.emeraldGreen),
                          );
                        }
                      },
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text('Export CSV'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => provider.clearHistory(),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                      label: const Text('Clear History'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Table / List
            Expanded(
              child: all.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 48, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          const SizedBox(height: 12),
                          const Text('History is clean. No records found.'),
                        ],
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: ListView.separated(
                        itemCount: all.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = all[index];
                          final catIcon = CategoryConstants.getCategoryIcon(item.categoryId);
                          final catColor = CategoryConstants.getCategoryColor(item.categoryId);

                          return ListTile(
                            leading: Icon(catIcon, color: catColor),
                            title: Text(item.fileName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('${Formatters.formatBytes(item.fileSize)} • ${Formatters.formatDate(item.createdAt)} • ${item.status.displayName}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18),
                              onPressed: () {
                                if (item.id != null) {
                                  provider.deleteDownload(item.id!);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

