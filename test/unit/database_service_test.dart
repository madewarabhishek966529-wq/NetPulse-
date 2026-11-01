import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse/models/app_settings.dart';
import 'package:netpulse/models/download_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('DatabaseService Tests', () {
    test('DownloadItem model serialization and deserialization', () {
      final item = DownloadItem(
        id: 1,
        gid: 'gid123456',
        url: 'https://example.com/large_installer.iso',
        fileName: 'large_installer.iso',
        filePath: 'C:\\Downloads\\large_installer.iso',
        fileSize: 1048576000,
        downloadedSize: 524288000,
        downloadSpeed: 10485760,
        status: DownloadStatus.active,
        categoryId: 'Archives',
        connections: 8,
        priority: DownloadPriority.high,
        isScheduled: true,
      );

      final map = item.toMap();
      expect(map['gid'], 'gid123456');
      expect(map['file_size'], 1048576000);
      expect(map['status'], 'active');
      expect(map['priority'], 'high');

      final fromMap = DownloadItem.fromMap(map);
      expect(fromMap.gid, item.gid);
      expect(fromMap.url, item.url);
      expect(fromMap.fileSize, item.fileSize);
      expect(fromMap.progress, 0.5);
      expect(fromMap.remainingBytes, 524288000);
      expect(fromMap.status, DownloadStatus.active);
      expect(fromMap.priority, DownloadPriority.high);
    });

    test('AppSettings model serialization and deserialization', () {
      const settings = AppSettings(
        maxSimultaneousDownloads: 5,
        maxConnectionsPerDownload: 16,
        globalSpeedLimitBytes: 1048576,
        darkMode: true,
        compactMode: true,
      );

      final map = settings.toSettingsMap();
      expect(map['max_simultaneous_downloads'], '5');
      expect(map['max_connections_per_download'], '16');

      final fromMap = AppSettings.fromSettingsMap(map);
      expect(fromMap.maxSimultaneousDownloads, 5);
      expect(fromMap.maxConnectionsPerDownload, 16);
      expect(fromMap.globalSpeedLimitBytes, 1048576);
      expect(fromMap.darkMode, isTrue);
      expect(fromMap.compactMode, isTrue);
    });
  });
}
