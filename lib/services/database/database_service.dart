import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/category_constants.dart';
import '../../models/app_settings.dart';
import '../../models/download_category.dart';
import '../../models/download_item.dart';
import '../../models/download_segment.dart';

class DatabaseService {
  static Database? _database;
  static bool _ffiInitialized = false;

  static void ensureInitialized() {
    if (!_ffiInitialized) {
      if (Platform.isWindows || Platform.isLinux) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      _ffiInitialized = true;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb({String? overridePath}) async {
    ensureInitialized();
    String dbPath;
    if (overridePath != null) {
      dbPath = overridePath;
    } else {
      final appSupport = await getApplicationSupportDirectory();
      dbPath = p.join(appSupport.path, AppConstants.databaseName);
    }

    final dbDir = Directory(p.dirname(dbPath));
    if (!dbDir.existsSync()) {
      await dbDir.create(recursive: true);
    }

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. downloads
    await db.execute('''
      CREATE TABLE downloads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gid TEXT,
        url TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        file_size INTEGER DEFAULT 0,
        downloaded_size INTEGER DEFAULT 0,
        download_speed INTEGER DEFAULT 0,
        status TEXT NOT NULL,
        category_id TEXT DEFAULT 'Other',
        created_at TEXT NOT NULL,
        completed_at TEXT,
        connections INTEGER DEFAULT 1,
        error_message TEXT,
        checksum TEXT,
        priority TEXT DEFAULT 'normal',
        is_scheduled INTEGER DEFAULT 0,
        scheduled_start_time TEXT,
        scheduled_end_time TEXT
      )
    ''');

    // 2. download_segments
    await db.execute('''
      CREATE TABLE download_segments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        download_id INTEGER NOT NULL,
        segment_index INTEGER NOT NULL,
        segment_status TEXT DEFAULT 'downloading',
        downloaded_bytes INTEGER DEFAULT 0,
        FOREIGN KEY (download_id) REFERENCES downloads(id) ON DELETE CASCADE
      )
    ''');

    // 3. categories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        directory TEXT NOT NULL
      )
    ''');

    // 4. download_settings
    await db.execute('''
      CREATE TABLE download_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_key TEXT UNIQUE NOT NULL,
        setting_value TEXT NOT NULL
      )
    ''');

    // 5. download_history
    await db.execute('''
      CREATE TABLE download_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        download_id INTEGER,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // Populate initial categories
    final defaultDownloadDir = await _getDefaultDir();
    for (final catName in CategoryConstants.defaultCategories) {
      final catDir = p.join(defaultDownloadDir, catName);
      await db.insert('categories', {
        'name': catName,
        'directory': catDir,
      });
    }
  }

  Future<String> _getDefaultDir() async {
    try {
      final d = await getDownloadsDirectory();
      if (d != null) return d.path;
    } catch (_) {}
    return Platform.environment['USERPROFILE'] ?? Directory.current.path;
  }

  // ==================== DOWNLOAD OPERATIONS ====================

  Future<int> insertDownload(DownloadItem item) async {
    final db = await database;
    final id = await db.insert('downloads', item.toMap());
    await logHistory(id, 'created');
    return id;
  }

  Future<int> updateDownload(DownloadItem item) async {
    final db = await database;
    if (item.id == null) return 0;
    return await db.update(
      'downloads',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> updateDownloadByGid(DownloadItem item) async {
    final db = await database;
    return await db.update(
      'downloads',
      item.toMap(),
      where: 'gid = ?',
      whereArgs: [item.gid],
    );
  }

  Future<DownloadItem?> getDownloadById(int id) async {
    final db = await database;
    final results = await db.query('downloads', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return DownloadItem.fromMap(results.first);
    }
    return null;
  }

  Future<DownloadItem?> getDownloadByGid(String gid) async {
    final db = await database;
    final results = await db.query('downloads', where: 'gid = ?', whereArgs: [gid]);
    if (results.isNotEmpty) {
      return DownloadItem.fromMap(results.first);
    }
    return null;
  }

  Future<List<DownloadItem>> getAllDownloads({
    DownloadStatus? status,
    String? category,
    String? searchQuery,
    String orderBy = 'created_at DESC',
  }) async {
    final db = await database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (status != null) {
      whereClauses.add('status = ?');
      whereArgs.add(status.name);
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      whereClauses.add('category_id = ?');
      whereArgs.add(category);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      whereClauses.add('(file_name LIKE ? OR url LIKE ?)');
      whereArgs.add('%${searchQuery.trim()}%');
      whereArgs.add('%${searchQuery.trim()}%');
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;
    final results = await db.query(
      'downloads',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return results.map((map) => DownloadItem.fromMap(map)).toList();
  }

  Future<List<DownloadItem>> getUnfinishedDownloads() async {
    final db = await database;
    final results = await db.query(
      'downloads',
      where: 'status IN (?, ?, ?)',
      whereArgs: [
        DownloadStatus.active.name,
        DownloadStatus.waiting.name,
        DownloadStatus.paused.name,
      ],
    );
    return results.map((map) => DownloadItem.fromMap(map)).toList();
  }

  Future<List<DownloadItem>> getScheduledDownloads() async {
    final db = await database;
    final results = await db.query(
      'downloads',
      where: 'is_scheduled = 1 AND status != ?',
      whereArgs: [DownloadStatus.completed.name],
      orderBy: 'scheduled_start_time ASC',
    );
    return results.map((map) => DownloadItem.fromMap(map)).toList();
  }

  Future<int> deleteDownload(int id) async {
    final db = await database;
    await logHistory(id, 'deleted');
    return await db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearHistory() async {
    final db = await database;
    // Clear completed or removed downloads
    return await db.delete(
      'downloads',
      where: 'status IN (?, ?)',
      whereArgs: [DownloadStatus.completed.name, DownloadStatus.removed.name],
    );
  }

  // ==================== SEGMENTS ====================

  Future<void> saveSegments(int downloadId, List<DownloadSegment> segments) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('download_segments', where: 'download_id = ?', whereArgs: [downloadId]);
    for (final seg in segments) {
      batch.insert('download_segments', seg.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<DownloadSegment>> getSegments(int downloadId) async {
    final db = await database;
    final results = await db.query(
      'download_segments',
      where: 'download_id = ?',
      whereArgs: [downloadId],
      orderBy: 'segment_index ASC',
    );
    return results.map((m) => DownloadSegment.fromMap(m)).toList();
  }

  // ==================== CATEGORIES ====================

  Future<List<DownloadCategory>> getCategories() async {
    final db = await database;
    final results = await db.query('categories', orderBy: 'name ASC');
    return results.map((m) => DownloadCategory.fromMap(m)).toList();
  }

  Future<int> insertCategory(DownloadCategory cat) async {
    final db = await database;
    return await db.insert('categories', cat.toMap());
  }

  Future<int> updateCategory(DownloadCategory cat) async {
    final db = await database;
    if (cat.id == null) return 0;
    return await db.update('categories', cat.toMap(), where: 'id = ?', whereArgs: [cat.id]);
  }

  // ==================== SETTINGS ====================

  Future<AppSettings> loadSettings() async {
    final db = await database;
    final rows = await db.query('download_settings');
    final map = <String, String>{};
    for (final row in rows) {
      final key = row['setting_key'] as String?;
      final val = row['setting_value'] as String?;
      if (key != null && val != null) {
        map[key] = val;
      }
    }
    return AppSettings.fromSettingsMap(map);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final db = await database;
    final map = settings.toSettingsMap();
    final batch = db.batch();
    for (final entry in map.entries) {
      batch.insert(
        'download_settings',
        {'setting_key': entry.key, 'setting_value': entry.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ==================== HISTORY LOG ====================

  Future<void> logHistory(int? downloadId, String action) async {
    try {
      final db = await database;
      await db.insert('download_history', {
        'download_id': downloadId,
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  // ==================== EXPORT CSV ====================

  Future<String> exportHistoryCsv() async {
    final all = await getAllDownloads(orderBy: 'created_at DESC');
    final buffer = StringBuffer();
    buffer.writeln('ID,GID,FileName,URL,FileSize,DownloadedSize,Status,Category,CreatedAt,CompletedAt');

    for (final item in all) {
      final escapedName = '"${item.fileName.replaceAll('"', '""')}"';
      final escapedUrl = '"${item.url.replaceAll('"', '""')}"';
      buffer.writeln(
        '${item.id},${item.gid},$escapedName,$escapedUrl,${item.fileSize},${item.downloadedSize},${item.status.name},${item.categoryId},${item.createdAt},${item.completedAt ?? ""}',
      );
    }
    return buffer.toString();
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
