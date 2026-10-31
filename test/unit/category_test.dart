import 'package:flutter_test/flutter_test.dart';
import 'package:netpulse/core/constants/category_constants.dart';
import 'package:netpulse/core/utils/file_utils.dart';

void main() {
  group('Category Detection Tests', () {
    test('detects software extensions', () {
      expect(CategoryConstants.detectCategoryFromExtension('exe'), CategoryConstants.software);
      expect(CategoryConstants.detectCategoryFromExtension('.msi'), CategoryConstants.software);
      expect(CategoryConstants.detectCategoryFromExtension('dmg'), CategoryConstants.software);
    });

    test('detects video extensions', () {
      expect(CategoryConstants.detectCategoryFromExtension('mp4'), CategoryConstants.videos);
      expect(CategoryConstants.detectCategoryFromExtension('.mkv'), CategoryConstants.videos);
      expect(CategoryConstants.detectCategoryFromExtension('avi'), CategoryConstants.videos);
    });

    test('detects archives extensions', () {
      expect(CategoryConstants.detectCategoryFromExtension('zip'), CategoryConstants.archives);
      expect(CategoryConstants.detectCategoryFromExtension('.7z'), CategoryConstants.archives);
      expect(CategoryConstants.detectCategoryFromExtension('tar'), CategoryConstants.archives);
      expect(CategoryConstants.detectCategoryFromExtension('gz'), CategoryConstants.archives);
    });

    test('detects document extensions', () {
      expect(CategoryConstants.detectCategoryFromExtension('pdf'), CategoryConstants.documents);
      expect(CategoryConstants.detectCategoryFromExtension('.docx'), CategoryConstants.documents);
    });

    test('returns other for unknown extensions', () {
      expect(CategoryConstants.detectCategoryFromExtension('unknownxyz'), CategoryConstants.other);
      expect(CategoryConstants.detectCategoryFromExtension(null), CategoryConstants.other);
      expect(CategoryConstants.detectCategoryFromExtension(''), CategoryConstants.other);
    });
  });

  group('File Security and Sanitization Tests', () {
    test('sanitizes dangerous Windows filenames and path traversal', () {
      expect(FileUtils.sanitizeFilename('../../passwords.txt'), '____passwords.txt');
      expect(FileUtils.sanitizeFilename('file<name>:with*illegal?chars.zip'), 'file_name__with_illegal_chars.zip');
      expect(FileUtils.sanitizeFilename('  normal_file.exe  '), 'normal_file.exe');
    });

    test('flags dangerous executable files', () {
      expect(FileUtils.isDangerousFile('setup.exe'), isTrue);
      expect(FileUtils.isDangerousFile('installer.msi'), isTrue);
      expect(FileUtils.isDangerousFile('script.bat'), isTrue);
      expect(FileUtils.isDangerousFile('script.ps1'), isTrue);
      expect(FileUtils.isDangerousFile('document.pdf'), isFalse);
      expect(FileUtils.isDangerousFile('image.png'), isFalse);
    });
  });
}
