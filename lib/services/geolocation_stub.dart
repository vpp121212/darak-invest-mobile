import 'geolocation_service.dart' show GeoResult;

/// نسخة غير ويب: لا توجد أذونات منصة أصلية — تُرجع فشلاً برسالة توضيحية.
class GeolocationService {
  static bool get isSupported => false;

  static Future<GeoResult> locate() async => const GeoResult(
        message: 'الموقع المباشر متاح في المتصفح فقط',
      );
}
