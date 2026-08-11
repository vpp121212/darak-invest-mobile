import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate' show Isolate;

import 'package:http/http.dart' as http;

import 'app_exception.dart';
import '../config/env_config.dart';

/// Central HTTP client for the Darak backend.
///
/// Owns the base URL, request timeout, auth header, JSON decoding and
/// unified error mapping so callers only deal with [AppException].
class ApiClient {
  static String get baseUrl => EnvConfig.apiBaseUrl;
  static Duration get timeout => EnvConfig.apiTimeout;

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
  ///
  /// `data:` URIs (base64 images uploaded from the device) pass through
  /// untouched so they can render offline from the local store.
  String resolve(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return pathOrUrl;
    }
    if (pathOrUrl.startsWith('data:')) return pathOrUrl;
    if (pathOrUrl.startsWith('assets/')) return pathOrUrl;
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

  Future<dynamic> patch(String path, {Map<String, dynamic>? body, bool auth = true}) {
    return _send(() => http.patch(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? const {}),
        ));
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body, bool auth = true}) {
    return _send(() => http.put(
          _uri(path),
          headers: _headers(auth: auth),
          body: jsonEncode(body ?? const {}),
        ));
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(timeout);
      return await _decode(response);
    } on TimeoutException {
      throw const AppTimeoutException();
    } on SocketException {
      throw const NetworkException('لا يوجد اتصال بالإنترنت');
    } on http.ClientException {
      throw const NetworkException('تعذّر الاتصال بالخادم');
    }
  }

  Future<dynamic> _decode(http.Response response) async {
    final status = response.statusCode;
    final body = response.body.isEmpty ? '{}' : response.body;

    // فك ترميز JSON في Isolate منفصل حتى لا يحجب واجهة المستخدم مع الحمولات
    // الكبيرة (قائمة العقارات، تقارير السوق، النبض). يعمل بأمان على الويب.
    if (status >= 200 && status < 300) {
      try {
        return await Isolate.run(() => jsonDecode(body));
      } catch (_) {
        throw const ParseException();
      }
    }

    var message = 'حدث خطأ ($status)';
    try {
      // رسائل الخطأ صغيرة — فك الترميز المباشر لا يحجب الواجهة ويظل متوافقاً
      // مع بيئة الاختبارات.
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final serverMsg = decoded['message'] ?? decoded['error'];
        if (serverMsg != null) message = serverMsg.toString();
        final details = decoded['details'];
        if (details is List && details.isNotEmpty) {
          final detailMsgs = details
              .map((d) => (d is Map ? d['message'] : null)?.toString())
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .toList();
          if (detailMsgs.isNotEmpty) message = detailMsgs.join('، ');
        }
      }
    } catch (_) {
      // keep default message when body is not JSON
    }
    throw ApiException(message, status);
  }
}
