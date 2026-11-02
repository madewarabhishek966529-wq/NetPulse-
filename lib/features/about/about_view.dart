import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo Badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.electricBlue, AppColors.cyberCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricBlue.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.bolt_rounded, size: 42, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 18),

                // Name & Version
                Text(
                  AppConstants.appName,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Download Smarter. Download Faster.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.electricBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Version ${AppConstants.appVersion} (Production Build) • Windows 10/11 x64',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
                  ),
                ),

                const SizedBox(height: 28),

                // Feature Highlights
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Core Architecture & Capabilities',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 14),
                      _buildFeatureTile(
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.electricBlue,
                        title: 'Smart Website URL Analyzer',
                        desc: 'Intelligently crawls publicly accessible pages to extract direct downloadable resources with automated ad and tracker filtering.',
                      ),
                      const Divider(height: 20),
                      _buildFeatureTile(
                        icon: Icons.speed_rounded,
                        color: AppColors.cyberCyan,
                        title: 'Multi-Segment Acceleration Engine',
                        desc: 'Powered by aria2c 1.37.0 over authenticated JSON-RPC with dynamic port allocation, multi-thread connection pooling, and zero-allocation Windows disk writes.',
                      ),
                      const Divider(height: 20),
                      _buildFeatureTile(
                        icon: Icons.hub_rounded,
                        color: AppColors.neonPurple,
                        title: 'BitTorrent & Magnet Swarm Engine',
                        desc: 'Hardened peer discovery with DHT routing table cache isolation, dynamic tracker lists, and atomic metadata-to-payload child GID migration.',
                      ),
                      const Divider(height: 20),
                      _buildFeatureTile(
                        icon: Icons.extension_rounded,
                        color: AppColors.emeraldGreen,
                        title: 'Chrome & Edge Browser Integration',
                        desc: 'Manifest V3 extension with native context menu shortcuts and direct HTTP API bridge for seamless one-click downloads.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tech Stack Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTechBadge('Flutter Desktop', 'Dart 3.13'),
                      _buildTechBadge('FastAPI Engine', 'Python 3.12'),
                      _buildTechBadge('aria2 Core', 'v1.37.0'),
                      _buildTechBadge('Storage', 'SQLite WAL'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTechBadge(String name, String ver) {
    return Column(
      children: [
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(ver, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondaryDark)),
      ],
    );
  }
}

