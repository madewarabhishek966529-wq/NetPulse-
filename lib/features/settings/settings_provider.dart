import 'package:flutter/material.dart';
import '../../core/utils/file_utils.dart';
import '../../models/app_settings.dart';
import '../../repositories/download_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final DownloadRepository _repository;
  AppSettings _settings = const AppSettings();
  bool _isLoaded = false;

  SettingsProvider({required DownloadRepository repository})
      : _repository = repository {
    _load();
  }

  AppSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  Future<void> _load() async {
    _settings = await _repository.dbService.loadSettings();

    // Default download folder fallback
    if (_settings.defaultDownloadFolder.isEmpty) {
      final defaultDir = await FileUtils.getDefaultDownloadDirectory();
      _settings = _settings.copyWith(defaultDownloadFolder: defaultDir);
      await _repository.dbService.saveSettings(_settings);
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _repository.dbService.saveSettings(newSettings);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    await updateSettings(_settings.copyWith(darkMode: value));
  }

  Future<void> setAccentColor(String hex) async {
    await updateSettings(_settings.copyWith(accentColorHex: hex));
  }

  Future<void> setCompactMode(bool value) async {
    await updateSettings(_settings.copyWith(compactMode: value));
  }

  Future<void> setDefaultDownloadFolder(String path) async {
    await updateSettings(_settings.copyWith(defaultDownloadFolder: path));
  }

  Future<void> resetToDefaults() async {
    final defaultDir = await FileUtils.getDefaultDownloadDirectory();
    final defaults = AppSettings(defaultDownloadFolder: defaultDir);
    await updateSettings(defaults);
  }
}

