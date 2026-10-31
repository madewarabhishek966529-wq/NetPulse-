import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse/core/utils/formatters.dart';
import 'package:netpulse/core/utils/validators.dart';

void main() {
  group('Formatters Unit Tests', () {
    test('formatBytes converts bytes to readable string', () {
      expect(Formatters.formatBytes(0), '0 B');
      expect(Formatters.formatBytes(500), '500 B');
      expect(Formatters.formatBytes(1024), '1.00 KB');
      expect(Formatters.formatBytes(1048576), '1.00 MB');
      expect(Formatters.formatBytes(1073741824), '1.00 GB');
      expect(Formatters.formatBytes(5368709120), '5.00 GB');
    });

    test('formatSpeed appends /s suffix', () {
      expect(Formatters.formatSpeed(0), '0 B/s');
      expect(Formatters.formatSpeed(1048576), '1.00 MB/s');
      expect(Formatters.formatSpeed(15728640), '15.00 MB/s');
    });

    test('formatEta calculates remaining time correctly', () {
      expect(Formatters.formatEta(0, 1000), '--:--');
      expect(Formatters.formatEta(1000, 0), '--:--');
      expect(Formatters.formatEta(3000, 100), '30s');
      expect(Formatters.formatEta(150000, 1000), '2m 30s');
      expect(Formatters.formatEta(7200000, 1000), '2h 0m');
    });

    test('formatPercent bounds between 0 and 100', () {
      expect(Formatters.formatPercent(0.0), '0.0%');
      expect(Formatters.formatPercent(0.5), '50.0%');
      expect(Formatters.formatPercent(1.0), '100.0%');
      expect(Formatters.formatPercent(1.5), '100.0%');
    });
  });

  group('Validators Unit Tests', () {
    test('isValidUrl validates HTTP/HTTPS/FTP protocols', () {
      expect(Validators.isValidUrl('https://example.com/file.zip'), isTrue);
      expect(Validators.isValidUrl('http://speedtest.tele2.net/10MB.zip'), isTrue);
      expect(Validators.isValidUrl('ftp://ftp.example.com/file.iso'), isTrue);
      expect(Validators.isValidUrl('invalid-url'), isFalse);
      expect(Validators.isValidUrl('javascript:alert(1)'), isFalse);
      expect(Validators.isValidUrl(''), isFalse);
    });

    test('isValidSha256 checks for 64 hex characters', () {
      expect(Validators.isValidSha256('e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'), isTrue);
      expect(Validators.isValidSha256('short_hash'), isFalse);
      expect(Validators.isValidSha256('invalid_characters_in_hash_1234567890123456789012345678901234567890'), isFalse);
    });

    test('isValidMd5 checks for 32 hex characters', () {
      expect(Validators.isValidMd5('d41d8cd98f00b204e9800998ecf8427e'), isTrue);
      expect(Validators.isValidMd5('invalid'), isFalse);
    });
  });
}

