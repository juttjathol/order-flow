import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import 'local_web_ui.dart';

final _log = Logger();
const _uuid = Uuid();

typedef StateProvider = Future<Map<String, dynamic>> Function();
typedef EventHandler = Future<void> Function(
    String type, Map<String, dynamic> payload, String deviceId);

/// Local HTTP + WebSocket server that runs only on the Main device.
class LocalServer {
  HttpServer? _server;
  final int port;
  final StateProvider getFullState;
  final EventHandler onClientEvent;
  final Map<String, WebSocketChannel> _clients = {};
  final Map<String, Map<String, dynamic>> _connectedDevices = {};

  LocalServer({
    this.port = 8787,
    required this.getFullState,
    required this.onClientEvent,
  });

  bool get isRunning => _server != null;
  Map<String, Map<String, dynamic>> get connectedDevices =>
      Map.unmodifiable(_connectedDevices);

  Future<void> start({String? bindAddress}) async {
    if (_server != null) return;
    final router = Router();

    router.get('/', (Request req) {
      return Response.ok(
        kLocalDashboardHtml,
        headers: {'Content-Type': 'text/html; charset=utf-8'},
      );
    });
    router.get('/dashboard', (Request req) {
      return Response.ok(
        kLocalDashboardHtml,
        headers: {'Content-Type': 'text/html; charset=utf-8'},
      );
    });
    router.get('/health', (Request req) {
      return Response.ok(jsonEncode({'status': 'ok', 'role': 'main'}));
    });
    router.post('/api/event', (Request req) async {
      try {
        final body =
            jsonDecode(await req.readAsString()) as Map<String, dynamic>;
        final type = body['type'] as String? ?? '';
        final payload =
            Map<String, dynamic>.from(body['payload'] as Map? ?? {});
        final deviceId = body['deviceId'] as String? ?? 'unknown';
        await onClientEvent(type, payload, deviceId);
        return Response.ok(
          jsonEncode({'ok': true}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}));
      }
    });
    router.get('/state', (Request req) async {
      final state = await getFullState();
      return Response.ok(
        jsonEncode(state),
        headers: {'Content-Type': 'application/json'},
      );
    });

    final wsHandler =
        webSocketHandler((WebSocketChannel webSocket, String? protocol) {
      var tempId = _uuid.v4();
      _clients[tempId] = webSocket;
      _log.i('WebSocket client connected: $tempId');
      webSocket.stream.listen(
        (message) async {
          try {
            final data = jsonDecode(message as String) as Map<String, dynamic>;
            final type = data['type'] as String? ?? '';
            final payload =
                Map<String, dynamic>.from(data['payload'] as Map? ?? {});
            final clientDeviceId = data['deviceId'] as String? ?? tempId;
            if (type == 'identify') {
              final id = payload['id'] as String? ?? clientDeviceId;
              _connectedDevices[id] = {
                ...payload,
                'isOnline': true,
                'lastSeen': DateTime.now().toUtc().toIso8601String(),
              };
              _clients.remove(tempId);
              _clients[id] = webSocket;
              tempId = id;
              _broadcast('device.joined', _connectedDevices[id]!);
              return;
            }
            await onClientEvent(type, payload, clientDeviceId);
          } catch (e, st) {
            _log.e('WS message error', error: e, stackTrace: st);
          }
        },
        onDone: () {
          _clients.remove(tempId);
          _connectedDevices.remove(tempId);
        },
        onError: (_) {
          _clients.remove(tempId);
          _connectedDevices.remove(tempId);
        },
      );
    });

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addHandler(Cascade().add(router.call).add(wsHandler).handler);

    final address = bindAddress != null
        ? InternetAddress(bindAddress)
        : InternetAddress.anyIPv4;
    _server = await shelf_io.serve(handler, address, port);
    _log.i('LocalServer listening on ${_server!.address.address}:$port');
  }

  Future<void> stop() async {
    for (final c in _clients.values) {
      try {
        await c.sink.close();
      } catch (_) {}
    }
    _clients.clear();
    _connectedDevices.clear();
    await _server?.close(force: true);
    _server = null;
  }

  void broadcast(String type, Map<String, dynamic> payload) =>
      _broadcast(type, payload);

  void _broadcast(String type, Map<String, dynamic> payload) {
    final msg = jsonEncode({
      'type': type,
      'payload': payload,
      'ts': DateTime.now().toUtc().toIso8601String(),
    });
    for (final channel in _clients.values) {
      try {
        channel.sink.add(msg);
      } catch (_) {}
    }
  }

  Middleware _corsMiddleware() {
    return (Handler inner) {
      return (Request req) async {
        if (req.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        final resp = await inner(req);
        return resp.change(headers: _corsHeaders);
      };
    };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
  };
}
