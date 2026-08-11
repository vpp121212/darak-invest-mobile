import 'geolocation_service.dart' show GeoPoint;

/// نسخة المنصات غير الويب: الموقع المباشر غير مدعوم.
class GeolocationService {
  static bool get isSupported => false;

  static Future<GeoPoint?> getCurrentPosition() async => null;
}
