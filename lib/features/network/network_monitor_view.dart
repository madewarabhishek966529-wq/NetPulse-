import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../dashboard/widgets/speed_chart.dart';
import '../dashboard/widgets/stat_card.dart';
import 'network_monitor_provider.dart';

class NetworkMonitorView extends StatefulWidget {
  const NetworkMonitorView({super.key});

  @override
  State<NetworkMonitorView> createState() => _NetworkMonitorViewState();
}

class _NetworkMonitorViewState extends State<NetworkMonitorView> {
  final _limitController = TextEditingController();
  int _globalLimitKb = 0;
  int _maxConcurrent = 3;

  @override
  void initState() {
    super.initState();
    final netProvider = context.read<NetworkMonitorProvider>();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // will be loaded from provider
  }

  void _applyLimit(int kb) {
    setState(() => _globalLimitKb = kb);
    final bytesPerSec = kb * 1024;
    context.read<NetworkMonitorProvider>().setGlobalLimit(bytesPerSec);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          kb == 0
              ? 'Global speed limit removed (Unlimited)'
              : 'Global limit set to ${kb} KB/s',
        ),
        backgroundColor: AppColors.electricBlue,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final netProvider = context.watch<NetworkMonitorProvider>();
    final stat = netProvider.currentStat;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header
            Row(
              children: [
                const Icon(
                  Icons.speed_rounded,
                  size: 24,
                  color: AppColors.electricBlue,
                ),
                const SizedBox(width: 10),
                Text(
                  'Advanced Network Monitor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.emeraldGreen.withOpacity(0.3),
                    ),
                  ),
                  child: const Text(
                    'Real-Time Telemetry',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.emeraldGreen,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Statistics Grid
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1,
              children: [
                StatCard(
                  title: 'Current Speed',
                  value: Formatters.formatSpeed(stat.currentSpeed),
                  subtitle: '${stat.activeConnections} Active Sockets',
                  icon: Icons.speed_rounded,
                  accentColor: AppColors.electricBlue,
                ),
                StatCard(
                  title: 'Average Throughput',
                  value: Formatters.formatSpeed(stat.averageSpeed),
                  subtitle: 'Calculated over 60s',
                  icon: Icons.stacked_line_chart_rounded,
                  accentColor: AppColors.vibrantBlue,
                ),
                StatCard(
                  title: 'Peak Speed Recorded',
                  value: Formatters.formatSpeed(netProvider.peakSpeed),
                  subtitle: 'Session maximum',
                  icon: Icons.bolt_rounded,
                  accentColor: AppColors.neonPurple,
                ),
                StatCard(
                  title: 'Total Transferred',
                  value: Formatters.formatBytes(stat.totalDownloadedBytes),
                  subtitle:
                      'Remaining: ${Formatters.formatBytes(stat.totalRemainingBytes)}',
                  icon: Icons.cloud_download_rounded,
                  accentColor: AppColors.emeraldGreen,
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Expanded Real-Time Speed Chart
            const SpeedChart(height: 240),

            const SizedBox(height: 22),

            // Bandwidth & Performance Controls
            Text(
              'Bandwidth & Performance Controls',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Global Download Speed Limit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _globalLimitKb == 0
                            ? 'Unlimited'
                            : '${_globalLimitKb} KB/s',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.electricBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Preset Buttons
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildPresetChip('Unlimited', 0),
                      _buildPresetChip('500 KB/s', 500),
                      _buildPresetChip('1 MB/s', 1024),
                      _buildPresetChip('2 MB/s', 2048),
                      _buildPresetChip('5 MB/s', 5120),
                      _buildPresetChip('10 MB/s', 10240),
                      _buildPresetChip('25 MB/s', 25600),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 14),

                  // Simultaneous Downloads Limit
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Maximum Simultaneous Downloads',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_maxConcurrent active tasks',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.neonPurple,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxConcurrent.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '$_maxConcurrent',
                    onChanged: (val) {
                      setState(() => _maxConcurrent = val.toInt());
                      netProvider.setMaxConcurrent(_maxConcurrent);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int kb) {
    final isSelected = (_globalLimitKb == kb);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ActionChip(
      label: Text(label),
      onPressed: () => _applyLimit(kb),
      backgroundColor: isSelected
          ? AppColors.electricBlue.withOpacity(0.18)
          : (isDark ? AppColors.darkBg : AppColors.lightBg),
      side: BorderSide(
        color: isSelected
            ? AppColors.electricBlue
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected
            ? AppColors.electricBlue
            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      ),
    );
  }
}
