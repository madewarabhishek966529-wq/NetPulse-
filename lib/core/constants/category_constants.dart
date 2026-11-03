import 'package:flutter/material.dart';

class CategoryConstants {
  static const String software = 'Software';
  static const String videos = 'Videos';
  static const String music = 'Music';
  static const String documents = 'Documents';
  static const String images = 'Images';
  static const String archives = 'Archives';
  static const String games = 'Games';
  static const String other = 'Other';

  static const List<String> defaultCategories = [
    software,
    videos,
    music,
    documents,
    images,
    archives,
    games,
    other,
  ];

  static const Map<String, List<String>> extensionMap = {
    software: [
      'exe', 'msi', 'dmg', 'pkg', 'deb', 'rpm', 'apk', 'appimage', 'jar',
      'cmd', 'bat', 'ps1', 'vbs', 'sh'
    ],
    videos: [
      'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v', '3gp',
      'ts', 'm2ts', 'vob', 'ogv'
    ],
    music: [
      'mp3', 'flac', 'wav', 'aac', 'ogg', 'm4a', 'wma', 'alac', 'aiff',
      'opus', 'mid', 'midi'
    ],
    documents: [
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'rtf',
      'odt', 'ods', 'odp', 'epub', 'mobi', 'csv', 'tsv', 'md', 'html', 'htm'
    ],
    images: [
      'jpg', 'jpeg', 'png', 'gif', 'svg', 'webp', 'bmp', 'ico', 'tiff',
      'tif', 'psd', 'ai', 'raw', 'cr2', 'nef'
    ],
    archives: [
      'zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz', 'iso', 'img',
      'tgz', 'tbz2', 'cab', 'zst'
    ],
    games: [
      'rom', 'nes', 'sfc', 'gba', 'nds', 'iso', 'cso', 'nsp', 'xci',
      'pak', 'wad', 'vpk'
    ],
  };

  static String detectCategoryFromExtension(String? extension) {
    if (extension == null || extension.isEmpty) return other;
    final ext = extension.toLowerCase().replaceAll('.', '').trim();

    for (final entry in extensionMap.entries) {
      if (entry.value.contains(ext)) {
        return entry.key;
      }
    }
    return other;
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case software:
        return Icons.terminal_rounded;
      case videos:
        return Icons.movie_creation_rounded;
      case music:
        return Icons.music_note_rounded;
      case documents:
        return Icons.description_rounded;
      case images:
        return Icons.photo_size_select_actual_rounded;
      case archives:
        return Icons.folder_zip_rounded;
      case games:
        return Icons.sports_esports_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case software:
        return const Color(0xFFC4A1FF); // Luminescent Lavender
      case videos:
        return const Color(0xFFF87171); // Soft Coral Rose
      case music:
        return const Color(0xFFF472B6); // Soft Orchid Pink
      case documents:
        return const Color(0xFFFBBF24); // Warm Amber
      case images:
        return const Color(0xFFA78BFA); // Soft Iris Purple
      case archives:
        return const Color(0xFFFB923C); // Warm Apricot
      case games:
        return const Color(0xFF34D399); // Soft Mint Emerald
      default:
        return const Color(0xFFAAA2B3); // Lavender Ash (Swatch 5)
    }
  }
}

