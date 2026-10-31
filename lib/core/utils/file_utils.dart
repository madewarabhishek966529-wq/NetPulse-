import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileUtils {
  static const Set<String> dangerousExtensions = {
    'exe', 'bat', 'cmd', 'vbs', 'ps1', 'scr', 'msi', 'com', 'pif', 'hta', 'cpl', 'jar'
  };

  static String sanitizeFilename(String filename) {
    var clean = filename.trim();
    // Remove control characters and path traversal
    clean = clean.replaceAll(RegExp(r'[\x00-\x1f\x7f]'), '');
    clean = clean.replaceAll('..', '_');
    // Replace Windows forbidden characters: < > : " / \ | ? *
    clean = clean.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    if (clean.isEmpty) {
      clean = 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
    return clean;
  }

  static bool isDangerousFile(String filename) {
    final ext = p.extension(filename).toLowerCase().replaceAll('.', '');
    return dangerousExtensions.contains(ext);
  }

  static Future<String> getDefaultDownloadDirectory() async {
    try {
      final dir = await getDownloadsDirectory();
      if (dir != null && await dir.exists()) {
        return dir.path;
      }
    } catch (_) {}

    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null) {
      final standardDownloads = p.join(userProfile, 'Downloads');
      if (Directory(standardDownloads).existsSync()) {
        return standardDownloads;
      }
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final defaultDir = p.join(appDocDir.path, 'NetPulseDownloads');
    await Directory(defaultDir).create(recursive: true);
    return defaultDir;
  }

  static String getNonCollidingPath(String directory, String filename) {
    var filePath = p.join(directory, filename);
    if (!File(filePath).existsSync()) {
      return filePath;
    }

    final nameWithoutExt = p.basenameWithoutExtension(filename);
    final ext = p.extension(filename);
    int counter = 1;

    while (File(filePath).existsSync()) {
      filePath = p.join(directory, '$nameWithoutExt ($counter)$ext');
      counter++;
    }
    return filePath;
  }
}

