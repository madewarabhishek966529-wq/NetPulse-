import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/category_constants.dart';
import '../../core/utils/file_utils.dart';

class UrlInspectionResult {
  final String url;
  final String fileName;
  final int fileSize; // 0 if unknown / chunked
  final bool supportsRange;
  final String mimeType;
  final String detectedCategory;
  final int recommendedConnections;
  final Map<String, String> responseHeaders;
  final String? errorMessage;

  UrlInspectionResult({
    required this.url,
    required this.fileName,
    required this.fileSize,
    required this.supportsRange,
    required this.mimeType,
    required this.detectedCategory,
    required this.recommendedConnections,
    required this.responseHeaders,
    this.errorMessage,
  });
}

class InspectUrlService {
  final Dio _dio;

  InspectUrlService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                followRedirects: true,
                maxRedirects: 5,
                headers: {
                  'User-Agent':
                      'NetPulse/1.0 (Windows NT 10.0; Win64; x64) Desktop-Engine',
                },
              ),
            );

  Future<UrlInspectionResult> inspectUrl(
    String url, {
    Map<String, String>? customHeaders,
    String? username,
    String? password,
  }) async {
    final headers = <String, dynamic>{};
    if (customHeaders != null) {
      headers.addAll(customHeaders);
    }
    if (username != null && username.isNotEmpty) {
      final credentials = '$username:${password ?? ""}';
      final encoded = 'Basic ${credentials}'; // or base64 in aria2
      headers['Authorization'] = encoded;
    }

    try {
      // 1. First try HEAD
      Response response;
      try {
        response = await _dio.head(
          url,
          options: Options(headers: headers),
        );
      } catch (_) {
        // Fallback to GET with Range: bytes=0-0 to prevent downloading entire file
        final getHeaders = Map<String, dynamic>.from(headers);
        getHeaders['Range'] = 'bytes=0-0';
        response = await _dio.get(
          url,
          options: Options(
            headers: getHeaders,
            responseType: ResponseType.stream,
          ),
        );
      }

      final headerMap = <String, String>{};
      response.headers.forEach((key, values) {
        headerMap[key.toLowerCase()] = values.join(', ');
      });

      // Filename extraction
      String fileName = _extractFilenameFromHeaders(headerMap);
      if (fileName.isEmpty) {
        fileName = _extractFilenameFromUrl(url);
      }
      fileName = FileUtils.sanitizeFilename(fileName);

      // File size extraction
      int fileSize = 0;
      final contentRange = headerMap['content-range'];
      if (contentRange != null) {
        final match = RegExp(r'/(\d+)').firstMatch(contentRange);
        if (match != null) {
          fileSize = int.tryParse(match.group(1) ?? '0') ?? 0;
        }
      }
      if (fileSize <= 0 && headerMap.containsKey('content-length')) {
        fileSize = int.tryParse(headerMap['content-length'] ?? '0') ?? 0;
      }

      // Range support check
      bool supportsRange = false;
      final acceptRanges = headerMap['accept-ranges'];
      if (acceptRanges != null && acceptRanges.toLowerCase().contains('bytes')) {
        supportsRange = true;
      } else if (response.statusCode == 206 || contentRange != null) {
        supportsRange = true;
      }

      final mimeType = headerMap['content-type'] ?? 'application/octet-stream';
      final ext = p.extension(fileName);
      final category = CategoryConstants.detectCategoryFromExtension(ext);
      final recommendedConnections = supportsRange ? 8 : 1;

      return UrlInspectionResult(
        url: url,
        fileName: fileName,
        fileSize: fileSize,
        supportsRange: supportsRange,
        mimeType: mimeType,
        detectedCategory: category,
        recommendedConnections: recommendedConnections,
        responseHeaders: headerMap,
      );
    } catch (e) {
      // In case network inspection fails (e.g. offline, auth required, strict bot protection)
      // gracefully extract from URL so user can still initiate download with aria2
      final fallbackFilename = FileUtils.sanitizeFilename(_extractFilenameFromUrl(url));
      final ext = p.extension(fallbackFilename);
      final category = CategoryConstants.detectCategoryFromExtension(ext);

      return UrlInspectionResult(
        url: url,
        fileName: fallbackFilename,
        fileSize: 0,
        supportsRange: true, // assume true for aria2 to test
        mimeType: 'application/octet-stream',
        detectedCategory: category,
        recommendedConnections: 8,
        responseHeaders: {},
        errorMessage: e.toString(),
      );
    }
  }

  String _extractFilenameFromHeaders(Map<String, String> headers) {
    final disposition = headers['content-disposition'];
    if (disposition == null) return '';

    // Check filename*=UTF-8''name.ext
    final utf8Match = RegExp(r"filename\*\s*=\s*(?:UTF-8|utf-8)''([^;]+)", caseSensitive: false)
        .firstMatch(disposition);
    if (utf8Match != null) {
      return Uri.decodeFull(utf8Match.group(1)!.trim());
    }

    // Check filename="name.ext" or filename=name.ext
    final normalMatch = RegExp(r'filename\s*=\s*"?([^";]+)"?', caseSensitive: false)
        .firstMatch(disposition);
    if (normalMatch != null) {
      return normalMatch.group(1)!.trim();
    }

    return '';
  }

  String _extractFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (pathSegments.isNotEmpty) {
        final last = pathSegments.last;
        final decoded = Uri.decodeComponent(last);
        if (decoded.contains('.')) {
          return decoded;
        }
      }
    } catch (_) {}
    return 'download_${DateTime.now().millisecondsSinceEpoch}';
  }
}
