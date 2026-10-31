import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import '../../core/errors/app_exceptions.dart';
import '../../core/utils/file_utils.dart';

class ChecksumVerificationResult {
  final String calculatedSha256;
  final String? calculatedMd5;
  final int fileSizeBytes;
  final bool matches;
  final String? expectedChecksum;
  final String filePath;

  ChecksumVerificationResult({
    required this.calculatedSha256,
    this.calculatedMd5,
    required this.fileSizeBytes,
    required this.matches,
    this.expectedChecksum,
    required this.filePath,
  });
}

class ChecksumService {
  /// Calculate SHA-256 using streaming to support multi-gigabyte files efficiently
  Future<String> calculateSha256(String filePath, {void Function(double progress)? onProgress}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileVerificationException('File does not exist: $filePath');
    }

    final totalSize = await file.length();
    int readBytes = 0;

    final output = AccumulatorSink<Digest>();
    final input = sha256.startChunkedConversion(output);

    final stream = file.openRead();
    await for (final chunk in stream) {
      input.add(chunk);
      readBytes += chunk.length;
      if (onProgress != null && totalSize > 0) {
        onProgress((readBytes / totalSize).clamp(0.0, 1.0));
      }
    }
    input.close();

    return output.events.single.toString();
  }

  /// Calculate MD5
  Future<String> calculateMd5(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileVerificationException('File does not exist: $filePath');
    }

    final output = AccumulatorSink<Digest>();
    final input = md5.startChunkedConversion(output);

    final stream = file.openRead();
    await for (final chunk in stream) {
      input.add(chunk);
    }
    input.close();

    return output.events.single.toString();
  }

  /// Verify integrity against expected hash
  Future<ChecksumVerificationResult> verifyFile({
    required String filePath,
    String? expectedChecksum,
    void Function(double progress)? onProgress,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileVerificationException('Target file does not exist: $filePath');
    }

    final length = await file.length();
    final calculatedSha256 = await calculateSha256(filePath, onProgress: onProgress);
    String? calculatedMd5;

    bool matches = false;
    if (expectedChecksum != null && expectedChecksum.trim().isNotEmpty) {
      final cleanExpected = expectedChecksum.trim().toLowerCase();
      if (cleanExpected.length == 64) {
        matches = (cleanExpected == calculatedSha256.toLowerCase());
      } else if (cleanExpected.length == 32) {
        calculatedMd5 = await calculateMd5(filePath);
        matches = (cleanExpected == calculatedMd5.toLowerCase());
      }
    }

    return ChecksumVerificationResult(
      calculatedSha256: calculatedSha256,
      calculatedMd5: calculatedMd5,
      fileSizeBytes: length,
      matches: matches,
      expectedChecksum: expectedChecksum,
      filePath: filePath,
    );
  }

  /// Check if file is executable/script and needs confirmation before launching
  bool requiresExecutableWarning(String filePath) {
    return FileUtils.isDangerousFile(filePath);
  }
}
