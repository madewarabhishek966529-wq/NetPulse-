import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../network/network_monitor_provider.dart';

class SpeedChart extends StatelessWidget {
  final double height;
  final bool showHeaders;

  const SpeedChart({
    super.key,
    this.height = 180,
    this.showHeaders = true,
  });

  @override
  Widget build(BuildContext context) {
    final netProvider = context.watch<NetworkMonitorProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spots = netProvider.speedSpots;

    double maxY = 100;
    if (spots.isNotEmpty) {
      for (final spot in spots) {
        if (spot.y > maxY) maxY = spot.y;
      }
    }
    maxY = (maxY * 1.25).ceilToDouble();

    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeaders) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.show_chart_rounded, size: 18, color: AppColors.electricBlue),
                    const SizedBox(width: 8),
                    Text(
                      'Real-Time Download Throughput',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.electricBlue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.electricBlue.withOpacity(0.3)),
                  ),
                  child: Text(
                    Formatters.formatSpeed(netProvider.currentStat.currentSpeed),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.electricBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: LineChart(
              LineChartData(
                minX: spots.isNotEmpty ? spots.first.x : 0,
                maxX: spots.isNotEmpty ? spots.last.x : 30,
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? (maxY / 4) : 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      interval: maxY > 0 ? (maxY / 3) : 30,
                      getTitlesWidget: (value, meta) {
                        final kb = value.toInt();
                        String label;
                        if (kb >= 1024) {
                          label = '${(kb / 1024).toStringAsFixed(1)}M';
                        } else {
                          label = '${kb}K';
                        }
                        return Text(
                          label,
                          style: TextStyle(
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    color: AppColors.electricBlue,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.electricBlue.withOpacity(0.35),
                          AppColors.darkBg.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: const FlDotData(show: false),
                  ),
                ],
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final speedBytes = (spot.y * 1024).toInt();
                        return LineTooltipItem(
                          Formatters.formatSpeed(speedBytes),
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

