import 'package:intl/intl.dart';

class Formatters {
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    int i = 0;
    double dBytes = bytes.toDouble();
    while (dBytes >= 1024 && i < suffixes.length - 1) {
      dBytes /= 1024;
      i++;
    }
    return '${dBytes.toStringAsFixed(i == 0 ? 0 : decimals)} ${suffixes[i]}';
  }

  static String formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond <= 0) return '0 B/s';
    return '${formatBytes(bytesPerSecond)}/s';
  }

  static String formatEta(int remainingBytes, int currentSpeed) {
    if (currentSpeed <= 0 || remainingBytes <= 0) return '--:--';
    final seconds = remainingBytes ~/ currentSpeed;
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '${mins}m ${secs}s';
    } else {
      final hours = seconds ~/ 3600;
      final mins = (seconds % 3600) ~/ 60;
      return '${hours}h ${mins}m';
    }
  }

  static String formatDate(DateTime? date) {
    if (date == null) return '--';
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    return formatter.format(date);
  }

  static String formatPercent(double progress) {
    if (progress.isNaN || progress.isInfinite) return '0.0%';
    final pct = (progress * 100).clamp(0.0, 100.0);
    return '${pct.toStringAsFixed(1)}%';
  }
}
