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
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: 'http://$host:$port/jsonrpc',
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 15),
               sendTimeout: const Duration(seconds: 15),
               headers: {'Content-Type': 'application/json'},
             ),
           );

  String get rpcUrl => 'http://$host:$port/jsonrpc';

  Future<dynamic> _call(
    String method, [
    List<dynamic> params = const [],
    Duration? timeout,
  ]) async {
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

    final requestOptions = timeout != null
        ? Options(sendTimeout: timeout, receiveTimeout: timeout)
        : null;

    try {
      final response = await _dio.post(
        '',
        data: jsonEncode(payload),
        options: requestOptions,
      );

      if (response.statusCode != 200) {
        throw Aria2Exception(
          'Aria2 RPC returned HTTP status ${response.statusCode}',
          code: 'HTTP_${response.statusCode}',
        );
      }

      final data = response.data is String
          ? jsonDecode(response.data)
          : response.data;
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
      final detail = switch (e.type) {
        DioExceptionType.connectionTimeout => 'Connection to aria2 engine timed out ($method)',
        DioExceptionType.sendTimeout => 'Sending data to aria2 engine timed out ($method)',
        DioExceptionType.receiveTimeout => 'Receiving response from aria2 engine timed out ($method). Engine may be busy with large metadata.',
        DioExceptionType.badResponse => 'Aria2 engine rejected request: ${e.response?.statusCode}',
        DioExceptionType.connectionError => 'Cannot connect to aria2 engine on $host:$port. Engine process may have stopped.',
        _ => e.message ?? 'Unknown network error',
      };
      throw RpcConnectionException(
        detail,
        code: e.type.name,
        details: e,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw Aria2Exception('Unexpected aria2 RPC error ($method): $e');
    }
  }

  /// addUri (30s timeout for network/magnet URI parsing)
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
    final result = await _call('addUri', params, const Duration(seconds: 30));
    return result.toString();
  }

  /// addTorrent (60s timeout for base64 serialization and large piece hash arrays)
  Future<String> addTorrent(
    String base64Torrent, {
    List<String> uris = const [],
    Map<String, dynamic>? options,
    int? position,
  }) async {
    final params = <dynamic>[base64Torrent, uris];
    if (options != null) {
      params.add(options);
    }
    if (position != null) {
      if (options == null) params.add({});
      params.add(position);
    }
    final result = await _call('addTorrent', params, const Duration(seconds: 60));
    return result.toString();
  }

  /// tellStatus (8s timeout)
  Future<Aria2Status> tellStatus(String gid, [List<String>? keys]) async {
    final params = <dynamic>[gid];
    if (keys != null && keys.isNotEmpty) {
      params.add(keys);
    }
    final result = await _call('tellStatus', params, const Duration(seconds: 8));
    return Aria2Status.fromMap(result as Map<String, dynamic>);
  }

  /// tellActive (8s timeout)
  Future<List<Aria2Status>> tellActive([List<String>? keys]) async {
    final params = <dynamic>[];
    if (keys != null && keys.isNotEmpty) {
      params.add(keys);
    }
    final result = await _call('tellActive', params, const Duration(seconds: 8));
    if (result is List) {
      return result
          .map((item) => Aria2Status.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// tellWaiting (8s timeout)
  Future<List<Aria2Status>> tellWaiting(
    int offset,
    int num, [
    List<String>? keys,
  ]) async {
    final params = <dynamic>[offset, num];
    if (keys != null && keys.isNotEmpty) {
      params.add(keys);
    }
    final result = await _call('tellWaiting', params, const Duration(seconds: 8));
    if (result is List) {
      return result
          .map((item) => Aria2Status.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// tellStopped (8s timeout)
  Future<List<Aria2Status>> tellStopped(
    int offset,
    int num, [
    List<String>? keys,
  ]) async {
    final params = <dynamic>[offset, num];
    if (keys != null && keys.isNotEmpty) {
      params.add(keys);
    }
    final result = await _call('tellStopped', params, const Duration(seconds: 8));
    if (result is List) {
      return result
          .map((item) => Aria2Status.fromMap(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// pause (8s timeout)
  Future<String> pause(String gid) async {
    final result = await _call('pause', [gid], const Duration(seconds: 8));
    return result.toString();
  }

  /// forcePause (8s timeout)
  Future<String> forcePause(String gid) async {
    final result = await _call('forcePause', [gid], const Duration(seconds: 8));
    return result.toString();
  }

  /// unpause (8s timeout)
  Future<String> unpause(String gid) async {
    final result = await _call('unpause', [gid], const Duration(seconds: 8));
    return result.toString();
  }

  /// pauseAll (10s timeout)
  Future<String> pauseAll() async {
    final result = await _call('pauseAll', const [], const Duration(seconds: 10));
    return result.toString();
  }

  /// unpauseAll (10s timeout)
  Future<String> unpauseAll() async {
    final result = await _call('unpauseAll', const [], const Duration(seconds: 10));
    return result.toString();
  }

  /// remove (8s timeout)
  Future<String> remove(String gid) async {
    final result = await _call('remove', [gid], const Duration(seconds: 8));
    return result.toString();
  }

  /// forceRemove (8s timeout)
  Future<String> forceRemove(String gid) async {
    final result = await _call('forceRemove', [gid], const Duration(seconds: 8));
    return result.toString();
  }

  /// changeOption (8s timeout)
  Future<String> changeOption(String gid, Map<String, dynamic> options) async {
    final result = await _call('changeOption', [gid, options], const Duration(seconds: 8));
    return result.toString();
  }

  /// changeGlobalOption (8s timeout)
  Future<String> changeGlobalOption(Map<String, dynamic> options) async {
    final result = await _call('changeGlobalOption', [options], const Duration(seconds: 8));
    return result.toString();
  }

  /// getGlobalOption (8s timeout)
  Future<Map<String, dynamic>> getGlobalOption() async {
    final result = await _call('getGlobalOption', const [], const Duration(seconds: 8));
    return Map<String, dynamic>.from(result as Map);
  }

  /// getGlobalStat (8s timeout)
  Future<Aria2GlobalStat> getGlobalStat() async {
    final result = await _call('getGlobalStat', const [], const Duration(seconds: 8));
    return Aria2GlobalStat.fromMap(result as Map<String, dynamic>);
  }

  /// purgeDownloadResult (8s timeout)
  Future<String> purgeDownloadResult() async {
    final result = await _call('purgeDownloadResult', const [], const Duration(seconds: 8));
    return result.toString();
  }

  /// getVersion (5s timeout)
  Future<Map<String, dynamic>> getVersion() async {
    final result = await _call('getVersion', const [], const Duration(seconds: 5));
    return Map<String, dynamic>.from(result as Map);
  }

  /// shutdown (5s timeout)
  Future<String> shutdown() async {
    final result = await _call('shutdown', const [], const Duration(seconds: 5));
    return result.toString();
  }
}
