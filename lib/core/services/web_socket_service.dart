import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

enum WsConnectionState { disconnected, connecting, connected, error }

class WebSocketService {
  // ── Change to wss:// for production ──────────────────
  // Android emulator  → ws://10.0.2.2:8000
  // Physical device   → ws://YOUR_LOCAL_IP:8000
  // ngrok             → wss://xxxx.ngrok.io
  static const String _wsBaseUrl = 'ws://10.0.2.2:8000';

  WebSocketChannel?   _channel;
  StreamSubscription? _subscription;
  WsConnectionState   _state            = WsConnectionState.disconnected;
  String?             _currentSessionId;

  // ── Callbacks wired by ChatProvider ──────────────────
  void Function(String chunk)? onChunk;
  void Function()?             onDone;
  void Function(String error)? onError;
  void Function()?             onConnected;

  // ── Getters ───────────────────────────────────────────
  WsConnectionState get state          => _state;
  String?           get currentSession => _currentSessionId;
  bool get isConnected => _state == WsConnectionState.connected;

  // ─────────────────────────────────────────────────────
  //  Connect
  // ─────────────────────────────────────────────────────
  Future<void> connect({
    required String sessionId,
    required String firebaseUid,
  }) async {
    // Already connected to the same session — reuse
    if (_state == WsConnectionState.connected &&
        _currentSessionId == sessionId) {
      return;
    }

    // Clean up any previous connection first
    await disconnect();

    _state            = WsConnectionState.connecting;
    _currentSessionId = sessionId;

    try {
      final uri = Uri.parse(
        '$_wsBaseUrl/ws/chat/$sessionId/$firebaseUid',
      );

      _channel = WebSocketChannel.connect(uri);

      // Wait until the handshake completes
      await _channel!.ready;

      _state = WsConnectionState.connected;
      onConnected?.call();

      // Start listening to the incoming stream
      _subscription = _channel!.stream.listen(
        _onMessage,
        onError:       _onStreamError,
        onDone:        _onStreamDone,
        cancelOnError: false,
      );
    } catch (e) {
      _state = WsConnectionState.error;
      onError?.call('WebSocket connection failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────
  //  Send a message to the backend
  // ─────────────────────────────────────────────────────
  void sendMessage(String message) {
    if (!isConnected || _channel == null) {
      onError?.call('Not connected to server.');
      return;
    }
    try {
      _channel!.sink.add(
        jsonEncode({'message': message}),
      );
    } catch (e) {
      onError?.call('Failed to send message: $e');
    }
  }

  // ─────────────────────────────────────────────────────
  //  Handle incoming message chunks
  // ─────────────────────────────────────────────────────
  void _onMessage(dynamic raw) {
    try {
      final data  = jsonDecode(raw as String) as Map<String, dynamic>;
      final chunk = data['chunk'] as String?;

      if (chunk == null) return;

      if (chunk == '[DONE]') {
        onDone?.call();
      } else {
        onChunk?.call(chunk);
      }
    } catch (e) {
      onError?.call('Failed to parse server message: $e');
    }
  }

  void _onStreamError(dynamic error) {
    _state = WsConnectionState.error;
    onError?.call('WebSocket stream error: $error');
  }

  void _onStreamDone() {
    // Server closed the connection
    _state = WsConnectionState.disconnected;
  }

  // ─────────────────────────────────────────────────────
  //  Disconnect cleanly
  // ─────────────────────────────────────────────────────
  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close(ws_status.normalClosure);
    _subscription     = null;
    _channel          = null;
    _currentSessionId = null;
    _state            = WsConnectionState.disconnected;
  }

  // ─────────────────────────────────────────────────────
  //  Dispose (called when ChatProvider is disposed)
  // ─────────────────────────────────────────────────────
  void dispose() {
    disconnect();
  }
}