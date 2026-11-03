import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../features/downloads/download_provider.dart';
import '../services/notifications/notification_service.dart';

class CustomTitleBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onAddDownload;
  final VoidCallback onOpenSettings;
  final VoidCallback? onToggleNotifications;

  const CustomTitleBar({
    super.key,
    required this.onAddDownload,
    required this.onOpenSettings,
    this.onToggleNotifications,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<NotificationService>();
    final downloadProvider = context.watch<DownloadProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // NetPulse Logo & Brand
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  image: const DecorationImage(
                    image: AssetImage('assets/icons/logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ShaderMask(
                shaderCallback: (bounds) => AppColors.brandGradient.createShader(bounds),
                child: const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.electricBlue.withOpacity(0.3)),
                ),
                child: const Text(
                  'v1.0',
                  style: TextStyle(fontSize: 10, color: AppColors.electricBlue, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(width: 32),

          // Search Downloads Field
          Expanded(
            child: Container(
              height: 32,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: TextField(
                onChanged: (val) => downloadProvider.setSearchQuery(val),
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search downloads, URLs, or files...',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Add URL Button
          ElevatedButton.icon(
            onPressed: onAddDownload,
            icon: const Icon(Icons.add_link_rounded, size: 16),
            label: const Text('Add URL'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),

          const SizedBox(width: 12),

          // Notifications Button
          Stack(
            children: [
              IconButton(
                onPressed: onToggleNotifications,
                icon: const Icon(Icons.notifications_none_rounded, size: 20),
                tooltip: 'Notifications',
                splashRadius: 18,
              ),
              if (notificationService.unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.coralRed,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      '${notificationService.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Settings Button
          IconButton(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: 'Settings',
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}
