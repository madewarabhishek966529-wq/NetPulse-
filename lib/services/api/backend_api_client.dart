import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/app_constants.dart';

class DetectedResource {
  final String filename;
  final String fileExtension;
  final int fileSize;
  final String contentType;
  final String sourceHostname;
  final String sourceUrl;
  final String finalUrl;
  final String detectionConfidence;
  final bool isDirectDownload;
  final bool rangeSupported;

  DetectedResource({
    required this.filename,
    required this.fileExtension,
    required this.fileSize,
    required this.contentType,
    required this.sourceHostname,
    required this.sourceUrl,
    required this.finalUrl,
    required this.detectionConfidence,
    required this.isDirectDownload,
    required this.rangeSupported,
  });

  factory DetectedResource.fromJson(Map<String, dynamic> json) {
    return DetectedResource(
      filename: json['filename'] ?? 'download',
      fileExtension: json['file_extension'] ?? '',
      fileSize: json['file_size'] ?? 0,
      contentType: json['content_type'] ?? 'application/octet-stream',
      sourceHostname: json['source_hostname'] ?? '',
      sourceUrl: json['source_url'] ?? '',
      finalUrl: json['final_url'] ?? '',
      detectionConfidence: json['detection_confidence'] ?? 'Medium',
      isDirectDownload: json['is_direct_download'] ?? true,
      rangeSupported: json['range_supported'] ?? false,
    );
  }
}

class FilteredResource {
  final String url;
  final String hostname;
  final String reason;

  FilteredResource({
    required this.url,
    required this.hostname,
    required this.reason,
  });

  factory FilteredResource.fromJson(Map<String, dynamic> json) {
    return FilteredResource(
      url: json['url'] ?? '',
      hostname: json['hostname'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}

class AnalyzerResult {
  final String originalUrl;
  final String status;
  final List<DetectedResource> discoveredFiles;
  final List<FilteredResource> filteredLinks;
  final int totalDiscovered;
  final int totalFiltered;
  final String? errorMessage;

  AnalyzerResult({
    required this.originalUrl,
    required this.status,
    required this.discoveredFiles,
    required this.filteredLinks,
    required this.totalDiscovered,
    required this.totalFiltered,
    this.errorMessage,
  });

  factory AnalyzerResult.fromJson(Map<String, dynamic> json) {
    final discoveredList = (json['discovered_files'] as List<dynamic>? ?? [])
        .map((e) => DetectedResource.fromJson(e as Map<String, dynamic>))
        .toList();

    final filteredList = (json['filtered_links'] as List<dynamic>? ?? [])
        .map((e) => FilteredResource.fromJson(e as Map<String, dynamic>))
        .toList();

    return AnalyzerResult(
      originalUrl: json['original_url'] ?? '',
      status: json['status'] ?? 'success',
      discoveredFiles: discoveredList,
      filteredLinks: filteredList,
      totalDiscovered: json['total_discovered'] ?? discoveredList.length,
      totalFiltered: json['total_filtered'] ?? filteredList.length,
      errorMessage: json['error_message'],
    );
  }
}

class BackendApiClient {
  final Dio _dio;

  BackendApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? AppConstants.backendBaseUrl,
            connectTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 25),
            headers: {'Content-Type': 'application/json'},
          ),
        );

  /// Checks if the backend server is reachable and online
  Future<bool> isBackendHealthy() async {
    try {
      final res = await _dio.get('/api/health');
      return res.statusCode == 200 && res.data['status'] == 'ok';
    } catch (e) {
      debugPrint('[BackendApiClient] Health check failed: $e');
      return false;
    }
  }

  /// Sends a webpage URL to the Smart URL Analyzer
  Future<AnalyzerResult> analyzeUrl(String url) async {
    try {
      final res = await _dio.post(
        '/api/analyze',
        data: {'url': url},
      );
      if (res.statusCode == 200) {
        return AnalyzerResult.fromJson(res.data);
      }
      throw Exception('Server returned ${res.statusCode}: ${res.statusMessage}');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? e.message;
      return AnalyzerResult(
        originalUrl: url,
        status: 'error',
        discoveredFiles: [],
        filteredLinks: [],
        totalDiscovered: 0,
        totalFiltered: 0,
        errorMessage: errorMsg.toString(),
      );
    } catch (e) {
      return AnalyzerResult(
        originalUrl: url,
        status: 'error',
        discoveredFiles: [],
        filteredLinks: [],
        totalDiscovered: 0,
        totalFiltered: 0,
        errorMessage: e.toString(),
      );
    }
  }

  /// Submits a detected file or URL to aria2 download manager via backend
  Future<Map<String, dynamic>> createDownload({
    required String url,
    String? filename,
    String? destination,
    int connections = 8,
    bool isTorrent = false,
  }) async {
    final res = await _dio.post(
      '/api/downloads',
      data: {
        'url': url,
        if (filename != null && filename.isNotEmpty) 'filename': filename,
        if (destination != null && destination.isNotEmpty) 'destination': destination,
        'connections': connections,
        'is_torrent': isTorrent,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  /// Fetches browser integration event history & status
  Future<Map<String, dynamic>> getBrowserStatus() async {
    try {
      final res = await _dio.get('/api/browser/status');
      return res.data as Map<String, dynamic>;
    } catch (e) {
      return {'is_ready': false, 'error': e.toString()};
    }
  }

  /// Retrieves backend settings
  Future<Map<String, String>> getSettings() async {
    try {
      final res = await _dio.get('/api/settings');
      final raw = res.data['settings'] as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      return {};
    }
  }

  /// Updates backend settings
  Future<bool> updateSettings(Map<String, String> settings) async {
    try {
      final res = await _dio.put('/api/settings', data: settings);
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

