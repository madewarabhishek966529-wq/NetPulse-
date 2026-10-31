import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/errors/app_exceptions.dart';
import 'aria2_models.dart';

class Aria2Client {
  final String host;
  final int port;
  final String? secret;
  final Dio _dio;
  int _requestId = 0;

  Aria2Client({
    this.host = '127.0.0.1',
    this.port = 6800,
    this.secret,
    Dio? dio,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'http://$host:$port/jsonrpc',
                connectTimeout: const Duration(seconds: 4),
                receiveTimeout: const Duration(seconds: 4),
                sendTimeout: const Duration(seconds: 4),
                headers: {'Content-Type': 'application/json'},
              ),
            );

  String get rpcUrl => 'http://$host:$port/jsonrpc';

  Future<dynamic> _call(String method, [List<dynamic> params = const []]) async {
    _requestId++;
    final fullParams = <dynamic>[];
    if (secret != null && secret!.isNotEmpty) {
      fullParams.add('token:$secret');
    }
    fullParams.addAll(params);

    final payload = {
      'jsonrpc': '2.0',
      'id': 'netpulse_$_requestId',
      'method': 'aria2.$method',
      'params': fullParams,
    };

    try {
      final response = await _dio.post(
        '',
        data: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        throw Aria2Exception(
          'Aria2 RPC returned HTTP status ${response.statusCode}',
          code: 'HTTP_${response.statusCode}',
        );
      }

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('error') && data['error'] != null) {
          final err = data['error'];
          final code = err['code']?.toString() ?? 'RPC_ERROR';
          final msg = err['message']?.toString() ?? 'Unknown RPC error';
          throw Aria2Exception(msg, code: code);
        }
        return data['result'];
      }
      throw Aria2Exception('Invalid response format from aria2 engine');
    } on DioException catch (e) {
      throw RpcConnectionException(
        'Failed to connect to aria2 engine: ${e.message}',
        code: e.type.name,
        details: e,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw Aria2Exception('Unexpected aria2 RPC error: $e');
    }
  }

  /// addUri
  Future<String> addUri(
    List<String> uris, {
    Map<String, dynamic>? options,
    int? position,
  }) async {
    final params = <dynamic>[uris];
    if (options != null) {
      params.add(options);
    }
    if (position != null) {
      if (options == null) params.add({});
      params.add(position);
    }
    final result = await _call('addUri', params);
    return result.toString();
  }

  /// tellStatus
  Future<Aria2Status> tellStatus(String gid, [List<String>? keys]) async {
    final params = <dynamic>[gid];
    if (keys != null && keys.isNotEmpty) {
      params.add(keys);
    }
    final result = await _call('tellStatus', params);
    return Aria2Status.fromMap(result as Map<String, dynamic>);
  }

  /// tellActive
  Future<List<Aria2Status>> tellActive([List<String>? keys]) async {
    final params = <dynamic>[];
    if (keys != null && keys.isNotEmpty) {
      params.add(keys);
    }
    final result = await _call('tellActive', params);
    if (result is List) {
      return result
          .map((item) => Aria2Status.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// tellWaiting
  Future<List<Aria2Status>> tellWaiting(int offset, int num, [List<String>? keys]) async {
    final params = <dynamic>[offset, num];
    if (keys != null && keys.isNotEmpty) {
      params.add(keys);
    }
    final result = await _call('tellWaiting', params);
    if (result is List) {
      return result
          .map((item) => Aria2Status.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// tellStopped
  Future<List<Aria2Status>> tellStopped(int offset, int num, [List<String>? keys]) async {
    final params = <dynamic>[offset, num];
    if (keys != null && keys.isNotEmpty) {
      params.add(keys);
    }
    final result = await _call('tellStopped', params);
    if (result is List) {
      return result
          .map((item) => Aria2Status.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// pause
  Future<String> pause(String gid) async {
    final result = await _call('pause', [gid]);
    return result.toString();
  }

  /// forcePause
  Future<String> forcePause(String gid) async {
    final result = await _call('forcePause', [gid]);
    return result.toString();
  }

  /// unpause
  Future<String> unpause(String gid) async {
    final result = await _call('unpause', [gid]);
    return result.toString();
  }

  /// pauseAll
  Future<String> pauseAll() async {
    final result = await _call('pauseAll');
    return result.toString();
  }

  /// unpauseAll
  Future<String> unpauseAll() async {
    final result = await _call('unpauseAll');
    return result.toString();
  }

  /// remove
  Future<String> remove(String gid) async {
    final result = await _call('remove', [gid]);
    return result.toString();
  }

  /// forceRemove
  Future<String> forceRemove(String gid) async {
    final result = await _call('forceRemove', [gid]);
    return result.toString();
  }

  /// changeOption
  Future<String> changeOption(String gid, Map<String, dynamic> options) async {
    final result = await _call('changeOption', [gid, options]);
    return result.toString();
  }

  /// changeGlobalOption
  Future<String> changeGlobalOption(Map<String, dynamic> options) async {
    final result = await _call('changeGlobalOption', [options]);
    return result.toString();
  }

  /// getGlobalOption
  Future<Map<String, dynamic>> getGlobalOption() async {
    final result = await _call('getGlobalOption');
    return Map<String, dynamic>.from(result as Map);
  }

  /// getGlobalStat
  Future<Aria2GlobalStat> getGlobalStat() async {
    final result = await _call('getGlobalStat');
    return Aria2GlobalStat.fromMap(result as Map<String, dynamic>);
  }

  /// purgeDownloadResult
  Future<String> purgeDownloadResult() async {
    final result = await _call('purgeDownloadResult');
    return result.toString();
  }

  /// getVersion
  Future<Map<String, dynamic>> getVersion() async {
    final result = await _call('getVersion');
    return Map<String, dynamic>.from(result as Map);
  }

  /// shutdown
  Future<String> shutdown() async {
    final result = await _call('shutdown');
    return result.toString();
  }
}
