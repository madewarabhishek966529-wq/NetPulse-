import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../features/downloads/download_provider.dart';

enum NavPage {
  overview,
  analyzer,
  allDownloads,
  activeDownloads,
  queuedDownloads,
  completed,
  failed,
  scheduled,
  browserIntegration,
  history,
  networkMonitor,
  settings,
  about,
}

class AppSidebar extends StatelessWidget {
  final NavPage selectedPage;
  final ValueChanged<NavPage> onPageSelected;

  const AppSidebar({
    super.key,
    required this.selectedPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeCount = downloadProvider.activeDownloads.length;
    final queuedCount = downloadProvider.queuedDownloads.length;
    final completedCount = downloadProvider.completedDownloads.length;
    final failedCount = downloadProvider.failedDownloads.length;
    final scheduledCount = downloadProvider.scheduledDownloads.length;

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Main Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildNavItem(
                  context,
                  page: NavPage.overview,
                  icon: Icons.dashboard_outlined,
                  selectedIcon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                ),
                _buildNavItem(
                  context,
                  page: NavPage.analyzer,
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome_rounded,
                  label: 'Smart Analyzer',
                  badge: 'AI',
                  badgeColor: AppColors.cyberCyan,
                ),
                _buildNavItem(
                  context,
                  page: NavPage.allDownloads,
                  icon: Icons.folder_open_outlined,
                  selectedIcon: Icons.folder_rounded,
                  label: 'Downloads',
                  badge: downloadProvider.allDownloads.isNotEmpty
                      ? '${downloadProvider.allDownloads.length}'
                      : null,
                ),
                _buildNavItem(
                  context,
                  page: NavPage.queuedDownloads,
                  icon: Icons.hourglass_empty_rounded,
                  selectedIcon: Icons.hourglass_full_rounded,
                  label: 'Download Queue',
                  badge: queuedCount > 0 ? '$queuedCount' : null,
                  badgeColor: AppColors.amberWarning,
                ),
                _buildNavItem(
                  context,
                  page: NavPage.browserIntegration,
                  icon: Icons.extension_outlined,
                  selectedIcon: Icons.extension_rounded,
                  label: 'Browser Integration',
                ),
                _buildNavItem(
                  context,
                  page: NavPage.history,
                  icon: Icons.history_rounded,
                  selectedIcon: Icons.manage_history_rounded,
                  label: 'Download History',
                ),
                _buildNavItem(
                  context,
                  page: NavPage.networkMonitor,
                  icon: Icons.speed_outlined,
                  selectedIcon: Icons.speed_rounded,
                  label: 'Network Monitor',
                ),
                _buildNavItem(
                  context,
                  page: NavPage.settings,
                  icon: Icons.settings_outlined,
                  selectedIcon: Icons.settings_rounded,
                  label: 'Settings',
                ),
                _buildNavItem(
                  context,
                  page: NavPage.about,
                  icon: Icons.info_outline_rounded,
                  selectedIcon: Icons.info_rounded,
                  label: 'About NetPulse',
                ),
              ],
            ),
          ),

          // Bottom Quick Engine Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.emeraldGreen,
                        blurRadius: 4,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Engine Active',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'aria2c JSON-RPC',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required NavPage page,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = selectedPage == page;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => onPageSelected(page),
          borderRadius: BorderRadius.circular(8),
          hoverColor: isDark ? AppColors.darkCardHover : AppColors.lightCardHover,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.darkCard : AppColors.lightCardHover)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.electricBlue.withOpacity(0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 18,
                  color: isSelected
                      ? AppColors.electricBlue
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                          : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppColors.textMutedDark).withOpacity(0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (badgeColor ?? AppColors.textMutedDark).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: badgeColor ?? AppColors.textSecondaryDark,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

