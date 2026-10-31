import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse/services/aria2/aria2_client.dart';
import 'package:netpulse/services/aria2/aria2_engine_manager.dart';

void main() {
  group('Live Aria2 Engine Integration Tests', () {
    late Aria2EngineManager manager;
    late Aria2Client client;

    setUpAll(() async {
      manager = Aria2EngineManager();
      client = await manager.startEngine(preferredPort: 6815);
    });

    tearDownAll(() async {
      await manager.stopEngine();
    });

    test('Engine starts and returns valid version metadata via JSON-RPC', () async {
      final ver = await client.getVersion();
      expect(ver.containsKey('version'), isTrue);
      expect(ver.containsKey('enabledFeatures'), isTrue);
      final features = List<String>.from(ver['enabledFeatures']);
      expect(features.contains('HTTPS'), isTrue);
      expect(features.contains('Async DNS'), isTrue);
    });

    test('Global statistics are reported from live engine', () async {
      final stat = await client.getGlobalStat();
      expect(stat.downloadSpeed, greaterThanOrEqualTo(0));
      expect(stat.uploadSpeed, greaterThanOrEqualTo(0));
      expect(stat.numActive, greaterThanOrEqualTo(0));
    });

    test('Engine handles addUri, tellStatus, pause, unpause, and remove', () async {
      final tempDir = await Directory.systemTemp.createTemp('netpulse_live_test_');

      try {
        // Add a test URI with paused state so it doesn't try to download external data in isolated test
        final gid = await client.addUri(
          ['https://httpbin.org/bytes/1024'],
          options: {
            'dir': tempDir.path,
            'out': 'test_download.bin',
            'pause': 'true',
            'split': '2',
            'max-connection-per-server': '2',
          },
        );

        expect(gid.isNotEmpty, isTrue);

        // Tell status
        final status = await client.tellStatus(gid);
        expect(status.gid, gid);
        expect(status.status, anyOf('paused', 'waiting'));

        // Unpause
        final unpauseRes = await client.unpause(gid);
        expect(unpauseRes, gid);

        // Re-pause
        final pauseRes = await client.pause(gid);
        expect(pauseRes, gid);

        // Remove
        final removeRes = await client.remove(gid);
        expect(removeRes, gid);
      } finally {
        if (tempDir.existsSync()) {
          try {
            tempDir.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    });

    test('Global options can be configured dynamically (speed limits)', () async {
      await client.changeGlobalOption({
        'max-overall-download-limit': '1048576', // 1 MB/s
      });

      final options = await client.getGlobalOption();
      expect(options['max-overall-download-limit'], '1048576');

      // Reset to unlimited
      await client.changeGlobalOption({
        'max-overall-download-limit': '0',
      });
    });
  });
}

