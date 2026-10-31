import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../../models/download_item.dart';
import '../../repositories/download_repository.dart';

class NativeHostManager {
  final DownloadRepository _repository;
  Timer? _incomingWatcherTimer;
  bool _isWatching = false;

  NativeHostManager(this._repository);

  String get _incomingDirPath {
    final localAppData = Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
    return p.join(localAppData, 'NetPulse', 'incoming');
  }

  /// Start watching the incoming folder for browser downloads
  void startIncomingWatcher({required void Function(DownloadItem item) onDownloadAdded}) {
    if (_isWatching) return;
    _isWatching = true;

    final dir = Directory(_incomingDirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _incomingWatcherTimer?.cancel();
    _incomingWatcherTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      await _checkIncomingFolder(onDownloadAdded);
    });

    debugPrint('[BrowserBridge] Incoming watcher started at $_incomingDirPath');
  }

  void stopIncomingWatcher() {
    _incomingWatcherTimer?.cancel();
    _incomingWatcherTimer = null;
    _isWatching = false;
  }

  Future<void> _checkIncomingFolder(void Function(DownloadItem item) onDownloadAdded) async {
    final dir = Directory(_incomingDirPath);
    if (!dir.existsSync()) return;

    try {
      final files = dir.listSync().whereType<File>().toList();
      for (final file in files) {
        if (p.extension(file.path).toLowerCase() == '.json') {
          try {
            final content = await file.readAsString();
            final data = jsonDecode(content) as Map<String, dynamic>;
            final url = data['url'] as String?;
            var fileName = data['fileName'] as String? ?? '';

            if (url != null && url.isNotEmpty) {
              if (fileName.isEmpty) {
                fileName = p.basename(Uri.parse(url).path);
                if (fileName.isEmpty) {
                  fileName = 'browser_download_${DateTime.now().millisecondsSinceEpoch}';
                }
              }

              final settings = await _repository.dbService.loadSettings();
              final targetDir = settings.defaultDownloadFolder.isNotEmpty
                  ? settings.defaultDownloadFolder
                  : (Platform.environment['USERPROFILE'] != null
                      ? p.join(Platform.environment['USERPROFILE']!, 'Downloads')
                      : Directory.current.path);

              final item = await _repository.addDownload(
                url: url,
                fileName: fileName,
                targetDirectory: targetDir,
                connections: settings.maxConnectionsPerDownload,
                category: settings.defaultCategory,
              );

              onDownloadAdded(item);
              debugPrint('[BrowserBridge] Successfully ingested browser download: $fileName');
            }
          } catch (e) {
            debugPrint('[BrowserBridge] Error parsing incoming file: $e');
          } finally {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('[BrowserBridge] Watcher error: $e');
    }
  }

  /// Check if Chrome native messaging is registered
  Future<bool> isChromeRegistered() async {
    return _checkRegistryKey(r'HKCU\Software\Google\Chrome\NativeMessagingHosts\com.netpulse.downloader');
  }

  /// Check if Edge native messaging is registered
  Future<bool> isEdgeRegistered() async {
    return _checkRegistryKey(r'HKCU\Software\Microsoft\Edge\NativeMessagingHosts\com.netpulse.downloader');
  }

  /// Check if Firefox native messaging is registered
  Future<bool> isFirefoxRegistered() async {
    return _checkRegistryKey(r'HKCU\Software\Mozilla\NativeMessagingHosts\com.netpulse.downloader');
  }

  Future<bool> _checkRegistryKey(String keyPath) async {
    try {
      final res = await Process.run('reg.exe', ['query', keyPath]);
      return res.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Register native messaging host in Windows registry
  Future<bool> registerBrowsers() async {
    try {
      final currentDir = Directory.current.path;
      final chromeManifest = p.join(currentDir, 'browser_extension', 'native_host', 'com.netpulse.downloader.json');
      final ffManifest = p.join(currentDir, 'browser_extension', 'native_host', 'firefox', 'com.netpulse.downloader.json');

      await Process.run('reg.exe', [
        'add',
        r'HKCU\Software\Google\Chrome\NativeMessagingHosts\com.netpulse.downloader',
        '/ve',
        '/t',
        'REG_SZ',
        '/d',
        chromeManifest,
        '/f'
      ]);

      await Process.run('reg.exe', [
        'add',
        r'HKCU\Software\Microsoft\Edge\NativeMessagingHosts\com.netpulse.downloader',
        '/ve',
        '/t',
        'REG_SZ',
        '/d',
        chromeManifest,
        '/f'
      ]);

      await Process.run('reg.exe', [
        'add',
        r'HKCU\Software\Mozilla\NativeMessagingHosts\com.netpulse.downloader',
        '/ve',
        '/t',
        'REG_SZ',
        '/d',
        ffManifest,
        '/f'
      ]);

      return true;
    } catch (e) {
      debugPrint('[BrowserBridge] Registration error: $e');
      return false;
    }
  }

  /// Unregister native messaging host
  Future<bool> unregisterBrowsers() async {
    try {
      await Process.run('reg.exe', ['delete', r'HKCU\Software\Google\Chrome\NativeMessagingHosts\com.netpulse.downloader', '/f']);
      await Process.run('reg.exe', ['delete', r'HKCU\Software\Microsoft\Edge\NativeMessagingHosts\com.netpulse.downloader', '/f']);
      await Process.run('reg.exe', ['delete', r'HKCU\Software\Mozilla\NativeMessagingHosts\com.netpulse.downloader', '/f']);
      return true;
    } catch (_) {
      return false;
    }
  }
}

