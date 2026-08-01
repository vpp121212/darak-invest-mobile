import '../core/network/api_client.dart';
import '../models/property.dart';

/// Data access layer for the Darak backend.
///
/// Thin, stateless wrappers over [ApiClient]. All network errors are surfaced
/// as [AppException] so UI code can render the message directly.
class ApiService {
  static final ApiClient _client = ApiClient.instance;

  static String get baseUrl => ApiClient.baseUrl;

  static String resolveImage(String pathOrUrl) => _client.resolve(pathOrUrl);

  static void setToken(String? token) => _client.token = token;

  static List<Property> _parseProperties(dynamic data) {
    final list = data is List ? data : (data['properties'] ?? data['data'] ?? []);
    return (list as List).map((e) {
      final property = Property.fromJson(e as Map<String, dynamic>);
      return property.copyWith(
        images: property.images.map(resolveImage).toList(),
      );
    }).toList();
  }

  static Future<List<Property>> getProperties({int limit = 50}) async {
    final data = await _client.get('/api/properties/all', query: {'limit': limit});
    return _parseProperties(data);
  }

  static Future<Property> getProperty(String id) async {
    final data = await _client.get('/api/properties/$id');
    final map = data is Map<String, dynamic> ? data : data['property'];
    final property = Property.fromJson(map);
    return property.copyWith(images: property.images.map(resolveImage).toList());
  }

  static Future<Map<String, dynamic>> search(Map<String, dynamic> params) async {
    final query = Map<String, dynamic>.from(params)
      ..removeWhere((_, v) => v == null || v == '');
    final data = await _client.get('/api/search', query: query);
    return data is Map<String, dynamic> ? data : {'properties': data};
  }

  static Future<Map<String, dynamic>> estimate(Map<String, dynamic> data) async {
    return _client.post('/api/ai/estimate', body: data) as Future<Map<String, dynamic>>;
  }

  static Future<Map<String, dynamic>> match(Map<String, dynamic> data) async {
    return _client.post('/api/ai/match', body: data) as Future<Map<String, dynamic>>;
  }

  static Future<Map<String, dynamic>> getNeighborhoodPulse(String district) async {
    return _client.get('/api/pulse/neighborhood/${Uri.encodeComponent(district)}')
        as Future<Map<String, dynamic>>;
  }

  static Future<List<String>> getCities() async {
    final data = await _client.get('/api/search/cities');
    final list = data is Map ? (data['cities'] ?? []) : data;
    return (list as List).map((e) => e.toString()).toList();
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await _client.post('/api/auth/login', body: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    final token = res['token'] ?? res['accessToken'];
    if (token != null) _client.token = token;
    return res;
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await _client.post('/api/auth/register', body: data)
        as Map<String, dynamic>;
    final token = res['token'] ?? res['accessToken'];
    if (token != null) _client.token = token;
    return res;
  }

  static Future<Map<String, dynamic>> getMe() async {
    return _client.get('/api/auth/me') as Future<Map<String, dynamic>>;
  }
}
