import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/download_item.dart';

class StatusBadge extends StatelessWidget {
  final DownloadStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (status) {
      case DownloadStatus.active:
        bg = AppColors.electricBlue.withOpacity(0.15);
        fg = AppColors.electricBlue;
        icon = Icons.arrow_downward_rounded;
        break;
      case DownloadStatus.waiting:
        bg = AppColors.amberWarning.withOpacity(0.15);
        fg = AppColors.amberWarning;
        icon = Icons.hourglass_top_rounded;
        break;
      case DownloadStatus.paused:
        bg = AppColors.textMutedDark.withOpacity(0.15);
        fg = AppColors.textSecondaryDark;
        icon = Icons.pause_rounded;
        break;
      case DownloadStatus.completed:
        bg = AppColors.emeraldGreen.withOpacity(0.15);
        fg = AppColors.emeraldGreen;
        icon = Icons.check_circle_outline_rounded;
        break;
      case DownloadStatus.error:
        bg = AppColors.coralRed.withOpacity(0.15);
        fg = AppColors.coralRed;
        icon = Icons.error_outline_rounded;
        break;
      case DownloadStatus.removed:
        bg = AppColors.textMutedDark.withOpacity(0.15);
        fg = AppColors.textMutedDark;
        icon = Icons.delete_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

