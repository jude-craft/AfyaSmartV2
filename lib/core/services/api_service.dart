import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  ApiService._();

  // ── Base URLs — update when forwarding port ───────────
  // Android emulator  → http://10.0.2.2:8000
  // Physical device   → http://YOUR_LOCAL_IP:8000
  // ngrok             → https://xxxx.ngrok.io
  static const String _baseUrl  = 'http://10.0.2.2:8000';
  static const Duration _timeout = Duration(seconds: 30);

  // ─────────────────────────────────────────────────────
  //  Headers
  // ─────────────────────────────────────────────────────
  static Future<Map<String, String>> _headers() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─────────────────────────────────────────────────────
  //  POST /chat — free chat
  // ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendChat({
    required String message,
    required String firebaseUid,
    required String email,
    required String displayName,
    String? sessionId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/chat'),
          headers: await _headers(),
          body: jsonEncode({
            'message':      message,
            'firebase_uid': firebaseUid,
            'email':        email,
            'display_name': displayName,
            'session_id':   sessionId,
          }),
        )
        .timeout(_timeout);

    _assertOk(response, 'Chat request failed');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────
  //  POST /symptoms — symptom checker
  // ─────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendSymptoms({
    required String message,
    required String firebaseUid,
    required String email,
    required String displayName,
    String? sessionId,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/symptoms'),
          headers: await _headers(),
          body: jsonEncode({
            'message':      message,
            'firebase_uid': firebaseUid,
            'email':        email,
            'display_name': displayName,
            'session_id':   sessionId,
          }),
        )
        .timeout(_timeout);

    _assertOk(response, 'Symptoms request failed');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─────────────────────────────────────────────────────
  //  GET /sessions/{firebase_uid} — fetch session list
  // ─────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchSessions(
    String firebaseUid,
  ) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/sessions/$firebaseUid'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    _assertOk(response, 'Failed to fetch sessions');

    final body = jsonDecode(response.body);

    // Backend returns {"sessions": [...]}
    if (body is Map && body['sessions'] != null) {
      return (body['sessions'] as List).cast<Map<String, dynamic>>();
    }
    if (body is List) {
      return body.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ─────────────────────────────────────────────────────
  //  GET /history/{session_id}/messages — fetch messages
  // ─────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> fetchMessages(
    String sessionId,
  ) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/history/$sessionId/messages'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    _assertOk(response, 'Failed to fetch messages');

    final body = jsonDecode(response.body);

    // Backend returns {"messages": [...]}
    if (body is Map && body['messages'] != null) {
      return (body['messages'] as List).cast<Map<String, dynamic>>();
    }
    if (body is List) {
      return body.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ─────────────────────────────────────────────────────
  //  DELETE /chat/{session_id} — delete a session
  // ─────────────────────────────────────────────────────
  static Future<bool> deleteSession(String sessionId) async {
    final response = await http
        .delete(
          Uri.parse('$_baseUrl/chat/$sessionId'),
          headers: await _headers(),
        )
        .timeout(_timeout);

    // Accept both 200 and 204 as success
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // ─────────────────────────────────────────────────────
  //  Assert helper
  // ─────────────────────────────────────────────────────
  static void _assertOk(http.Response response, String context) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message:    '$context: ${response.body}',
      );
    }
  }
}

// ── Custom exception ──────────────────────────────────────
class ApiException implements Exception {
  final int    statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';
}