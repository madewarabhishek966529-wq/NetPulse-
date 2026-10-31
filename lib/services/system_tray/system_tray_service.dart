import 'package:flutter/foundation.dart';
import '../../core/utils/formatters.dart';
import '../../repositories/download_repository.dart';

class SystemTrayService {
  final DownloadRepository _repository;
  bool _isTrayInitialized = false;

  SystemTrayService(this._repository);

  bool get isTrayInitialized => _isTrayInitialized;

  Future<void> initSystemTray({
    required VoidCallback onShowWindow,
    required VoidCallback onHideWindow,
    required VoidCallback onExitApp,
  }) async {
    _isTrayInitialized = true;
    debugPrint('[SystemTray] Desktop tray integration initialized.');
  }

  void updateTraySpeed(int bytesPerSecond) {
    if (!_isTrayInitialized) return;
    final speedStr = Formatters.formatSpeed(bytesPerSecond);
    debugPrint('[SystemTray] Current Speed: $speedStr');
  }

  Future<void> pauseAllDownloads() async {
    await _repository.pauseAll();
  }

  Future<void> resumeAllDownloads() async {
    await _repository.resumeAll();
  }
}
