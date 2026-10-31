import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/constants/app_constants.dart';
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

  /// Start the aria2 background process and establish JSON-RPC connection
  Future<Aria2Client> startEngine({int? preferredPort}) async {
    if (_isRunning && _client != null) {
      return _client!;
    }

    final executable = await findAria2Executable();
    debugPrint('[Aria2Engine] Using executable: $executable');

    _rpcSecret = _generateSecureSecret();
    _rpcPort = await _findAvailablePort(preferredPort ?? AppConstants.defaultRpcPort);

    final args = [
      '--enable-rpc=true',
      '--rpc-listen-port=$_rpcPort',
      '--rpc-listen-all=false',
      '--rpc-allow-origin-all=false',
      '--rpc-secret=$_rpcSecret',
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
    ];

    try {
      _process = await Process.start(
        executable,
        args,
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

      // Verify connection with health-check retry loop
      bool connected = false;
      int retries = 0;
      const maxRetries = 15;

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

  /// Graceful shutdown
  Future<void> stopEngine() async {
    if (_client != null) {
      try {
        await _client!.shutdown();
      } catch (_) {}
    }

    if (_process != null) {
      try {
        _process!.kill(ProcessSignal.sigterm);
      } catch (_) {
        _process!.kill(ProcessSignal.sigkill);
      }
      _process = null;
    }

    _isRunning = false;
    _client = null;
    debugPrint('[Aria2Engine] Engine shut down cleanly.');
  }
}
