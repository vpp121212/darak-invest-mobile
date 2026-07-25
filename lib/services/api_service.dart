import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property.dart';
import '../models/auction.dart';

class ApiService {
  static const String baseUrl = 'https://darak-invest-backend.vercel.app';

  static Map<String, String> _headers({String? token}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    final error = jsonDecode(response.body);
    throw Exception(error['message'] ?? 'حدث خطأ (${response.statusCode})');
  }

  static Future<List<Property>> getProperties() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/properties'),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      final list = data is List ? data : (data['properties'] ?? data['data'] ?? []) as List;
      return list.map((e) => Property.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل تحميل العقارات: $e');
    }
  }

  static Future<Property> getProperty(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/properties/$id'),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      final map = data is Map<String, dynamic> ? data : data['property'];
      return Property.fromJson(map);
    } catch (e) {
      throw Exception('فشل تحميل العقار: $e');
    }
  }

  static Future<List<Property>> searchProperties(Map<String, dynamic> params) async {
    try {
      final uri = Uri.parse('$baseUrl/api/properties/search').replace(
        queryParameters: params.map((k, v) => MapEntry(k, v.toString())),
      );
      final response = await http.get(uri, headers: _headers());
      final data = _handleResponse(response);
      final list = data is List ? data : (data['properties'] ?? data['data'] ?? []) as List;
      return list.map((e) => Property.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل البحث: $e');
    }
  }

  static Future<List<Auction>> getAuctions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auctions'),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      final list = data is List ? data : (data['auctions'] ?? data['data'] ?? []) as List;
      return list.map((e) => Auction.fromJson(e)).toList();
    } catch (e) {
      throw Exception('فشل تحميل المزادات: $e');
    }
  }

  static Future<List<Map>> getOffices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/offices'),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      final list = data is List ? data : (data['offices'] ?? data['data'] ?? []) as List;
      return list.cast<Map>().toList();
    } catch (e) {
      throw Exception('فشل تحميل المكاتب: $e');
    }
  }

  static Future<List<Map>> getTopAgents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/agents/top'),
        headers: _headers(),
      );
      final data = _handleResponse(response);
      final list = data is List ? data : (data['agents'] ?? data['data'] ?? []) as List;
      return list.cast<Map>().toList();
    } catch (e) {
      throw Exception('فشل تحميل الوكلاء: $e');
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('فشل تسجيل الدخول: $e');
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('فشل التسجيل: $e');
    }
  }

  static Future<Map<String, dynamic>> getMe(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/auth/me'),
        headers: _headers(token: token),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('فشل تحميل بيانات المستخدم: $e');
    }
  }

  static Future<Map<String, dynamic>> estimate(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/estimate'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('فشل التقييم: $e');
    }
  }

  static Future<Map<String, dynamic>> match(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/match'),
        headers: _headers(),
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      throw Exception('فشل المطابقة: $e');
    }
  }
}
