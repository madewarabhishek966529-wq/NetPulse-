import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/category_constants.dart';
import '../../core/theme/app_colors.dart';
import 'download_provider.dart';
import 'widgets/download_item_card.dart';

class DownloadsView extends StatelessWidget {
  final DownloadFilterStatus? initialFilter;

  const DownloadsView({super.key, this.initialFilter});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DownloadProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = provider.filteredDownloads;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Action Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.folder_open_rounded, size: 22, color: AppColors.electricBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Download Manager',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.electricBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${items.length} items',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.electricBlue,
                        ),
                      ),
                    ),
                  ],
                ),

                // Bulk Toolbar
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => provider.pauseAll(),
                      icon: const Icon(Icons.pause_rounded, size: 16),
                      label: const Text('Pause All'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => provider.resumeAll(),
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('Resume All'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final csv = await provider.repository.dbService.exportHistoryCsv();
                        final path = '${Platform.environment['USERPROFILE']}\\Downloads\\netpulse_export.csv';
                        await File(path).writeAsString(csv);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Exported history to $path'),
                              backgroundColor: AppColors.emeraldGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.file_download_outlined, size: 16),
                      label: const Text('Export CSV'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => provider.clearHistory(),
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Clear Completed'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Filter Tabs & Category Selector Row
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  // Status Filter Chips
                  _buildStatusFilterChip(context, provider, DownloadFilterStatus.all, 'All'),
                  _buildStatusFilterChip(context, provider, DownloadFilterStatus.active, 'Active'),
                  _buildStatusFilterChip(context, provider, DownloadFilterStatus.queued, 'Queued'),
                  _buildStatusFilterChip(context, provider, DownloadFilterStatus.completed, 'Completed'),
                  _buildStatusFilterChip(context, provider, DownloadFilterStatus.failed, 'Failed'),
                  _buildStatusFilterChip(context, provider, DownloadFilterStatus.scheduled, 'Scheduled'),

                  const Spacer(),

                  // Category Selector
                  DropdownButton<String>(
                    value: provider.selectedCategory,
                    underline: const SizedBox(),
                    items: ['All', ...CategoryConstants.defaultCategories].map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(cat, style: const TextStyle(fontSize: 12)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) provider.setSelectedCategory(val);
                    },
                  ),

                  const SizedBox(width: 12),

                  // Sort Dropdown
                  DropdownButton<DownloadSortBy>(
                    value: provider.sortBy,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: DownloadSortBy.dateDesc, child: Text('Date: Newest First', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: DownloadSortBy.dateAsc, child: Text('Date: Oldest First', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: DownloadSortBy.sizeDesc, child: Text('Size: Largest First', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: DownloadSortBy.sizeAsc, child: Text('Size: Smallest First', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: DownloadSortBy.nameAsc, child: Text('Name (A-Z)', style: TextStyle(fontSize: 12))),
                      DropdownMenuItem(value: DownloadSortBy.speedDesc, child: Text('Download Speed', style: TextStyle(fontSize: 12))),
                    ],
                    onChanged: (val) {
                      if (val != null) provider.setSortBy(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Downloads List
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No downloads found matching current filters',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return DownloadItemCard(item: items[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilterChip(
    BuildContext context,
    DownloadProvider provider,
    DownloadFilterStatus status,
    String label,
  ) {
    final isSelected = provider.filterStatus == status;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => provider.setFilterStatus(status),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? Colors.black
              : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
        ),
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.electricBlue,
        showCheckmark: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected
                ? AppColors.electricBlue
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
      ),
    );
  }
}

