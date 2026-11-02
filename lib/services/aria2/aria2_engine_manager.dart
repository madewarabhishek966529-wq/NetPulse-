import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/torrent_constants.dart';
import '../../core/errors/app_exceptions.dart';
import 'aria2_client.dart';

class Aria2EngineManager {
  Process? _process;
  Aria2Client? _client;
  String? _rpcSecret;
  int _rpcPort = AppConstants.defaultRpcPort;
  bool _isRunning = false;

  Aria2Client? get client => _client;
  String? get rpcSecret => _rpcSecret;
  int get rpcPort => _rpcPort;
  bool get isRunning => _isRunning;

  /// Generate a secure random 32-character hex secret
  String _generateSecureSecret() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Locate aria2c.exe
  Future<String> findAria2Executable() async {
    // 1. Check relative development path
    final devPath = p.join(Directory.current.path, 'assets', 'bin', 'aria2c.exe');
    if (File(devPath).existsSync()) {
      return devPath;
    }

    // 2. Check executable directory (for release builds)
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final inExeDir = p.join(exeDir, 'aria2c.exe');
    if (File(inExeDir).existsSync()) {
      return inExeDir;
    }

    final inExeDataDir = p.join(exeDir, 'data', 'flutter_assets', 'assets', 'bin', 'aria2c.exe');
    if (File(inExeDataDir).existsSync()) {
      return inExeDataDir;
    }

    // 3. Check AppData destination
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final targetAria2 = p.join(appSupportDir.path, 'bin', 'aria2c.exe');
      if (File(targetAria2).existsSync()) {
        return targetAria2;
      }

      // Try extracting from Flutter assets
      try {
        final byteData = await rootBundle.load('assets/bin/aria2c.exe');
        final targetDir = Directory(p.dirname(targetAria2));
        if (!targetDir.existsSync()) {
          await targetDir.create(recursive: true);
        }
        final file = File(targetAria2);
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        return targetAria2;
      } catch (assetErr) {
        debugPrint('Could not extract aria2 from assets: $assetErr');
      }
    } catch (_) {}

    // 4. Check WinGet standard installation directory
    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (localAppData != null) {
      final wingetPath = p.join(
        localAppData,
        'Microsoft',
        'WinGet',
        'Packages',
      );
      if (Directory(wingetPath).existsSync()) {
        try {
          final matches = Directory(wingetPath)
              .listSync(recursive: true)
              .where((entity) => p.basename(entity.path).toLowerCase() == 'aria2c.exe')
              .toList();
          if (matches.isNotEmpty) {
            return matches.first.path;
          }
        } catch (_) {}
      }
    }

    // 5. Check system PATH
    try {
      final res = await Process.run('where.exe', ['aria2c.exe']);
      if (res.exitCode == 0 && res.stdout.toString().trim().isNotEmpty) {
        final line = res.stdout.toString().trim().split('\r\n').first.trim();
        if (File(line).existsSync()) {
          return line;
        }
      }
    } catch (_) {}

    throw Aria2Exception(
      'aria2c executable not found. Please ensure aria2c.exe is present in assets/bin/ or installed.',
      code: 'EXECUTABLE_NOT_FOUND',
    );
  }

  /// Find an available port on 127.0.0.1
  Future<int> _findAvailablePort(int startingPort) async {
    for (int port = startingPort; port <= startingPort + 50; port++) {
      try {
        final server = await ServerSocket.bind('127.0.0.1', port);
        await server.close();
        return port;
      } catch (_) {
        // Port in use, continue search
      }
    }
    return startingPort;
  }

  /// Clean up any orphaned aria2c processes left from crashed or previous runs
  static Future<void> cleanupStaleAriaProcesses() async {
    if (Platform.isWindows) {
      try {
        await Process.run('taskkill', ['/F', '/IM', 'aria2c.exe']);
      } catch (_) {}
    }
  }

  /// Ensure Windows Firewall allows inbound BitTorrent peer traffic for the located binary
  static Future<void> ensureFirewallRule(String executablePath) async {
    if (!Platform.isWindows) return;
    try {
      await Process.run('netsh', [
        'advfirewall',
        'firewall',
        'add',
        'rule',
        'name=NetPulse Torrent Engine',
        'dir=in',
        'action=allow',
        'program=$executablePath',
        'enable=yes',
      ]);
    } catch (_) {}
  }

  /// Prepare and sanitize dedicated DHT routing cache to prevent corrupt cache crashes
  Future<Map<String, String>> _prepareDhtCache() async {
    try {
      Directory baseDir;
      try {
        baseDir = await getApplicationSupportDirectory();
      } catch (_) {
        baseDir = Directory(p.join(Directory.current.path, '.netpulse'));
      }

      final dhtDir = Directory(p.join(baseDir.path, 'dht'));
      if (!dhtDir.existsSync()) {
        dhtDir.createSync(recursive: true);
      }

      final dht4 = File(p.join(dhtDir.path, 'dht.dat'));
      final dht6 = File(p.join(dhtDir.path, 'dht6.dat'));

      // Clean up corrupt/empty 0-byte cache files that cause aria2 deserializer crashes
      if (dht4.existsSync() && dht4.lengthSync() < 16) {
        try { dht4.deleteSync(); } catch (_) {}
      }
      if (dht6.existsSync() && dht6.lengthSync() < 16) {
        try { dht6.deleteSync(); } catch (_) {}
      }

      return {
        'workingDir': baseDir.path,
        'dht4': dht4.path,
        'dht6': dht6.path,
      };
    } catch (e) {
      debugPrint('[Aria2Engine] DHT cache prep error: $e');
      return {};
    }
  }

  /// Start the aria2 background process and establish JSON-RPC connection
  Future<Aria2Client> startEngine({int? preferredPort}) async {
    if (_isRunning && _client != null) {
      return _client!;
    }

    // Terminate stale background aria2 processes on application startup
    if (preferredPort == null) {
      await cleanupStaleAriaProcesses();
    }

    final executable = await findAria2Executable();
    debugPrint('[Aria2Engine] Using executable: $executable');
    await ensureFirewallRule(executable);

    _rpcSecret = _generateSecureSecret();
    _rpcPort = await _findAvailablePort(preferredPort ?? AppConstants.defaultRpcPort);

    final dhtCache = await _prepareDhtCache();
    final workingDir = dhtCache['workingDir'];

    final args = [
      '--enable-rpc=true',
      '--rpc-listen-port=$_rpcPort',
      '--rpc-listen-all=false',
      '--rpc-allow-origin-all=false',
      '--rpc-secret=$_rpcSecret',
      '--rpc-max-request-size=128M',
      '--max-connection-per-server=16',
      '--split=8',
      '--min-split-size=5M',
      '--continue=true',
      '--auto-file-renaming=false',
      '--allow-overwrite=true',
      '--check-integrity=false',
      '--disk-cache=32M',
      '--file-allocation=none',
      '--max-tries=5',
      '--retry-wait=3',
      '--quiet=true',
      '--summary-interval=0',
      // BitTorrent & P2P Acceleration Options
      '--enable-dht=true',
      '--enable-dht6=true',
      '--dht-entry-point=${TorrentConstants.primaryDhtNode}',
      '--dht-entry-point6=${TorrentConstants.primaryDhtNode}',
      '--listen-port=6881-6999',
      '--dht-listen-port=6881-6999',
      '--bt-enable-lpd=true',
      '--enable-peer-exchange=true',
      '--bt-max-peers=120',
      '--bt-request-peer-speed-limit=50M',
      '--bt-min-crypto-level=plain',
      '--bt-require-crypto=false',
      '--seed-ratio=0.0',
      '--follow-torrent=mem',
      '--bt-tracker=${TorrentConstants.trackerArgString}',
    ];

    if (dhtCache.containsKey('dht4') && dhtCache['dht4'] != null) {
      final p4 = dhtCache['dht4']!.replaceAll(r'\', '/');
      args.add('--dht-file-path=$p4');
    }
    if (dhtCache.containsKey('dht6') && dhtCache['dht6'] != null) {
      final p6 = dhtCache['dht6']!.replaceAll(r'\', '/');
      args.add('--dht-file-path6=$p6');
    }

    try {
      _process = await Process.start(
        executable,
        args,
        workingDirectory: workingDir,
        mode: ProcessStartMode.normal,
      );

      _process!.exitCode.then((code) {
        debugPrint('[Aria2Engine] Process exited with code $code');
        _isRunning = false;
      });

      // Create client
      _client = Aria2Client(
        host: '127.0.0.1',
        port: _rpcPort,
        secret: _rpcSecret,
      );

      // Verify connection with health-check retry loop (up to 25 attempts x 200ms = 5.0 seconds)
      bool connected = false;
      int retries = 0;
      const maxRetries = 25;

      while (!connected && retries < maxRetries) {
        await Future.delayed(const Duration(milliseconds: 200));
        try {
          final ver = await _client!.getVersion();
          if (ver.containsKey('version')) {
            connected = true;
            _isRunning = true;
            debugPrint('[Aria2Engine] Connected successfully! Version: ${ver['version']} on port $_rpcPort');
            break;
          }
        } catch (_) {
          retries++;
        }
      }

      if (!connected) {
        await stopEngine();
        throw RpcConnectionException(
          'Aria2 process started but failed to respond to JSON-RPC after $maxRetries attempts.',
          code: 'CONNECTION_TIMEOUT',
        );
      }

      return _client!;
    } catch (e) {
      _isRunning = false;
      if (e is AppException) rethrow;
      throw Aria2Exception('Failed to launch aria2 process: $e');
    }
  }

  /// Graceful shutdown: RPC shutdown first, wait for process exit, then fallback to kill
  Future<void> stopEngine() async {
    if (_client != null) {
      try {
        await _client!.shutdown();
      } catch (_) {}
    }

    if (_process != null) {
      try {
        // Wait up to 1500ms for clean exit
        await _process!.exitCode.timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () {
            try {
              _process!.kill(ProcessSignal.sigterm);
            } catch (_) {
              _process!.kill(ProcessSignal.sigkill);
            }
            return -1;
          },
        );
      } catch (_) {
        try {
          _process!.kill(ProcessSignal.sigkill);
        } catch (_) {}
      }
      _process = null;
    }

    _isRunning = false;
    _client = null;
    debugPrint('[Aria2Engine] Engine shut down cleanly.');
  }
}
