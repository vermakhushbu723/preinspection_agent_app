import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../config/api_config.dart';

/// Error from the backend (or the network). [message] is safe to show the user.
class ApiException implements Exception {
  const ApiException(this.message, {this.status = 0});

  final String message;

  /// HTTP status; 0 = no response (offline, timeout).
  final int status;

  bool get isUnauthorized => status == 401;

  @override
  String toString() => message;
}

/// Minimal JSON + file-upload client on `dart:io` (no extra package).
/// Sends the signed-in token as `Authorization: Bearer ...`.
class ApiClient {
  ApiClient({String? baseUrl, HttpClient? httpClient})
    : _base = (baseUrl ?? ApiConfig.baseUrl).replaceAll(RegExp(r'/$'), ''),
      _http = httpClient ?? HttpClient();

  final String _base;
  final HttpClient _http;

  /// Set after login, cleared on logout.
  String? token;

  /// Called when the server says the session is gone (401) -- the app signs out.
  void Function()? onUnauthorized;

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_base$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  Future<dynamic> get(String path) => _json('GET', path);
  Future<dynamic> post(String path, [Object? body]) =>
      _json('POST', path, body ?? const {});
  Future<dynamic> patch(String path, Object body) => _json('PATCH', path, body);
  Future<dynamic> delete(String path) => _json('DELETE', path);

  Future<dynamic> _json(String method, String path, [Object? body]) async {
    return _send(method, _uri(path), ApiConfig.timeout, (req) async {
      if (body != null) {
        final bytes = utf8.encode(jsonEncode(body));
        req.headers.contentType = ContentType.json;
        req.contentLength = bytes.length;
        req.add(bytes);
      }
    });
  }

  /// PUT a file from disk as the raw request body.
  Future<dynamic> putFile(
    String path,
    File file,
    String contentType, {
    Map<String, String>? query,
  }) async {
    final length = await file.length();
    return _send('PUT', _uri(path, query), ApiConfig.uploadTimeout, (
      req,
    ) async {
      req.headers.contentType = ContentType.parse(contentType);
      req.contentLength = length;
      await req.addStream(file.openRead());
    });
  }

  /// PUT in-memory bytes (e.g. a signature PNG).
  Future<dynamic> putBytes(
    String path,
    Uint8List bytes,
    String contentType,
  ) async {
    return _send('PUT', _uri(path), ApiConfig.uploadTimeout, (req) async {
      req.headers.contentType = ContentType.parse(contentType);
      req.contentLength = bytes.length;
      req.add(bytes);
    });
  }

  Future<dynamic> _send(
    String method,
    Uri uri,
    Duration timeout,
    Future<void> Function(HttpClientRequest req) writeBody,
  ) async {
    try {
      final req = await _http.openUrl(method, uri).timeout(timeout);
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final t = token;
      if (t != null) {
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $t');
      }
      await writeBody(req);
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join().timeout(timeout);
      dynamic data;
      if (text.isNotEmpty) {
        try {
          data = jsonDecode(text);
        } catch (_) {
          data = null;
        }
      }
      if (res.statusCode >= 200 && res.statusCode < 300) return data;
      if (res.statusCode == 401 && t != null) onUnauthorized?.call();
      final detail = data is Map && data['detail'] is String
          ? data['detail'] as String
          : null;
      throw ApiException(
        detail ??
            (res.statusCode >= 500
                ? 'Server error, please try again.'
                : 'Request failed (${res.statusCode}).'),
        status: res.statusCode,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The server is taking too long. Check your internet connection and try again.',
      );
    } on SocketException {
      throw const ApiException(
        'No internet connection. Check your network and try again.',
      );
    } on HttpException {
      throw const ApiException(
        'Connection to the server failed. Please try again.',
      );
    } on HandshakeException {
      throw const ApiException('Secure connection to the server failed.');
    }
  }
}
