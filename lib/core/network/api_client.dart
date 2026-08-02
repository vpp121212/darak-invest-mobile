import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'app_exception.dart';

/// Central HTTP client for the Darak backend.
///
/// Owns the base URL, request timeout, auth header, JSON decoding and
/// unified error mapping so callers only deal with [AppException].
class ApiClient {
  static const String baseUrl = 'https://darak-invest-backend-j6hy.onrender.com';
  static const Duration timeout = Duration(seconds: 45);

  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Set after login; injected into every request's Authorization header.
  String? token;

  Map<String, String> _headers({bool auth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final t = token;
    if (auth && t != null && t.isNotEmpty) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  /// Resolves backend-relative paths (e.g. `/uploads/...`) to absolute URLs.
  String resolve(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (pathOrUrl.isEmpty) return '';
    return pathOrUrl.startsWith('/')
        ? '$baseUrl$pathOrUrl'
        : '$baseUrl/$pathOrUrl';
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse(path.startsWith('http') ? path : '$baseUrl$path');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(
      queryParameters: query.map(
        (k, v) => MapEntry(k, v.toString()),
      ),
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _send(() => http.get(_uri(path, query), headers: _headers(auth: auth)));
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) {
    return _send(() => http.post(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? const {}),
        ));
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(timeout);
      return _decode(response);
    } on TimeoutException {
      throw const AppTimeoutException();
    } on SocketException {
      throw const NetworkException('لا يوجد اتصال بالإنترنت');
    } on http.ClientException {
      throw const NetworkException('تعذّر الاتصال بالخادم');
    }
  }

  dynamic _decode(http.Response response) {
    final status = response.statusCode;
    final body = response.body.isEmpty ? '{}' : response.body;

    if (status >= 200 && status < 300) {
      try {
        return jsonDecode(body);
      } catch (_) {
        throw const ParseException();
      }
    }

    var message = 'حدث خطأ ($status)';
    try {
      final decoded = jsonDecode(body);
      message = (decoded is Map && decoded['message'] != null)
          ? decoded['message'].toString()
          : (decoded is Map && decoded['error'] != null
              ? decoded['error'].toString()
              : message);
    } catch (_) {
      // keep default message when body is not JSON
    }
    throw ApiException(message, status);
  }
}
