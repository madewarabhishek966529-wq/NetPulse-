import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    DateTime? timestamp,
    this.icon = Icons.notifications_rounded,
    this.color = const Color(0xFF00E5FF),
  }) : timestamp = timestamp ?? DateTime.now();
}

class NotificationService extends ChangeNotifier {
  final List<NotificationItem> _notifications = [];
  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;
  set soundEnabled(bool val) {
    _soundEnabled = val;
    notifyListeners();
  }

  List<NotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.length;

  void notify({
    required String title,
    required String message,
    IconData icon = Icons.notifications_rounded,
    Color color = const Color(0xFF00E5FF),
  }) {
    final item = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      icon: icon,
      color: color,
    );
    _notifications.insert(0, item);
    if (_notifications.length > 50) {
      _notifications.removeLast();
    }
    notifyListeners();
  }

  void notifyDownloadCompleted(String fileName) {
    notify(
      title: 'Download Completed',
      message: '"$fileName" has finished downloading successfully.',
      icon: Icons.check_circle_rounded,
      color: const Color(0xFF00E676),
    );
  }

  void notifyDownloadFailed(String fileName, String? reason) {
    notify(
      title: 'Download Failed',
      message: 'Failed to download "$fileName": ${reason ?? "Network error"}',
      icon: Icons.error_rounded,
      color: const Color(0xFFFF5252),
    );
  }

  void notifyScheduledStarted(String fileName) {
    notify(
      title: 'Scheduled Download Started',
      message: '"$fileName" started automatically per your schedule.',
      icon: Icons.schedule_rounded,
      color: const Color(0xFF7C4DFF),
    );
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
