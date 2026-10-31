import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../models/download_stat.dart';
import '../../repositories/download_repository.dart';

class NetworkMonitorProvider extends ChangeNotifier {
  final DownloadRepository _repository;
  StreamSubscription? _statSub;

  DownloadStat _currentStat = const DownloadStat();
  final List<FlSpot> _speedSpots = [];
  double _timeIndex = 0;
  int _peakSpeed = 0;

  NetworkMonitorProvider({required DownloadRepository repository})
      : _repository = repository {
    _init();
  }

  DownloadStat get currentStat => _currentStat;
  List<FlSpot> get speedSpots => List.unmodifiable(_speedSpots);
  int get peakSpeed => _peakSpeed;

  void _init() {
    // Initialize 30 empty spots
    for (int i = 0; i < 30; i++) {
      _speedSpots.add(FlSpot(i.toDouble(), 0));
    }
    _timeIndex = 30;

    _statSub = _repository.statStream.listen((stat) {
      _currentStat = stat;
      if (stat.peakSpeed > _peakSpeed) {
        _peakSpeed = stat.peakSpeed;
      }

      // Append new spot (speed in KB/s for chart readability)
      final speedKb = (stat.currentSpeed / 1024.0);
      _speedSpots.add(FlSpot(_timeIndex, speedKb));
      _timeIndex += 1;

      if (_speedSpots.length > AppConstants.speedChartMaxPoints) {
        _speedSpots.removeAt(0);
      }

      notifyListeners();
    });
  }

  Future<void> setGlobalLimit(int bytesPerSec) async {
    await _repository.setGlobalSpeedLimit(bytesPerSec);
    final settings = await _repository.dbService.loadSettings();
    await _repository.dbService.saveSettings(
      settings.copyWith(globalSpeedLimitBytes: bytesPerSec),
    );
    notifyListeners();
  }

  Future<void> setMaxConcurrent(int count) async {
    await _repository.setMaxConcurrentDownloads(count);
    final settings = await _repository.dbService.loadSettings();
    await _repository.dbService.saveSettings(
      settings.copyWith(maxSimultaneousDownloads: count),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _statSub?.cancel();
    super.dispose();
  }
}

