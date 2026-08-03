import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/property.dart';

/// تخزين محلي للعقارات المُضافة من داخل التطبيق عندما لا يكون الخادم متاحاً.
///
/// يكمل دورة البيانات «إدخال المالك ← عرض المستخدم» دون اتصال، عبر
/// [shared_preferences]، ويُدمج مع قائمة الواجهة في [PropertiesNotifier].
class LocalPropertiesStore {
  static const String _key = 'darak_local_properties';

  static Future<List<Property>> loadLocalProperties() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Property.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> saveLocalProperty(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    var list = <dynamic>[];
    if (raw != null && raw.isNotEmpty) {
      try {
        list = jsonDecode(raw) as List;
      } catch (_) {
        list = <dynamic>[];
      }
    }
    list.add(json);
    await prefs.setString(_key, jsonEncode(list));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
