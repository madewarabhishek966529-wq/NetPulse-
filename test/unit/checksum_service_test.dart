import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse/services/file_verification/checksum_service.dart';

void main() {
  group('ChecksumService Tests', () {
    late ChecksumService checksumService;
    late Directory tempDir;
    late File testFile;
    const testContent = 'Hello NetPulse';

    setUp(() async {
      checksumService = ChecksumService();
      tempDir = await Directory.systemTemp.createTemp('netpulse_test_');
      testFile = File('${tempDir.path}\\test.txt');
      await testFile.writeAsString(testContent);
    });

    tearDown(() async {
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('calculates correct SHA-256 for test file', () async {
      final sha = await checksumService.calculateSha256(testFile.path);
      expect(sha.toLowerCase(), 'b574fadc3a759de41c1f95138cce691df689305312771be7e63109b2329e8dd3');
    });

    test('calculates correct MD5 for test file', () async {
      final md5 = await checksumService.calculateMd5(testFile.path);
      expect(md5.toLowerCase(), '6e725bea887d3e5192e697ead796cd92');
    });

    test('verifies file integrity with matching hash', () async {
      final result = await checksumService.verifyFile(
        filePath: testFile.path,
        expectedChecksum: 'B574FADC3A759DE41C1F95138CCE691DF689305312771BE7E63109B2329E8DD3',
      );
      expect(result.matches, isTrue);
      expect(result.fileSizeBytes, testContent.length);
    });

    test('detects mismatch for corrupted or incorrect hash', () async {
      final result = await checksumService.verifyFile(
        filePath: testFile.path,
        expectedChecksum: '0000000000000000000000000000000000000000000000000000000000000000',
      );
      expect(result.matches, isFalse);
    });
  });
}
