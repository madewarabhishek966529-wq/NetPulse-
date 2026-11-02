import 'package:flutter/material.dart';
import '../../repositories/download_repository.dart';
import '../../services/api/backend_api_client.dart';

class AnalyzerProvider extends ChangeNotifier {
  final BackendApiClient _apiClient;
  bool _isAnalyzing = false;
  String? _currentStepMessage;
  AnalyzerResult? _lastResult;
  String? _errorMessage;
  bool _isBackendOnline = false;

  AnalyzerProvider({BackendApiClient? apiClient})
      : _apiClient = apiClient ?? BackendApiClient() {
    checkHealth();
  }

  bool get isAnalyzing => _isAnalyzing;
  String? get currentStepMessage => _currentStepMessage;
  AnalyzerResult? get lastResult => _lastResult;
  String? get errorMessage => _errorMessage;
  bool get isBackendOnline => _isBackendOnline;

  Future<void> checkHealth() async {
    _isBackendOnline = await _apiClient.isBackendHealthy();
    notifyListeners();
  }

  void clearResult() {
    _lastResult = null;
    _errorMessage = null;
    _currentStepMessage = null;
    notifyListeners();
  }

  Future<void> analyzeWebpage(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      _errorMessage = 'Please enter a valid webpage URL.';
      notifyListeners();
      return;
    }

    _isAnalyzing = true;
    _errorMessage = null;
    _currentStepMessage = 'Connecting to server & validating destination...';
    notifyListeners();

    try {
      _currentStepMessage = 'Filtering tracking networks & evaluating candidate links...';
      notifyListeners();

      final result = await _apiClient.analyzeUrl(cleanUrl);

      if (result.status == 'error') {
        _errorMessage = result.errorMessage ?? 'Analysis failed to complete.';
        _lastResult = null;
      } else {
        _lastResult = result;
        _errorMessage = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to analyze page: $e';
      _lastResult = null;
    } finally {
      _isAnalyzing = false;
      _currentStepMessage = null;
      notifyListeners();
    }
  }

  Future<bool> startDownload(DetectedResource file, DownloadRepository repository) async {
    try {
      // Use repository to start download directly with high-speed multi-connection acceleration
      await repository.addDownload(
        url: file.finalUrl.isNotEmpty ? file.finalUrl : file.sourceUrl,
        fileName: file.filename,
        connections: 8,
      );
      return true;
    } catch (e) {
      debugPrint('[AnalyzerProvider] Failed to start download: $e');
      return false;
    }
  }
}

